-- =============================================================================
-- Thermodynamic property library
-- All temperatures in Celsius unless otherwise noted (Factorio uses Celsius)
-- Enthalpies in kJ/mol, Cp in J/(mol·K)
-- =============================================================================

local thermo = {}

-- ---------------------------------------------------------------------------
-- Shomate equation Cp coefficients: Cp = A + B*t + C*t² + D*t³ + E/t²
-- where t = T(K) / 1000
-- Valid ranges noted per species
-- Source: NIST WebBook
-- ---------------------------------------------------------------------------
thermo.shomate = {
  -- H2: 298–1000 K
  hydrogen = { A=33.066178, B=-11.363417, C=11.432816, D=-2.772874, E=-0.158558, Hf=0.0 },
  -- O2: 700–2000 K
  oxygen   = { A=30.03235,  B=8.772972,  C=-3.988133, D=0.788313,  E=-0.741599, Hf=0.0 },
  -- N2: 298–6000 K
  nitrogen = { A=26.09200,  B=8.218801,  C=-1.976141, D=0.159274,  E=0.044434,  Hf=0.0 },
  -- CH4: 298–1300 K
  methane  = { A=-0.703029, B=108.4773,  C=-42.52157, D=5.862788,  E=0.678565,  Hf=-74.87 },
  -- CO: 298–1300 K
  co       = { A=25.56759,  B=6.096130,  C=4.054656,  D=-2.671301, E=0.131021,  Hf=-110.53 },
  -- CO2: 298–1200 K
  co2      = { A=24.99735,  B=55.18696,  C=-33.69137, D=7.948387,  E=-0.136638, Hf=-393.51 },
  -- H2O (gas): 500–1700 K
  steam    = { A=30.09200,  B=6.832514,  C=6.793435,  D=-2.534480, E=0.082139,  Hf=-241.83 },
  -- NH3: 298–1400 K
  ammonia  = { A=19.99563,  B=49.77119,  C=-15.37599, D=1.921168,  E=0.189174,  Hf=-45.90 },
  -- C2H4: 298–1200 K
  ethylene = { A=-6.387880, B=184.4019,  C=-112.9718, D=28.49593,  E=0.315540,  Hf=52.47 },
  -- C2H6: 298–1200 K
  ethane   = { A=-3.029849, B=199.2018,  C=-158.8387, D=53.67370,  E=0.085461,  Hf=-83.80 },
  -- CH3OH: 298–1500 K
  methanol = { A=14.19760,  B=168.7798,  C=-146.7254, D=59.36550,  E=0.026005,  Hf=-200.94 },
}

-- ---------------------------------------------------------------------------
-- Cp at temperature T (°C) for a given species [J/(mol·K)]
-- ---------------------------------------------------------------------------
function thermo.cp(species, T_celsius)
  local c = thermo.shomate[species]
  if not c then return nil end
  local t = (T_celsius + 273.15) / 1000.0
  return c.A + c.B*t + c.C*t^2 + c.D*t^3 + c.E/t^2
end

-- ---------------------------------------------------------------------------
-- Enthalpy change ΔH from T1 to T2 (°C) for one mole [kJ/mol]
-- Integrates Shomate equation numerically (10-point Gaussian quadrature)
-- ---------------------------------------------------------------------------
function thermo.delta_h(species, T1_celsius, T2_celsius)
  local c = thermo.shomate[species]
  if not c then return nil end
  -- Gauss-Legendre points and weights for [-1,1] (10-point)
  local xi = {-0.9739065, -0.8650634, -0.6794096, -0.4333954, -0.1488743,
               0.1488743,  0.4333954,  0.6794096,  0.8650634,  0.9739065}
  local wi = { 0.0666713,  0.1494513,  0.2190864,  0.2692667,  0.2955242,
               0.2955242,  0.2692667,  0.2190864,  0.1494513,  0.0666713}
  local Ta, Tb = T1_celsius + 273.15, T2_celsius + 273.15
  local sum = 0
  for i = 1, 10 do
    local T = 0.5*(Tb - Ta)*xi[i] + 0.5*(Tb + Ta)  -- K
    local t = T / 1000.0
    local cp = c.A + c.B*t + c.C*t^2 + c.D*t^3 + c.E/t^2  -- J/(mol·K)
    sum = sum + wi[i] * cp
  end
  return sum * 0.5 * (Tb - Ta) / 1000.0  -- kJ/mol
