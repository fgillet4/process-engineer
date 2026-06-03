-- =============================================================================
-- Chemical species as Factorio fluids
-- gas_temperature: below this = liquid, at/above = gas (°C)
-- For species that are gases at room temp, gas_temperature is set very low
-- so they're always in gas phase during normal gameplay.
-- heat_capacity is per-unit (kJ per 1°C temperature change per fluid unit)
-- =============================================================================

data:extend({

  -- H2 — always gas at game temperatures (bp = -253°C); gas_temperature = -200
  {
    type = "fluid",
    name = "pe-hydrogen",
    default_temperature = 25,
    max_temperature = 900,
    gas_temperature = -200,
    heat_capacity = "14.3kJ",
    base_color  = {r=0.4, g=0.7, b=1.0},
    flow_color  = {r=0.6, g=0.85, b=1.0},
    icon = "__base__/graphics/icons/fluid/petroleum-gas.png",
    icon_size = 64,
    order = "a[pe]-a[hydrogen]",
  },

  -- N2 — always gas (bp = -196°C)
  {
    type = "fluid",
    name = "pe-nitrogen",
    default_temperature = 25,
    max_temperature = 900,
    gas_temperature = -150,
    heat_capacity = "1.04kJ",
    base_color  = {r=0.8, g=0.8, b=0.85},
    flow_color  = {r=0.9, g=0.9, b=0.95},
    icon = "__base__/graphics/icons/fluid/petroleum-gas.png",
    icon_size = 64,
    order = "a[pe]-b[nitrogen]",
  },

  -- CH4 — always gas (bp = -161°C)
  {
    type = "fluid",
    name = "pe-methane",
    default_temperature = 25,
    max_temperature = 1000,
    gas_temperature = -100,
    heat_capacity = "2.22kJ",
    base_color  = {r=1.0, g=0.65, b=0.1},
    flow_color  = {r=1.0, g=0.8,  b=0.3},
    icon = "__base__/graphics/icons/fluid/petroleum-gas.png",
    icon_size = 64,
    order = "a[pe]-c[methane]",
  },

  -- CO — always gas (bp = -191°C)
  {
    type = "fluid",
    name = "pe-co",
    default_temperature = 25,
    max_temperature = 1200,
    gas_temperature = -150,
    heat_capacity = "1.04kJ",
    base_color  = {r=0.6, g=0.4, b=0.8},
    flow_color  = {r=0.75, g=0.55, b=0.9},
    icon = "__base__/graphics/icons/fluid/petroleum-gas.png",
    icon_size = 64,
    order = "a[pe]-d[co]",
  },

  -- CO2 — gas above -78.5°C (sublimation); always gas in game context
  {
    type = "fluid",
    name = "pe-co2",
    default_temperature = 25,
    max_temperature = 1000,
    gas_temperature = -50,
    heat_capacity = "0.846kJ",
    base_color  = {r=0.35, g=0.35, b=0.35},
    flow_color  = {r=0.5,  g=0.5,  b=0.5},
    icon = "__base__/graphics/icons/fluid/crude-oil.png",
    icon_size = 64,
    order = "a[pe]-e[co2]",
  },

  -- NH3 — gas above -33°C; liquid at room temp under pressure
  -- In game: stored/transported as liquid (refrigerant grade), gas_temperature = -33
  {
    type = "fluid",
    name = "pe-ammonia",
    default_temperature = 25,
    max_temperature = 600,
    gas_temperature = -33,
    heat_capacity = "2.18kJ",
    base_color  = {r=0.2, g=0.85, b=0.3},
    flow_color  = {r=0.4, g=1.0,  b=0.5},
    icon = "__base__/graphics/icons/fluid/sulfuric-acid.png",
    icon_size = 64,
    order = "a[pe]-f[ammonia]",
  },

  -- Syngas (H2/CO mixture) — always gas
  {
    type = "fluid",
    name = "pe-syngas",
    default_temperature = 800,
    max_temperature = 1000,
    gas_temperature = -200,
    heat_capacity = "6.8kJ",
    base_color  = {r=1.0, g=0.9, b=0.2},
    flow_color  = {r=1.0, g=1.0, b=0.4},
    icon = "__base__/graphics/icons/fluid/petroleum-gas.png",
    icon_size = 64,
    order = "a[pe]-g[syngas]",
  },

  -- C2H6 — gas at room temp (bp = -89°C)
  {
    type = "fluid",
    name = "pe-ethane",
    default_temperature = 25,
    max_temperature = 900,
    gas_temperature = -60,
    heat_capacity = "1.75kJ",
    base_color  = {r=1.0, g=0.55, b=0.2},
    flow_color  = {r=1.0, g=0.7,  b=0.4},
    icon = "__base__/graphics/icons/fluid/light-oil.png",
    icon_size = 64,
    order = "a[pe]-h[ethane]",
  },

  -- C2H4 — gas at room temp (bp = -104°C)
  {
    type = "fluid",
    name = "pe-ethylene",
    default_temperature = 25,
    max_temperature = 900,
    gas_temperature = -80,
    heat_capacity = "1.55kJ",
    base_color  = {r=1.0, g=0.4, b=0.6},
    flow_color  = {r=1.0, g=0.6, b=0.75},
    icon = "__base__/graphics/icons/fluid/light-oil.png",
    icon_size = 64,
    order = "a[pe]-i[ethylene]",
  },

  -- CH3OH — liquid at room temp (bp = 64.7°C); gas_temperature = 65
  {
    type = "fluid",
    name = "pe-methanol",
    default_temperature = 25,
    max_temperature = 400,
    gas_temperature = 65,
    heat_capacity = "2.53kJ",
    base_color  = {r=0.3, g=0.9, b=0.6},
    flow_color  = {r=0.5, g=1.0, b=0.75},
    icon = "__base__/graphics/icons/fluid/lubricant.png",
    icon_size = 64,
    order = "a[pe]-j[methanol]",
  },

  -- H2 compressed — always gas
  {
    type = "fluid",
    name = "pe-hydrogen-compressed",
    default_temperature = 40,
    max_temperature = 200,
    gas_temperature = -200,
    heat_capacity = "14.3kJ",
    base_color  = {r=0.2, g=0.4, b=0.9},
    flow_color  = {r=0.3, g=0.55, b=1.0},
    icon = "__base__/graphics/icons/fluid/petroleum-gas.png",
    icon_size = 64,
    order = "a[pe]-k[hydrogen-compressed]",
  },

  -- N2 compressed — always gas
  {
    type = "fluid",
    name = "pe-nitrogen-compressed",
    default_temperature = 40,
    max_temperature = 200,
    gas_temperature = -150,
    heat_capacity = "1.04kJ",
    base_color  = {r=0.5, g=0.5, b=0.7},
    flow_color  = {r=0.65, g=0.65, b=0.8},
    icon = "__base__/graphics/icons/fluid/petroleum-gas.png",
    icon_size = 64,
    order = "a[pe]-l[nitrogen-compressed]",
  },

})
