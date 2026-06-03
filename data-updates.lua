-- =============================================================================
-- data-updates.lua — runs after all mods' data.lua
-- Here we copy graphics from base game assembling machines so the entities
-- render correctly without requiring custom art assets.
-- Replace these with real sprites when you have them.
-- =============================================================================

local function copy_animation(src_name, tgt_name)
  local src = data.raw["assembling-machine"][src_name]
  local tgt = data.raw["assembling-machine"][tgt_name]
  if not src or not tgt then return end
  tgt.animation          = table.deepcopy(src.animation)
  tgt.working_sound      = table.deepcopy(src.working_sound)
  tgt.open_sound         = table.deepcopy(src.open_sound)
  tgt.close_sound        = table.deepcopy(src.close_sound)
  tgt.idle_animation     = table.deepcopy(src.idle_animation)
  tgt.working_visualisations = table.deepcopy(src.working_visualisations)
end

-- High-temperature fired heaters → oil refinery sprite
copy_animation("oil-refinery",       "pe-smr")
copy_animation("oil-refinery",       "pe-cracker")

-- Chemical reactors → chemical plant sprite
copy_animation("chemical-plant",     "pe-wgs")
copy_animation("chemical-plant",     "pe-methanol-reactor")

-- Pressure reactor → electric furnace (large, imposing)
copy_animation("electric-furnace",   "pe-haber-bosch")

-- Rotating machinery → assembling-machine-3
copy_animation("assembling-machine-3", "pe-compressor")

-- Heat exchangers and separators → assembling-machine-2 (smaller)
copy_animation("assembling-machine-2", "pe-heat-exchanger")
copy_animation("assembling-machine-2", "pe-flash-separator")
copy_animation("assembling-machine-2", "pe-psa-splitter")

-- Also copy fluid box pipe pictures to all entities that use the helper
-- (some pipe connection pictures may still be nil; Factorio tolerates nil here)