end

-- ---------------------------------------------------------------------------
-- Standard reaction enthalpy ΔH°rxn at 298°C from heats of formation [kJ/mol]
-- products and reactants: { {species, stoich_coeff}, ... }
-- ---------------------------------------------------------------------------
function thermo.delta_h_rxn(products, reactants)
  local dH = 0
  for _, p in ipairs(products)  do dH = dH + p[2] * thermo.shomate[p[1]].Hf end
  for _, r in ipairs(reactants) do dH = dH - r[2] * thermo.shomate[r[1]].Hf end
  return dH
end

-- ---------------------------------------------------------------------------
-- Antoine equation vapor pressure [bar]
-- log10(P) = A - B/(C+T)  where T in °C
-- ---------------------------------------------------------------------------
thermo.antoine = {
  methanol = { A=8.08097, B=1582.271, C=239.726 },  -- 15–84 °C
  water    = { A=8.07131, B=1730.630, C=233.426 },  -- 60–150 °C
  ammonia  = { A=7.36050, B=926.132,  C=240.170 },  -- -83 to +60 °C
  ethylene = { A=6.74756, B=585.000,  C=255.000 },  -- cryogenic
}

function thermo.vapor_pressure(species, T_celsius)
  local a = thermo.antoine[species]
  if not a then return nil end
  return 10^(a.A - a.B / (a.C + T_celsius))  -- bar
end

-- ---------------------------------------------------------------------------
-- Equilibrium constants K_eq(T) for key reactions
-- ln(K) = -ΔG°/RT  approximated with van't Hoff: d(lnK)/dT = ΔH/(RT²)
-- Using tabulated K values fit to Arrhenius-style expression K = A*exp(-Ea/RT)
-- ---------------------------------------------------------------------------
thermo.keq = {
  -- SMR: CH4 + H2O ⇌ CO + 3H2   highly endothermic, K increases with T
  smr = function(T_celsius)
    local T = T_celsius + 273.15
    return math.exp(-26830/T + 30.114)  -- dimensionless (bar² basis)
  end,
  -- WGS: CO + H2O ⇌ CO2 + H2   exothermic, K decreases with T
  wgs = function(T_celsius)
    local T = T_celsius + 273.15
    return math.exp(4577.8/T - 4.33)
  end,
  -- Haber-Bosch: N2 + 3H2 ⇌ 2NH3   exothermic, K decreases with T
  haber_bosch = function(T_celsius)
    local T = T_celsius + 273.15
    return math.exp(-10.938 + 10171/T)  -- units: bar^-2
  end,
  -- Methanol: CO + 2H2 ⇌ CH3OH   exothermic
  methanol_synth = function(T_celsius)
    local T = T_celsius + 273.15
    return math.exp(-12.621 + 5765/T)
  end,
}

-- ---------------------------------------------------------------------------
-- Equilibrium conversion for a given K and feed (simplified single-pass)
-- Returns fractional conversion (0–1) of limiting reactant
-- Uses simplified analytical or Newton's method approach
-- ---------------------------------------------------------------------------

-- WGS: CO + H2O → CO2 + H2  (equimolar, easiest case)
-- K = x_CO2 * x_H2 / (x_CO * x_H2O)  (pressure cancels)
-- x = equilibrium conversion of CO, feed: 1 mol CO, 1 mol H2O
function thermo.wgs_conversion(T_celsius)
  local K = thermo.keq.wgs(T_celsius)
  -- solving: K*(1-x)^2 = x^2  → x = sqrt(K)/(1+sqrt(K))
  local sqrtK = math.sqrt(math.max(K, 0))
  return sqrtK / (1 + sqrtK)
end

-- SMR: CH4 + H2O → CO + 3H2  (steam:methane = 3:1 typical)
-- Simplified - returns thermodynamic feasibility metric (0=no rxn, 1=complete)
function thermo.smr_extent(T_celsius, P_bar)
  P_bar = P_bar or 25
  local K = thermo.keq.smr(T_celsius)
  -- K in bar² units, reaction produces 3 mol gas per mol methane
  -- simplified approach: K >> P² means high conversion
  local driving = K / (P_bar^2)
  return math.min(1.0, math.max(0.0, driving / (1 + driving)))
end

return thermo
