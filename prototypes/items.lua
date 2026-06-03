-- =============================================================================
-- Catalyst and equipment items
-- Catalysts are consumed slowly (long crafting times model catalyst life)
-- =============================================================================

data:extend({

  -- -------------------------------------------------------------------------
  -- Catalyst items
  -- -------------------------------------------------------------------------

  -- Nickel catalyst — Steam Methane Reforming (Ni/Al2O3)
  -- Real life: ~15 kg/m³ catalyst bed, replaced every 3–5 years
  {
    type = "item",
    name = "pe-nickel-catalyst",
    icon = "__base__/graphics/icons/iron-plate.png",
    icon_size = 64,
    subgroup = "pe-catalysts",
    order = "a[pe-cat]-a",
    stack_size = 100,
  },

  -- Iron-chromia catalyst — High-temperature WGS (Fe3O4/Cr2O3)
  -- Active at 300–450°C
  {
    type = "item",
    name = "pe-iron-chromia-catalyst",
    icon = "__base__/graphics/icons/iron-plate.png",
    icon_size = 64,
    subgroup = "pe-catalysts",
    order = "a[pe-cat]-b",
    stack_size = 100,
  },

  -- Copper-zinc catalyst — Low-temperature WGS and methanol synthesis (Cu/ZnO/Al2O3)
  -- Active at 200–270°C
  {
    type = "item",
    name = "pe-copper-zinc-catalyst",
    icon = "__base__/graphics/icons/copper-plate.png",
    icon_size = 64,
    subgroup = "pe-catalysts",
    order = "a[pe-cat]-c",
    stack_size = 100,
  },

  -- Iron-ruthenium catalyst — Haber-Bosch ammonia synthesis (Fe/K2O/Al2O3 or Ru/C)
  -- Ruthenium-based is ~10x more active than iron but more expensive
  {
    type = "item",
    name = "pe-iron-catalyst",
    icon = "__base__/graphics/icons/iron-plate.png",
    icon_size = 64,
    subgroup = "pe-catalysts",
    order = "a[pe-cat]-d",
    stack_size = 100,
  },

  -- -------------------------------------------------------------------------
  -- Equipment / hardware items used in reactor construction
  -- -------------------------------------------------------------------------

  -- Refractory lining — insulates high-temperature reactors
  {
    type = "item",
    name = "pe-refractory-brick",
    icon = "__base__/graphics/icons/stone-brick.png",
    icon_size = 64,
    subgroup = "pe-materials",
    order = "b[pe-mat]-a",
    stack_size = 200,
  },

  -- Stainless steel tube — heat exchanger tube bundles, reform tubes
  {
    type = "item",
    name = "pe-stainless-tube",
    icon = "__base__/graphics/icons/pipe.png",
    icon_size = 64,
    subgroup = "pe-materials",
    order = "b[pe-mat]-b",
    stack_size = 100,
  },

  -- Pressure vessel — for high-pressure reactors (Haber-Bosch, methanol)
  {
    type = "item",
    name = "pe-pressure-vessel",
    icon = "__base__/graphics/icons/steel-plate.png",
    icon_size = 64,
    subgroup = "pe-materials",
    order = "b[pe-mat]-c",
    stack_size = 20,
  },

  -- -------------------------------------------------------------------------
  -- Intermediate / product items
  -- -------------------------------------------------------------------------

  -- Ammonia (liquid, stored in tank) — also represented as fluid
  {
    type = "item",
    name = "pe-ammonium-nitrate",
    icon = "__base__/graphics/icons/solid-fuel.png",
    icon_size = 64,
    subgroup = "pe-products",
    order = "c[pe-prod]-a",
    stack_size = 200,
  },

  -- Urea — NH3 + CO2 at high pressure; fertilizer end product
  {
    type = "item",
    name = "pe-urea",
    icon = "__base__/graphics/icons/solid-fuel.png",
    icon_size = 64,
    subgroup = "pe-products",
    order = "c[pe-prod]-b",
    stack_size = 200,
  },

  -- Polyethylene pellets — from ethylene polymerization
  {
    type = "item",
    name = "pe-polyethylene",
    icon = "__base__/graphics/icons/plastic-bar.png",
    icon_size = 64,
    subgroup = "pe-products",
    order = "c[pe-prod]-c",
    stack_size = 200,
  },

  -- -------------------------------------------------------------------------
  -- Item subgroups (registered here, used in item-subgroup prototypes)
  -- -------------------------------------------------------------------------
  {
    type = "item-subgroup",
    name = "pe-catalysts",
    group = "production",
    order = "pe-a",
  },
  {
    type = "item-subgroup",
    name = "pe-materials",
    group = "production",
    order = "pe-b",
  },
  {
    type = "item-subgroup",
    name = "pe-products",
    group = "production",
    order = "pe-c",
  },
  {
    type = "item-subgroup",
    name = "pe-machines",
    group = "production",
    order = "pe-d",
  },

})
