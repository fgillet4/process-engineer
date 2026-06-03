-- =============================================================================
-- Process Engineer — runtime control script
-- Runs during gameplay (not during data loading)
--
-- Responsibilities:
--   1. VLE-based flash separator: compute vapour/liquid split each cycle
--   2. Temperature-dependent WGS conversion display (informational GUI)
--   3. Reactor status: detect if correct temperature fluid is supplied
--   4. On-demand thermodynamic calculations triggered by circuit signals
-- =============================================================================

local thermo = require("lib/thermodynamics")
local vle    = require("lib/vle")

-- Ticks between VLE recalculations (every 2 seconds at 60 UPS)
local VLE_INTERVAL = 120

-- =============================================================================
-- Utility: get a named signal value from a combinator-connected entity
-- =============================================================================
local function get_signal(entity, signal_name)
  local red  = entity.get_merged_signal({ type="virtual", name=signal_name }, defines.wire_connector_id.circuit_red)
  local grn  = entity.get_merged_signal({ type="virtual", name=signal_name }, defines.wire_connector_id.circuit_green)
  return (red or 0) + (grn or 0)
end

-- =============================================================================
-- VLE flash calculation for pe-flash-separator entities
-- Reads inlet fluid composition from the entity's fluid box,
-- runs Rachford-Rice flash, and adjusts recipe output ratios via script.
--
-- In Factorio the recipe controls flow rates; we can't directly set fluid
-- amounts mid-recipe. Instead we use scripted interaction:
--   • Store computed V (vapour fraction) in global storage
--   • Provide a read-out via on_gui_opened for the player
--   • Future: drive a circuit signal output with V value
-- =============================================================================

local function update_flash_separators()
  if not storage.flash_units then return end
  for unit_number, data_entry in pairs(storage.flash_units) do
    local entity = data_entry.entity
    if not (entity and entity.valid) then
      storage.flash_units[unit_number] = nil
    else
      -- Read temperature from the hot-side input fluid box (box index 1)
      local fb = entity.fluidbox
      local fluid_in = fb[1]
      if fluid_in and fluid_in.amount > 0 then
        local T = fluid_in.temperature or 25
        -- Default flash: treat as mixed light hydrocarbon + water stream
        -- Composition inferred from recipe being run (simplified: use fixed z)
        -- TODO: read actual feed composition from upstream tank signals
        local z = data_entry.feed_composition or {
          water   = 0.3,
          methane = 0.5,
          co2     = 0.2,
        }
        local P = data_entry.pressure_bar or 5.0  -- read from circuit signal in future

        local result, K = vle.flash(z, T, P)

        -- Store result for GUI display
        storage.flash_units[unit_number].last_result = {
          V = result.V,
          T = T,
          P = P,
          x = result.x,
          y = result.y,
          tick = game.tick,
        }
      end
    end
  end
end

-- =============================================================================
-- Equilibrium conversion display helper
-- Called when player opens a WGS reactor — shows live K_eq and conversion
-- =============================================================================

local function build_wgs_info_gui(player, entity)
  local fb = entity.fluidbox
  local steam_box = fb[2]
  local T = (steam_box and steam_box.temperature) or 350  -- default HT-WGS temp

  local K    = thermo.keq.wgs(T)
  local conv = thermo.wgs_conversion(T)
  local dH   = thermo.delta_h_rxn(
    { {"co2",1}, {"hydrogen",1} },
    { {"co",1},  {"steam",1}    }
  )

  local frame = player.gui.screen["pe-wgs-info"]
  if frame then frame.destroy() end

  frame = player.gui.screen.add{
    type    = "frame",
    name    = "pe-wgs-info",
    caption = "WGS Reactor — Thermodynamic Status",
    direction = "vertical",
  }
  frame.auto_center = true

  local content = frame.add{ type="table", column_count=2 }
  local function row(label, value)
    content.add{ type="label", caption="[color=gray]"..label.."[/color]" }
    content.add{ type="label", caption=value }
  end

  row("Fluid temperature:",      string.format("%.0f °C", T))
  row("K_eq (CO + H₂O ⇌ CO₂ + H₂):", string.format("%.3f", K))
  row("Equilibrium conversion:", string.format("%.1f%%", conv * 100))
  row("ΔH°rxn (298 K):",         string.format("%.1f kJ/mol", dH))
  row("Regime:",                 T > 300 and "High-Temp (Fe/Cr catalyst)" or "Low-Temp (Cu/Zn catalyst)")

  if K < 2 then
    frame.add{ type="label", caption="[color=orange]⚠ Low conversion — consider lower temperature or excess steam[/color]" }
  end

  frame.add{ type="button", name="pe-close-wgs-info", caption="Close" }
end

-- =============================================================================
-- SMR live status: show ΔH and extent of reaction
-- =============================================================================

