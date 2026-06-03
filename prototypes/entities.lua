-- =============================================================================
-- Unit operation machine definitions
-- Graphics are assigned in data-updates.lua from base assembling machines
-- All machines use electric energy; heat-intensive operations have high wattage
-- Pipe connection positions match entity collision_box edges
-- =============================================================================

-- Helper: build a fluidbox definition
local function fluidbox(prod_type, x, y, dir, volume)
  volume = volume or 1000
  return {
    production_type = prod_type,
    volume = volume,
    pipe_picture = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"].fluid_boxes[1].pipe_picture),
    pipe_covers = table.deepcopy(data.raw["assembling-machine"]["chemical-plant"].fluid_boxes[1].pipe_covers),
    pipe_connections = { { position = {x, y}, direction = dir } },
  }
end

-- Direction constants (data.lua scope, defines not available)
local N, E, S, W = 0, 2, 4, 6

data:extend({

  -- ===========================================================================
  -- 1. Steam Methane Reformer (SMR) — 4×4
  --    Endothermic: 2.5 MW, 850°C outlet
  --    CH4 + H2O(steam) → CO + 3H2  (plus excess steam for selectivity)
  --    Real-world: Ni/Al2O3 catalyst in fired tube furnace
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-smr",
    icon = "__base__/graphics/icons/oil-refinery.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.5, result = "pe-smr" },
    max_health = 400,
    corpse = "medium-remnants",
    collision_box = {{-2.4, -2.4}, {2.4, 2.4}},
    selection_box = {{-2.5, -2.5}, {2.5, 2.5}},
    crafting_categories = {"pe-reforming"},
    crafting_speed = 1.0,
    energy_usage = "2500kW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = 10 },
    },
    fluid_boxes = {
      fluidbox("input",  -2, 0,  W),   -- methane in  (west)
      fluidbox("input",   0, -2, N),   -- steam in    (north)
      fluidbox("output",  2, 0,  E),   -- syngas out  (east, ~800°C)
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 2,
    allowed_effects = {"speed", "consumption", "productivity", "quality"},
    working_sound = {
      sound = { filename = "__base__/sound/furnace.ogg", volume = 0.8 },
    },
  },

  -- Item for placing SMR
  { type = "item", name = "pe-smr", icon = "__base__/graphics/icons/oil-refinery.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-a", place_result = "pe-smr", stack_size = 5 },

  -- ===========================================================================
  -- 2. Water-Gas Shift Reactor (WGS) — 3×3
  --    High-temp stage: Fe3O4/Cr2O3 catalyst, 330–430°C, ΔH = -41 kJ/mol
  --    Low-temp stage:  Cu/ZnO/Al2O3 catalyst, 200–250°C (separate recipe)
  --    CO + H2O → CO2 + H2
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-wgs",
    icon = "__base__/graphics/icons/chemical-plant.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.5, result = "pe-wgs" },
    max_health = 300,
    corpse = "medium-remnants",
    collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    crafting_categories = {"pe-wgs"},
    crafting_speed = 1.0,
    energy_usage = "200kW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = 2 },
    },
    fluid_boxes = {
      fluidbox("input",  -2, 0,  W),   -- CO or syngas in
      fluidbox("input",   0, -2, N),   -- steam in
      fluidbox("output",  2, 0,  E),   -- H2-rich gas out
      fluidbox("output",  0,  2, S),   -- CO2 byproduct out
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 2,
    allowed_effects = {"speed", "consumption", "productivity", "quality"},
  },

  { type = "item", name = "pe-wgs", icon = "__base__/graphics/icons/chemical-plant.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-b", place_result = "pe-wgs", stack_size = 10 },

  -- ===========================================================================
  -- 3. Haber-Bosch Reactor — 4×4
  --    Fe/K2O/Al2O3 catalyst (promoted iron), 400–500°C, 150–300 bar
  --    N2 + 3H2 ⇌ 2NH3   ΔH = -92 kJ/mol (exothermic)
  --    Single-pass conversion ~15–25%; recycle loop modelled by long recipe time
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-haber-bosch",
    icon = "__base__/graphics/icons/electric-furnace.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.5, result = "pe-haber-bosch" },
    max_health = 500,
    corpse = "big-remnants",
    collision_box = {{-2.4, -2.4}, {2.4, 2.4}},
    selection_box = {{-2.5, -2.5}, {2.5, 2.5}},
    crafting_categories = {"pe-haber-bosch"},
    crafting_speed = 1.0,
    energy_usage = "300kW",   -- heat management (mostly self-heating from exotherm)
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = 1 },
    },
    fluid_boxes = {
      fluidbox("input",  -2, 0,  W),   -- compressed H2 in
      fluidbox("input",   0, -2, N),   -- compressed N2 in
      fluidbox("output",  2, 0,  E),   -- NH3 out
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 3,
    allowed_effects = {"speed", "consumption", "productivity", "quality"},
  },

  { type = "item", name = "pe-haber-bosch", icon = "__base__/graphics/icons/electric-furnace.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-c", place_result = "pe-haber-bosch", stack_size = 5 },

  -- ===========================================================================
  -- 4. Gas Compressor — 2×3
  --    Multi-stage with intercooling; modelled as single unit
  --    Compresses H2, N2, CO, etc. from atmospheric to ~200 bar equivalent
  --    Energy ~ isothermal work: W = n·R·T·ln(P2/P1)
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-compressor",
    icon = "__base__/graphics/icons/pump.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.3, result = "pe-compressor" },
    max_health = 250,
    corpse = "small-remnants",
    collision_box = {{-1.4, -0.9}, {1.4, 0.9}},
    selection_box = {{-1.5, -1.0}, {1.5, 1.0}},
    crafting_categories = {"pe-compression"},
    crafting_speed = 2.0,
    energy_usage = "750kW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = 0 },
    },
    fluid_boxes = {
      fluidbox("input",  -2, 0,  W, 500),   -- gas in  (atmospheric)
      fluidbox("output",  2, 0,  E, 500),   -- gas out (compressed)
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 2,
    allowed_effects = {"speed", "consumption", "quality"},
  },

  { type = "item", name = "pe-compressor", icon = "__base__/graphics/icons/pump.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-d", place_result = "pe-compressor", stack_size = 20 },

  -- ===========================================================================
  -- 5. Shell-and-Tube Heat Exchanger — 3×3
  --    Counter-current flow; recovers heat from hot process streams
  --    No net energy consumption (purely thermal transfer)
  --    Hot side and cold side are separate fluid paths
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-heat-exchanger",
    icon = "__base__/graphics/icons/heat-exchanger.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.3, result = "pe-heat-exchanger" },
    max_health = 200,
    corpse = "medium-remnants",
    collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    crafting_categories = {"pe-heat-exchange"},
    crafting_speed = 1.0,
    energy_usage = "10kW",   -- instrumentation only
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },
    fluid_boxes = {
      fluidbox("input",  -2,  0,  W),   -- hot stream in
      fluidbox("output",  2,  0,  E),   -- hot stream out (cooled)
      fluidbox("input",   0,  2,  S),   -- cold stream in
      fluidbox("output",  0, -2,  N),   -- cold stream out (heated)
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 0,
  },

  { type = "item", name = "pe-heat-exchanger", icon = "__base__/graphics/icons/heat-exchanger.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-e", place_result = "pe-heat-exchanger", stack_size = 10 },

  -- ===========================================================================
  -- 6. Flash Separator — 2×3
  --    Adiabatic pressure reduction; VLE calculation done in control.lua
  --    Separates a mixed stream into vapour and liquid fractions
  --    Used after SMR (quench), after Haber-Bosch (NH3 condensation), etc.
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-flash-separator",
    icon = "__base__/graphics/icons/storage-tank.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.3, result = "pe-flash-separator" },
    max_health = 200,
    corpse = "small-remnants",
    collision_box = {{-0.9, -1.4}, {0.9, 1.4}},
    selection_box = {{-1.0, -1.5}, {1.0, 1.5}},
    crafting_categories = {"pe-flash"},
    crafting_speed = 1.0,
    energy_usage = "20kW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },
    fluid_boxes = {
      fluidbox("input",   0, -2, N),   -- mixed feed in  (top)
      fluidbox("output",  0,  2, S),   -- liquid out     (bottom)
      fluidbox("output",  2,  0, E),   -- vapour out     (side)
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 0,
  },

  { type = "item", name = "pe-flash-separator", icon = "__base__/graphics/icons/storage-tank.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-f", place_result = "pe-flash-separator", stack_size = 20 },

  -- ===========================================================================
  -- 7. Steam Cracker — 4×4
  --    Fired tubular cracker; 750–850°C, millisecond residence time
  --    C2H6 + steam → C2H4 + H2 + (CH4 by-product)   ΔH = +137 kJ/mol
  --    Also cracks propane, naphtha (add recipes as mod expands)
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-cracker",
    icon = "__base__/graphics/icons/oil-refinery.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.5, result = "pe-cracker" },
    max_health = 400,
    corpse = "big-remnants",
    collision_box = {{-2.4, -2.4}, {2.4, 2.4}},
    selection_box = {{-2.5, -2.5}, {2.5, 2.5}},
    crafting_categories = {"pe-cracking"},
    crafting_speed = 1.0,
    energy_usage = "2000kW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
      emissions_per_minute = { pollution = 8 },
    },
    fluid_boxes = {
      fluidbox("input",  -2,  0, W),   -- feedstock in (ethane, propane, naphtha)
      fluidbox("input",   0, -2, N),   -- dilution steam in
      fluidbox("output",  2,  0, E),   -- cracked gas out
      fluidbox("output",  0,  2, S),   -- pyrolysis fuel oil out
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 2,
    allowed_effects = {"speed", "consumption", "productivity", "quality"},
  },

  { type = "item", name = "pe-cracker", icon = "__base__/graphics/icons/oil-refinery.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-g", place_result = "pe-cracker", stack_size = 5 },

  -- ===========================================================================
  -- 8. Methanol Reactor — 3×3
  --    Cu/ZnO/Al2O3 catalyst, 250°C, 50–100 bar
  --    CO + 2H2 → CH3OH   ΔH = -90 kJ/mol (exothermic, cooling required)
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-methanol-reactor",
    icon = "__base__/graphics/icons/chemical-plant.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.3, result = "pe-methanol-reactor" },
    max_health = 300,
    corpse = "medium-remnants",
    collision_box = {{-1.4, -1.4}, {1.4, 1.4}},
    selection_box = {{-1.5, -1.5}, {1.5, 1.5}},
    crafting_categories = {"pe-methanol"},
    crafting_speed = 1.0,
    energy_usage = "100kW",   -- cooling load (exothermic)
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },
    fluid_boxes = {
      fluidbox("input",  -2,  0, W),   -- CO in  (or syngas)
      fluidbox("input",   0, -2, N),   -- compressed H2 in
      fluidbox("output",  2,  0, E),   -- methanol out
      fluidbox("output",  0,  2, S),   -- water byproduct out
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 2,
    allowed_effects = {"speed", "consumption", "productivity", "quality"},
  },

  { type = "item", name = "pe-methanol-reactor", icon = "__base__/graphics/icons/chemical-plant.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-h", place_result = "pe-methanol-reactor", stack_size = 10 },

  -- ===========================================================================
  -- 9. PSA / Syngas Splitter — 2×3
  --    Pressure Swing Adsorption: separates H2 from CO in syngas
  --    Also models membrane separation or cryogenic separation (simplified)
  -- ===========================================================================
  {
    type = "assembling-machine",
    name = "pe-psa-splitter",
    icon = "__base__/graphics/icons/storage-tank.png",
    icon_size = 64,
    flags = {"placeable-neutral", "player-creation"},
    minable = { mining_time = 0.3, result = "pe-psa-splitter" },
    max_health = 250,
    corpse = "medium-remnants",
    collision_box = {{-0.9, -1.4}, {0.9, 1.4}},
    selection_box = {{-1.0, -1.5}, {1.0, 1.5}},
    crafting_categories = {"pe-syngas-split"},
    crafting_speed = 1.0,
    energy_usage = "150kW",
    energy_source = {
      type = "electric",
      usage_priority = "secondary-input",
    },
    fluid_boxes = {
      fluidbox("input",  0, -2, N),   -- syngas in
      fluidbox("output", 2,  0, E),   -- H2 out (high purity)
      fluidbox("output", 0,  2, S),   -- CO out (or tail gas)
    },
    fluid_boxes_off_when_no_fluid_recipe = true,
    module_slots = 1,
  },

  { type = "item", name = "pe-psa-splitter", icon = "__base__/graphics/icons/storage-tank.png",
    icon_size = 64, subgroup = "pe-machines", order = "pe-d-i", place_result = "pe-psa-splitter", stack_size = 10 },

})
