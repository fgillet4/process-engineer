-- =============================================================================
-- Chemical reactions as Factorio recipes
-- Stoichiometry is real (molar ratios from balanced equations)
-- Fluid amounts scaled to 100-unit base (1 unit ≈ 1 mol for mass balance)
-- Catalyst items consumed at low rate to model catalyst deactivation/replacement
-- =============================================================================

data:extend({

  -- ===========================================================================
  -- STEAM METHANE REFORMING (SMR)
  -- Overall: CH4 + H2O(g) → CO + 3H2   ΔH°298 = +206.1 kJ/mol
  -- In practice run with S:C = 3 to suppress coke; outlet ~800°C
  -- Single-pass (simplified): 1 mol CH4 → 1 mol CO + 3 mol H2
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-smr",
    category = "pe-reforming",
    enabled = false,
    energy_required = 8,   -- seconds; long because endothermic + catalyst contact time
    ingredients = {
      { type = "fluid", name = "pe-methane",               amount = 100 },
      { type = "fluid", name = "steam",                    amount = 300,
        minimum_temperature = 500 },                                         -- >500°C steam
      { type = "item",  name = "pe-nickel-catalyst",       amount = 1  },
    },
    results = {
      -- Syngas at 800°C (hot, needs quench/HX before WGS)
      { type = "fluid", name = "pe-syngas", amount = 400, temperature = 800 },
    },
    main_product = "pe-syngas",
    crafting_machine_tint = {
      primary   = {r=1.0, g=0.6, b=0.1, a=1},
      secondary = {r=0.8, g=0.4, b=0.0, a=1},
    },
  },

  -- ===========================================================================
  -- SYNGAS COOLING (before WGS)
  -- Hot syngas quench: cool from 800°C to 350°C using BFW (boiler feed water)
  -- Produces high-pressure steam as valuable by-product (waste heat recovery)
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-syngas-cooling",
    category = "pe-heat-exchange",
    enabled = false,
    energy_required = 4,
    ingredients = {
      { type = "fluid", name = "pe-syngas", amount = 400, minimum_temperature = 700 },
      { type = "fluid", name = "water",     amount = 200 },
    },
    results = {
      { type = "fluid", name = "pe-syngas", amount = 400, temperature = 350 },
      { type = "fluid", name = "steam",     amount = 200, temperature = 500 },  -- HP steam by-product
    },
    main_product = "pe-syngas",
  },

  -- ===========================================================================
  -- SYNGAS SPLITTING (PSA)
  -- Separates syngas into H2 and CO product streams
  -- PSA: H2 purity ~99.9%, CO recovery ~80–90%
  -- Feed is 3:1 H2:CO by moles → 300 H2 + 100 CO per 400 syngas
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-syngas-split",
    category = "pe-syngas-split",
    enabled = false,
    energy_required = 4,
    ingredients = {
      { type = "fluid", name = "pe-syngas", amount = 400 },
    },
    results = {
      { type = "fluid", name = "pe-hydrogen", amount = 280 },  -- 93% H2 recovery
      { type = "fluid", name = "pe-co",       amount = 90  },  -- 90% CO recovery
    },
  },

  -- ===========================================================================
  -- WATER-GAS SHIFT — High Temperature (HT-WGS)
  -- CO + H2O → CO2 + H2   ΔH°298 = -41.2 kJ/mol
  -- Fe3O4/Cr2O3 catalyst, 330–430°C
  -- Equilibrium conversion ~70–80% at 400°C
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-wgs-ht",
    category = "pe-wgs",
    enabled = false,
    energy_required = 5,
    ingredients = {
      { type = "fluid", name = "pe-co",                       amount = 100 },
      { type = "fluid", name = "steam",                       amount = 120,
        minimum_temperature = 150 },
      { type = "item",  name = "pe-iron-chromia-catalyst",    amount = 1   },
    },
    results = {
      { type = "fluid", name = "pe-hydrogen",  amount = 75  },  -- ~75% conversion
      { type = "fluid", name = "pe-co2",       amount = 75  },
      { type = "fluid", name = "pe-co",        amount = 25  },  -- unreacted CO
    },
    main_product = "pe-hydrogen",
  },

  -- ===========================================================================
  -- WATER-GAS SHIFT — Low Temperature (LT-WGS)
  -- Same reaction, Cu/ZnO/Al2O3 catalyst, 200–250°C
  -- Better equilibrium conversion ~95–98% — follow-on stage after HT-WGS
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-wgs-lt",
    category = "pe-wgs",
    enabled = false,
    energy_required = 7,
    ingredients = {
      { type = "fluid", name = "pe-co",                       amount = 100 },
      { type = "fluid", name = "steam",                       amount = 110,
        minimum_temperature = 100 },
      { type = "item",  name = "pe-copper-zinc-catalyst",     amount = 1   },
    },
    results = {
      { type = "fluid", name = "pe-hydrogen",  amount = 96  },  -- ~96% conversion
      { type = "fluid", name = "pe-co2",       amount = 96  },
      { type = "fluid", name = "pe-co",        amount = 4   },  -- trace unconverted
    },
    main_product = "pe-hydrogen",
  },

  -- ===========================================================================
  -- GAS COMPRESSION — Hydrogen
  -- Multistage centrifugal compressor, ~200 bar outlet
  -- Isothermal work: W = n·R·T·ln(P2/P1) ≈ 2.7 kWh/kg H2 at η=0.75
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-compress-hydrogen",
    category = "pe-compression",
    enabled = false,
    energy_required = 2,
    ingredients = {
      { type = "fluid", name = "pe-hydrogen", amount = 100 },
    },
    results = {
      { type = "fluid", name = "pe-hydrogen-compressed", amount = 100, temperature = 40 },
    },
    main_product = "pe-hydrogen-compressed",
  },

  -- ===========================================================================
  -- GAS COMPRESSION — Nitrogen
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-compress-nitrogen",
    category = "pe-compression",
    enabled = false,
    energy_required = 2,
    ingredients = {
      { type = "fluid", name = "pe-nitrogen", amount = 100 },
    },
    results = {
      { type = "fluid", name = "pe-nitrogen-compressed", amount = 100, temperature = 40 },
    },
    main_product = "pe-nitrogen-compressed",
  },

  -- ===========================================================================
  -- HABER-BOSCH AMMONIA SYNTHESIS
  -- N2 + 3H2 ⇌ 2NH3   ΔH°298 = -92.4 kJ/mol
  -- Promoted Fe catalyst, 400–500°C, 150–300 bar
  -- Single-pass conversion ~15–20%; modelled as effective 22% per pass
  -- Real plants use recycle loop — here modelled via long energy_required
  -- Stoich ratio: N2:H2 = 1:3 by moles → 50 + 150 → 200 NH3 (at 22% conv.)
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-haber-bosch",
    category = "pe-haber-bosch",
    enabled = false,
    energy_required = 12,   -- long time models effective recycle loop
    ingredients = {
      { type = "fluid", name = "pe-nitrogen-compressed", amount = 50  },
      { type = "fluid", name = "pe-hydrogen-compressed", amount = 150 },
      { type = "item",  name = "pe-iron-catalyst",       amount = 1   },
    },
    results = {
      -- 22% effective conversion per recipe cycle (represents recycle loop)
      { type = "fluid", name = "pe-ammonia", amount = 44, temperature = 50 },
    },
    main_product = "pe-ammonia",
  },

  -- ===========================================================================
  -- STEAM CRACKING — Ethane
  -- C2H6 → C2H4 + H2   ΔH°298 = +136.9 kJ/mol
  -- 750–850°C, 0.1–0.3 s residence time, diluted with steam
  -- Ethane conversion ~65%; ethylene selectivity ~80%
  -- By-products: methane (~10%), propylene, heavier fractions
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-cracking-ethane",
    category = "pe-cracking",
    enabled = false,
    energy_required = 6,
    ingredients = {
      { type = "fluid", name = "pe-ethane", amount = 100 },
      { type = "fluid", name = "steam",     amount = 100, minimum_temperature = 500 },
    },
    results = {
      { type = "fluid", name = "pe-ethylene", amount = 52 },  -- 65% conv × 80% sel
      { type = "fluid", name = "pe-hydrogen", amount = 52 },
      { type = "fluid", name = "pe-methane",  amount = 13 },  -- by-product
      { type = "fluid", name = "pe-ethane",   amount = 35 },  -- unconverted recycle
    },
    main_product = "pe-ethylene",
  },

  -- ===========================================================================
  -- METHANOL SYNTHESIS
  -- CO + 2H2 → CH3OH   ΔH°298 = -90.7 kJ/mol
  -- Cu/ZnO/Al2O3 catalyst, 250°C, 50–100 bar
  -- Single-pass conversion ~14–17%; recycle loop to ~97% overall
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-methanol-synthesis",
    category = "pe-methanol",
    enabled = false,
    energy_required = 8,
    ingredients = {
      { type = "fluid", name = "pe-co",                   amount = 50  },
      { type = "fluid", name = "pe-hydrogen-compressed",  amount = 100 },
      { type = "item",  name = "pe-copper-zinc-catalyst", amount = 1   },
    },
    results = {
      { type = "fluid", name = "pe-methanol",  amount = 55 },   -- 90% eff. conversion
      { type = "fluid", name = "water",        amount = 55 },   -- stoichiometric H2O
    },
    main_product = "pe-methanol",
  },

  -- ===========================================================================
  -- UREA SYNTHESIS
  -- 2NH3 + CO2 → CO(NH2)2 + H2O   ΔH ≈ -84 kJ/mol
  -- 180–190°C, 140–175 bar; two-step via ammonium carbamate intermediate
  -- NH3:CO2 = 2.7–4.0 (N:C excess to drive conversion)
  -- ===========================================================================
  {
    type = "recipe",
    name = "pe-urea-synthesis",
    category = "pe-urea",
    enabled = false,
    energy_required = 10,
    ingredients = {
      { type = "fluid", name = "pe-ammonia", amount = 100 },
      { type = "fluid", name = "pe-co2",     amount = 44  },
    },
    results = {
      { type = "item",  name = "pe-urea",    amount = 4   },    -- solid product
      { type = "fluid", name = "water",      amount = 18  },
    },
    main_product = "pe-urea",
  },

  -- ===========================================================================
  -- CATALYST CRAFTING RECIPES (in assembling machines)
  -- ===========================================================================

  -- Nickel catalyst (Ni/Al2O3): precipitated Ni on alumina support
  {
    type = "recipe",
    name = "pe-nickel-catalyst",
    enabled = false,
    energy_required = 30,
    ingredients = {
      { type = "item", name = "iron-plate",    amount = 5  },   -- Ni proxy (no Ni ore)
      { type = "item", name = "stone",         amount = 10 },   -- Al2O3 proxy
    },
    results = {
      { type = "item", name = "pe-nickel-catalyst", amount = 10 },
    },
  },

  -- Iron-chromia catalyst (Fe3O4/Cr2O3)
  {
    type = "recipe",
    name = "pe-iron-chromia-catalyst",
    enabled = false,
    energy_required = 20,
    ingredients = {
      { type = "item", name = "iron-plate",    amount = 8  },
    },
    results = {
      { type = "item", name = "pe-iron-chromia-catalyst", amount = 10 },
    },
  },

  -- Copper-zinc catalyst (Cu/ZnO/Al2O3)
  {
    type = "recipe",
    name = "pe-copper-zinc-catalyst",
    enabled = false,
    energy_required = 25,
    ingredients = {
      { type = "item", name = "copper-plate",  amount = 6  },
      { type = "item", name = "iron-plate",    amount = 3  },
      { type = "item", name = "stone",         amount = 5  },
    },
    results = {
      { type = "item", name = "pe-copper-zinc-catalyst", amount = 10 },
    },
  },

  -- Iron catalyst (promoted Fe for Haber-Bosch)
  {
    type = "recipe",
    name = "pe-iron-catalyst",
    enabled = false,
    energy_required = 20,
    ingredients = {
      { type = "item", name = "iron-plate",    amount = 10 },
    },
    results = {
      { type = "item", name = "pe-iron-catalyst", amount = 10 },
    },
  },

  -- Refractory brick (from stone + heat)
  {
    type = "recipe",
    name = "pe-refractory-brick",
    enabled = false,
    energy_required = 5,
    ingredients = {
      { type = "item", name = "stone-brick",   amount = 4  },
    },
    results = {
      { type = "item", name = "pe-refractory-brick", amount = 4 },
    },
  },

  -- Stainless tube (from steel)
  {
    type = "recipe",
    name = "pe-stainless-tube",
    enabled = false,
    energy_required = 3,
    ingredients = {
      { type = "item", name = "steel-plate",   amount = 3  },
    },
    results = {
      { type = "item", name = "pe-stainless-tube", amount = 4 },
    },
  },

  -- Pressure vessel (from steel + processing units)
  {
    type = "recipe",
    name = "pe-pressure-vessel",
    enabled = false,
    energy_required = 10,
    ingredients = {
      { type = "item", name = "steel-plate",   amount = 20 },
      { type = "item", name = "iron-plate",    amount = 10 },
    },
    results = {
      { type = "item", name = "pe-pressure-vessel", amount = 1 },
    },
  },

  -- ===========================================================================
  -- MACHINE CRAFTING RECIPES
  -- ===========================================================================

  {
    type = "recipe", name = "pe-smr", enabled = false, energy_required = 10,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 30 },
      { type = "item", name = "pe-refractory-brick",  amount = 20 },
      { type = "item", name = "pe-stainless-tube",    amount = 15 },
      { type = "item", name = "pipe",                 amount = 10 },
      { type = "item", name = "electronic-circuit",   amount = 10 },
    },
    results = { { type = "item", name = "pe-smr", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-wgs", enabled = false, energy_required = 6,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 15 },
      { type = "item", name = "pe-stainless-tube",    amount = 8  },
      { type = "item", name = "pipe",                 amount = 8  },
      { type = "item", name = "electronic-circuit",   amount = 8  },
    },
    results = { { type = "item", name = "pe-wgs", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-haber-bosch", enabled = false, energy_required = 12,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 40 },
      { type = "item", name = "pe-pressure-vessel",   amount = 2  },
      { type = "item", name = "pe-stainless-tube",    amount = 20 },
      { type = "item", name = "pipe",                 amount = 15 },
      { type = "item", name = "advanced-circuit",     amount = 15 },
    },
    results = { { type = "item", name = "pe-haber-bosch", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-compressor", enabled = false, energy_required = 5,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 15 },
      { type = "item", name = "electric-engine-unit", amount = 5  },
      { type = "item", name = "pipe",                 amount = 8  },
      { type = "item", name = "electronic-circuit",   amount = 6  },
    },
    results = { { type = "item", name = "pe-compressor", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-heat-exchanger", enabled = false, energy_required = 6,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 12 },
      { type = "item", name = "pe-stainless-tube",    amount = 12 },
      { type = "item", name = "pipe",                 amount = 10 },
      { type = "item", name = "electronic-circuit",   amount = 5  },
    },
    results = { { type = "item", name = "pe-heat-exchanger", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-flash-separator", enabled = false, energy_required = 4,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 10 },
      { type = "item", name = "pipe",                 amount = 6  },
      { type = "item", name = "electronic-circuit",   amount = 4  },
    },
    results = { { type = "item", name = "pe-flash-separator", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-cracker", enabled = false, energy_required = 10,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 35 },
      { type = "item", name = "pe-refractory-brick",  amount = 15 },
      { type = "item", name = "pe-stainless-tube",    amount = 12 },
      { type = "item", name = "pipe",                 amount = 10 },
      { type = "item", name = "electronic-circuit",   amount = 10 },
    },
    results = { { type = "item", name = "pe-cracker", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-methanol-reactor", enabled = false, energy_required = 6,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 15 },
      { type = "item", name = "pe-pressure-vessel",   amount = 1  },
      { type = "item", name = "pipe",                 amount = 8  },
      { type = "item", name = "electronic-circuit",   amount = 8  },
    },
    results = { { type = "item", name = "pe-methanol-reactor", amount = 1 } },
  },

  {
    type = "recipe", name = "pe-psa-splitter", enabled = false, energy_required = 5,
    ingredients = {
      { type = "item", name = "steel-plate",          amount = 12 },
      { type = "item", name = "pipe",                 amount = 6  },
      { type = "item", name = "electronic-circuit",   amount = 6  },
    },
    results = { { type = "item", name = "pe-psa-splitter", amount = 1 } },
  },

})