local function build_smr_info_gui(player, entity)
  local fb    = entity.fluidbox
  local T_out = 850  -- nominal outlet temp
  local steam = fb[2]
  if steam and steam.temperature then T_out = math.min(steam.temperature * 0.95, 900) end

  local extent = thermo.smr_extent(T_out, 25)
  local dH_smr = thermo.delta_h_rxn(
    { {"co",1}, {"hydrogen",3} },
    { {"methane",1}, {"steam",1} }
  )

  local frame = player.gui.screen["pe-smr-info"]
  if frame then frame.destroy() end
  frame = player.gui.screen.add{
    type = "frame", name = "pe-smr-info",
    caption = "Steam Methane Reformer — Status",
    direction = "vertical",
  }
  frame.auto_center = true

  local content = frame.add{ type="table", column_count=2 }
  local function row(l,v)
    content.add{ type="label", caption="[color=gray]"..l.."[/color]" }
    content.add{ type="label", caption=v }
  end

  row("Outlet temperature:", string.format("%.0f °C", T_out))
  row("ΔH°rxn (SMR, 298 K):", string.format("%.1f kJ/mol (endothermic)", dH_smr))
  row("Equilibrium extent:", string.format("%.1f%%", extent * 100))
  row("Optimal range:", "800–900 °C (thermodynamic + kinetic balance)")
  row("Catalyst:", "Ni/Al₂O₃  — deactivates with coke and sulfur")

  if T_out < 700 then
    frame.add{ type="label", caption="[color=red]✗ Temperature too low — minimal syngas production[/color]" }
  elseif T_out > 950 then
    frame.add{ type="label", caption="[color=red]⚠ Temperature too high — catalyst sintering risk[/color]" }
  else
    frame.add{ type="label", caption="[color=green]✓ Operating in optimal temperature window[/color]" }
  end

  frame.add{ type="button", name="pe-close-smr-info", caption="Close" }
end

-- =============================================================================
-- Haber-Bosch status GUI
-- =============================================================================

local function build_hb_info_gui(player, entity)
  local T_op = 450  -- nominal operating temp (°C)
  local P_op = 200  -- bar

  local K    = thermo.keq.haber_bosch(T_op)
  local dH   = thermo.delta_h_rxn(
    { {"ammonia",2} },
    { {"nitrogen",1}, {"hydrogen",3} }
  )
  -- NH3 mole fraction at equilibrium (simplified, ideal):
  -- K = y_NH3² / (y_N2 · y_H2³ · P²)   at P in bar, stoich feed
  -- For stoich feed y_N2=0.25, y_H2=0.75 and variable y_NH3 at conversion x:
  -- Approximate equilibrium NH3 mol%:
  local K_eff = K * P_op^2
  local y_nh3_approx = math.sqrt(K_eff / (1 + K_eff)) * 100  -- rough mol%
  y_nh3_approx = math.min(y_nh3_approx, 25)  -- cap at physical limit

  local frame = player.gui.screen["pe-hb-info"]
  if frame then frame.destroy() end
  frame = player.gui.screen.add{
    type = "frame", name = "pe-hb-info",
    caption = "Haber-Bosch Reactor — Status",
    direction = "vertical",
  }
  frame.auto_center = true

  local content = frame.add{ type="table", column_count=2 }
  local function row(l,v)
    content.add{ type="label", caption="[color=gray]"..l.."[/color]" }
    content.add{ type="label", caption=v }
  end

  row("Operating temperature:", string.format("%.0f °C (nominal)", T_op))
  row("Operating pressure:",    string.format("%.0f bar (modelled)", P_op))
  row("K_eq (N₂ + 3H₂ ⇌ 2NH₃):", string.format("%.3e bar⁻²", K))
  row("Est. eq. NH₃ mol%:",     string.format("~%.1f%%", y_nh3_approx))
  row("ΔH°rxn (298 K):",        string.format("%.1f kJ/mol (exothermic)", dH))
  row("Catalyst:",              "Promoted Fe (K₂O + Al₂O₃ promoters)")
  row("Real plant conversion:", "~15–20% per pass, ~97% with recycle")

  frame.add{ type="label", caption="[color=cyan]ℹ Le Chatelier: lower T → higher K, but slower kinetics → 400–500°C optimum[/color]" }
  frame.add{ type="button", name="pe-close-hb-info", caption="Close" }
end

-- =============================================================================
-- Event handlers
-- =============================================================================

script.on_event(defines.events.on_built_entity, function(event)
  local entity = event.entity
  if not entity.valid then return end

  if entity.name == "pe-flash-separator" then
    storage.flash_units = storage.flash_units or {}
    storage.flash_units[entity.unit_number] = {
      entity = entity,
      feed_composition = nil,  -- will be set by circuit signal or defaults
      pressure_bar = 5.0,
      last_result = nil,
    }
  end
end)

script.on_event(defines.events.on_entity_destroyed, function(event)
  if storage.flash_units and event.unit_number then
    storage.flash_units[event.unit_number] = nil
  end
end)

script.on_event(defines.events.on_tick, function(event)
  if event.tick % VLE_INTERVAL == 0 then
    update_flash_separators()
  end
end)

script.on_event(defines.events.on_gui_opened, function(event)
  if event.entity and event.entity.valid then
    local name   = event.entity.name
    local player = game.players[event.player_index]
    if name == "pe-wgs" then
      build_wgs_info_gui(player, event.entity)
    elseif name == "pe-smr" then
      build_smr_info_gui(player, event.entity)
    elseif name == "pe-haber-bosch" then
      build_hb_info_gui(player, event.entity)
    end
  end
end)

script.on_event(defines.events.on_gui_click, function(event)
  local name = event.element.name
  if name == "pe-close-wgs-info" or name == "pe-close-smr-info" or name == "pe-close-hb-info" then
    event.element.parent.destroy()
  end
end)

-- Initialise storage on new game / migration
script.on_init(function()
  storage.flash_units = {}
end)

script.on_load(function()
  -- storage is already populated from save; nothing to rebuild
end)
