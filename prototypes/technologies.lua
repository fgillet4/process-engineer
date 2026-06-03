-- =============================================================================
-- Technology tree — mirrors real industrial development sequence:
--   1. Steam reforming & syngas (foundation)
--   2. Hydrogen production (WGS + PSA)
--   3. Ammonia synthesis loop (compression + Haber-Bosch)
--   4. Methanol + plastics (cracking + C2 chemistry)
--   5. Urea / fertilizers (downstream of NH3)
-- =============================================================================

-- Helper: standard unlock list for a technology
local function unlocks(names)
  local effects = {}
  for _, name in ipairs(names) do
    table.insert(effects, { type = "unlock-recipe", recipe = name })
  end
  return effects
end

data:extend({

  -- ===========================================================================
  -- Tier 1: Steam Reforming
  -- Requires: chemical science packs
  -- Unlocks: SMR, syngas cooling, syngas splitting, catalyst materials
  -- ===========================================================================
  {
    type = "technology",
    name = "pe-steam-reforming",
    icon = "__base__/graphics/technology/oil-processing.png",
    icon_size = 256,
    prerequisites = { "oil-processing", "electric-furnace" },
    unit = {
      count = 100,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
      },
      time = 30,
    },
    effects = unlocks({
      "pe-smr",
      "pe-syngas-cooling",
      "pe-syngas-split",
      "pe-nickel-catalyst",
      "pe-refractory-brick",
      "pe-stainless-tube",
      "pe-heat-exchanger",
      "pe-flash-separator",
      "pe-psa-splitter",
      "pe-smr",           -- machine recipe
      "pe-heat-exchanger",
      "pe-flash-separator",
      "pe-psa-splitter",
    }),
  },

  -- ===========================================================================
  -- Tier 2: Hydrogen Production
  -- WGS stages + compressor; produces pure H2 from syngas
  -- ===========================================================================
  {
    type = "technology",
    name = "pe-hydrogen-production",
    icon = "__base__/graphics/technology/advanced-electronics.png",
    icon_size = 256,
    prerequisites = { "pe-steam-reforming" },
    unit = {
      count = 150,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
      },
      time = 45,
    },
    effects = unlocks({
      "pe-wgs-ht",
      "pe-wgs-lt",
      "pe-compress-hydrogen",
      "pe-iron-chromia-catalyst",
      "pe-copper-zinc-catalyst",
      "pe-wgs",            -- machine recipe
      "pe-compressor",
    }),
  },

  -- ===========================================================================
  -- Tier 3: Ammonia Synthesis (Haber-Bosch Loop)
  -- Requires H2 from Tier 2 + N2 compression
  -- ===========================================================================
  {
    type = "technology",
    name = "pe-ammonia-synthesis",
    icon = "__base__/graphics/technology/production-science-pack.png",
    icon_size = 256,
    prerequisites = { "pe-hydrogen-production" },
    unit = {
      count = 200,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
        { "production-science-pack", 1 },
      },
      time = 60,
    },
    effects = unlocks({
      "pe-compress-nitrogen",
      "pe-haber-bosch",
      "pe-iron-catalyst",
      "pe-pressure-vessel",
      "pe-haber-bosch",    -- machine recipe
    }),
  },

  -- ===========================================================================
  -- Tier 4: C2 Chemistry (Steam Cracking)
  -- ===========================================================================
  {
    type = "technology",
    name = "pe-steam-cracking",
    icon = "__base__/graphics/technology/plastics.png",
    icon_size = 256,
    prerequisites = { "pe-steam-reforming", "advanced-oil-processing" },
    unit = {
      count = 200,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
        { "production-science-pack", 1 },
      },
      time = 60,
    },
    effects = unlocks({
      "pe-cracking-ethane",
      "pe-cracker",        -- machine recipe
    }),
  },

  -- ===========================================================================
  -- Tier 4b: Methanol Synthesis
  -- ===========================================================================
  {
    type = "technology",
    name = "pe-methanol-chemistry",
    icon = "__base__/graphics/technology/sulfur-processing.png",
    icon_size = 256,
    prerequisites = { "pe-hydrogen-production" },
    unit = {
      count = 150,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
      },
      time = 45,
    },
    effects = unlocks({
      "pe-methanol-synthesis",
      "pe-methanol-reactor",  -- machine recipe
    }),
  },

  -- ===========================================================================
  -- Tier 5: Fertilizer Chemistry (Urea)
  -- End-game: combines NH3 + CO2 from the upstream process chain
  -- ===========================================================================
  {
    type = "technology",
    name = "pe-fertilizer-chemistry",
    icon = "__base__/graphics/technology/space-science-pack.png",
    icon_size = 256,
    prerequisites = { "pe-ammonia-synthesis" },
    unit = {
      count = 300,
      ingredients = {
        { "automation-science-pack", 1 },
        { "logistic-science-pack",   1 },
        { "chemical-science-pack",   1 },
        { "production-science-pack", 1 },
        { "utility-science-pack",    1 },
      },
      time = 90,
    },
    effects = unlocks({
      "pe-urea-synthesis",
      -- pe-urea-synthesis machine uses assembling-machine or pe-methanol-reactor
    }),
  },

})
