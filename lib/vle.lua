-- =============================================================================
-- Vapour-Liquid Equilibrium (VLE) library
-- Implements Raoult's Law + Modified Raoult's Law (with activity coefficients)
-- and Peng-Robinson EOS for high-pressure systems (Haber-Bosch, methanol loop)
--
-- All temperatures in Celsius, pressures in bar, compositions in mole fractions
-- =============================================================================

local thermo = require("lib/thermodynamics")
local vle = {}

-- ---------------------------------------------------------------------------
-- Antoine coefficients (log10 basis, P in mmHg, T in °C)
-- Converted to bar internally
-- ---------------------------------------------------------------------------
local antoine = {
  --             A        B        C      T_min  T_max (°C)
  methane  = { 6.61184, 389.93,  266.00, -182,  -82  },
  ethane   = { 6.80896, 656.40,  256.00, -119,  -89  },
  ethylene = { 6.74756, 585.00,  255.00, -169, -100  },
  propane  = { 6.82973, 813.20,  248.00,  -87,  -42  },
  methanol = { 8.08097, 1582.27, 239.73,   15,   84  },
  water    = { 8.07131, 1730.63, 233.43,   60,  150  },
  ammonia  = { 7.36050,  926.13, 240.17,  -83,   60  },
  co2      = { 6.81228,  531.15, 270.40, -100,   20  },  -- sublimation region, approx
  hydrogen = { 5.82600,   93.98, 274.76, -259, -240  },  -- cryogenic only
  nitrogen = { 6.49457,  255.68, 266.55, -210, -148  },  -- cryogenic only
}

-- Returns vapor pressure in bar
function vle.p_sat(species, T_celsius)
  local a = antoine[species]
  if not a then return nil end
  -- mmHg → bar: 1 mmHg = 0.00133322 bar
  local log_p_mmhg = a[1] - a[2] / (a[3] + T_celsius)
  return (10^log_p_mmhg) * 0.00133322
end

-- ---------------------------------------------------------------------------
-- Raoult's Law: ideal VLE  P_i = x_i * P_sat_i
-- K_i = y_i/x_i = P_sat_i / P
-- Input:  species list, T (°C), P (bar)
-- Output: K-values table (Ki for each species)
-- ---------------------------------------------------------------------------
function vle.k_raoult(species_list, T_celsius, P_bar)
  local K = {}
  for _, sp in ipairs(species_list) do
    local psat = vle.p_sat(sp, T_celsius)
    if psat then
      K[sp] = psat / P_bar
    else
      K[sp] = nil  -- supercritical or outside range
    end
  end
  return K
end

-- ---------------------------------------------------------------------------
-- Rachford-Rice flash calculation
-- Finds vapour fraction V (0–1) and phase compositions (x, y)
-- Feed:     z  = {species → mole_fraction}
-- K-values: K  = {species → Ki}
-- Returns:  { V=vapour_fraction, x=liquid_mole_fracs, y=vapour_mole_fracs }
--           or nil if feed is all-liquid or all-vapour
-- ---------------------------------------------------------------------------
function vle.rachford_rice_flash(z, K)
  local species = {}
  for sp, _ in pairs(z) do table.insert(species, sp) end

  -- Check trivial cases: if all K > 1 → all vapour; all K < 1 → all liquid
  local all_vapour, all_liquid = true, true
  for _, sp in ipairs(species) do
    if K[sp] and K[sp] < 1 then all_vapour = false end
    if K[sp] and K[sp] > 1 then all_liquid = false end
  end
  if all_vapour then return { V=1.0, x=z, y=z } end
  if all_liquid then return { V=0.0, x=z, y=z } end

  -- Rachford-Rice function: sum[ z_i*(K_i - 1) / (1 + V*(K_i - 1)) ] = 0
  local function rr(V)
    local s = 0
    for _, sp in ipairs(species) do
      if K[sp] then
        local ki = K[sp]
        s = s + z[sp] * (ki - 1) / (1 + V * (ki - 1))
      end
    end
    return s
  end

  -- Bisection to solve for V in [0, 1]
  local V_lo, V_hi = 0.0, 1.0
  -- Bracket bounds more tightly to avoid singularities
  local Kmin, Kmax = math.huge, -math.huge
  for _, sp in ipairs(species) do
    if K[sp] then
      Kmin = math.min(Kmin, K[sp])
      Kmax = math.max(Kmax, K[sp])
    end
  end
  V_lo = math.max(0.0, 1/(1 - Kmax) + 1e-8)
  V_hi = math.min(1.0, 1/(1 - Kmin) - 1e-8)
  if V_lo >= V_hi then V_lo, V_hi = 0.0, 1.0 end

  local V = 0.5
  for _ = 1, 50 do  -- bisection iterations
    local f_mid = rr(V)
    if math.abs(f_mid) < 1e-10 then break end
    if rr(V_lo) * f_mid < 0 then
      V_hi = V
    else
      V_lo = V
    end
    V = 0.5 * (V_lo + V_hi)
  end
  V = math.max(0.0, math.min(1.0, V))

  -- Compute phase compositions
  local x, y = {}, {}
  local sum_x, sum_y = 0, 0
  for _, sp in ipairs(species) do
    if K[sp] then
      local xi = z[sp] / (1 + V * (K[sp] - 1))
      local yi = K[sp] * xi
      x[sp] = xi
      y[sp] = yi
      sum_x = sum_x + xi
      sum_y = sum_y + yi
    end
  end
  -- Normalise
  for _, sp in ipairs(species) do
    if x[sp] then
      x[sp] = x[sp] / sum_x
      y[sp] = y[sp] / sum_y
    end
  end

  return { V = V, x = x, y = y }
end

-- ---------------------------------------------------------------------------
-- Peng-Robinson EOS — for high-pressure systems
-- Returns compressibility factor Z and fugacity coefficients phi
-- PR: P = RT/(V-b) - a(T)/(V(V+b) + b(V-b))
-- ---------------------------------------------------------------------------

-- Critical properties table: { Tc(K), Pc(bar), omega }
local pr_props = {
  hydrogen  = { Tc=33.19,   Pc=13.13,  omega=−0.219 },
  nitrogen  = { Tc=126.19,  Pc=33.96,  omega=0.037  },
  methane   = { Tc=190.56,  Pc=45.99,  omega=0.011  },
  co        = { Tc=132.92,  Pc=34.53,  omega=0.048  },
  co2       = { Tc=304.13,  Pc=73.77,  omega=0.225  },
  ammonia   = { Tc=405.56,  Pc=113.59, omega=0.253  },
  methanol  = { Tc=512.64,  Pc=80.97,  omega=0.565  },
  water     = { Tc=647.10,  Pc=220.64, omega=0.345  },
  ethane    = { Tc=305.32,  Pc=48.72,  omega=0.100  },
  ethylene  = { Tc=282.34,  Pc=50.41,  omega=0.087  },
}

local R = 83.14  -- cm³·bar/(mol·K)

-- PR alpha function (Soave modification)
local function pr_alpha(T_K, Tc, omega)
  local kappa = 0.37464 + 1.54226*omega - 0.26992*omega^2
  local Tr = T_K / Tc
  return (1 + kappa * (1 - math.sqrt(Tr)))^2
end

-- PR a and b parameters for pure component
local function pr_ab(species, T_K)
  local p = pr_props[species]
  if not p then return nil, nil end
  local Tc, Pc, omega = p.Tc, p.Pc, p.omega
  local a0 = 0.45724 * R^2 * Tc^2 / Pc
  local b  = 0.07780 * R * Tc / Pc
  local alpha = pr_alpha(T_K, Tc, omega)
  return a0 * alpha, b
end

-- Solve cubic PR EOS: Z³ - (1-B)Z² + (A-3B²-2B)Z - (AB-B²-B³) = 0
-- Returns all real roots (there can be 1 or 3)
local function solve_cubic_pr(A, B)
  -- Coefficients: Z³ + p*Z² + q*Z + r = 0
  local p = -(1 - B)
  local q = A - 3*B^2 - 2*B
  local r = -(A*B - B^2 - B^3)
  -- Cardano / trigonometric solution
  local p3 = p/3
  local Q = p3^2 - q/3
  local R_ = p3^3 - p3*q/2 + r/2
  local D = Q^3 - R_^2

  if D >= 0 then
    -- Three real roots
    local theta = math.acos(R_ / math.sqrt(Q^3))
    local sqQ = math.sqrt(Q)
    local z1 = -2*sqQ*math.cos(theta/3) - p3
    local z2 = -2*sqQ*math.cos((theta + 2*math.pi)/3) - p3
    local z3 = -2*sqQ*math.cos((theta + 4*math.pi)/3) - p3
    return {z1, z2, z3}
  else
    -- One real root
    local S = R_ + math.sqrt(R_^2 - Q^3)
    S = (S >= 0) and S^(1/3) or -((-S)^(1/3))
    local T_ = R_ - math.sqrt(R_^2 - Q^3)
    T_ = (T_ >= 0) and T_^(1/3) or -((-T_)^(1/3))
    local z = S + T_ - p3
    return {z}
  end
end

-- Fugacity coefficient for pure component from PR EOS
function vle.pr_fugacity_coeff(species, T_celsius, P_bar, phase)
  -- phase: "vapor" or "liquid"
  local T_K = T_celsius + 273.15
  local a, b = pr_ab(species, T_K)
  if not a then return 1.0 end  -- assume ideal if no data

  local A = a * P_bar / (R * T_K)^2
  local B = b * P_bar / (R * T_K)

  local roots = solve_cubic_pr(A, B)
  -- Filter physically meaningful roots (Z > B)
  local valid = {}
  for _, z in ipairs(roots) do
    if z > B then table.insert(valid, z) end
  end
  if #valid == 0 then return 1.0 end

  -- Choose root: largest Z for vapor, smallest Z for liquid
  table.sort(valid)
  local Z = (phase == "liquid") and valid[1] or valid[#valid]

  -- ln(phi) = Z - 1 - ln(Z-B) - A/(2√2*B) * ln[(Z+(1+√2)B)/(Z+(1-√2)B)]
  local sqrt2 = math.sqrt(2)
  local ln_phi = (Z - 1)
                 - math.log(Z - B)
                 - A / (2 * sqrt2 * B)
                   * math.log((Z + (1 + sqrt2)*B) / (Z + (1 - sqrt2)*B))

  return math.exp(ln_phi)
end

-- K-value from PR EOS: K_i = phi_i_liquid / phi_i_vapor
function vle.k_pr(species_list, T_celsius, P_bar)
  local K = {}
  for _, sp in ipairs(species_list) do
    local phi_l = vle.pr_fugacity_coeff(sp, T_celsius, P_bar, "liquid")
    local phi_v = vle.pr_fugacity_coeff(sp, T_celsius, P_bar, "vapor")
    if phi_v and phi_v > 0 then
      K[sp] = phi_l / phi_v
    else
      K[sp] = 1.0
    end
  end
  return K
end

-- ---------------------------------------------------------------------------
-- High-level flash: auto-selects Raoult (low P) or PR (high P > 10 bar)
-- ---------------------------------------------------------------------------
function vle.flash(z, T_celsius, P_bar)
  local species_list = {}
  for sp, _ in pairs(z) do table.insert(species_list, sp) end

  local K
  if P_bar > 10 then
    K = vle.k_pr(species_list, T_celsius, P_bar)
  else
    K = vle.k_raoult(species_list, T_celsius, P_bar)
    -- Fall back to PR for any species without Antoine data
    for _, sp in ipairs(species_list) do
      if not K[sp] then
        local phi_l = vle.pr_fugacity_coeff(sp, T_celsius, P_bar, "liquid")
        local phi_v = vle.pr_fugacity_coeff(sp, T_celsius, P_bar, "vapor")
        K[sp] = (phi_v and phi_v > 0) and phi_l/phi_v or 1.0
      end
    end
  end

  return vle.rachford_rice_flash(z, K), K
end

-- ---------------------------------------------------------------------------
-- Bubble point temperature search (binary): finds T at which first bubble forms
-- at given P and liquid composition z
-- ---------------------------------------------------------------------------
function vle.bubble_point_T(z, P_bar, T_guess_celsius)
  T_guess_celsius = T_guess_celsius or 100
  local species_list = {}
  for sp, _ in pairs(z) do table.insert(species_list, sp) end

  -- Bubble condition: sum(Ki * xi) = 1
  local function residual(T)
    local K = (P_bar > 10) and vle.k_pr(species_list, T, P_bar)
                             or vle.k_raoult(species_list, T, P_bar)
    local s = 0
    for sp, xi in pairs(z) do
      s = s + (K[sp] or 1.0) * xi
    end
    return s - 1.0
  end

  -- Bracket and bisect
  local T_lo, T_hi = T_guess_celsius - 100, T_guess_celsius + 200
  for _ = 1, 60 do
    local T_mid = 0.5*(T_lo + T_hi)
    if residual(T_lo) * residual(T_mid) < 0 then
      T_hi = T_mid
    else
      T_lo = T_mid
    end
    if math.abs(T_hi - T_lo) < 0.05 then break end
  end
  return 0.5*(T_lo + T_hi)
end

-- ---------------------------------------------------------------------------
-- Dew point temperature search: finds T at which first droplet condenses
-- ---------------------------------------------------------------------------
function vle.dew_point_T(z, P_bar, T_guess_celsius)
  T_guess_celsius = T_guess_celsius or 100
  local species_list = {}
  for sp, _ in pairs(z) do table.insert(species_list, sp) end

  -- Dew condition: sum(zi / Ki) = 1
  local function residual(T)
    local K = (P_bar > 10) and vle.k_pr(species_list, T, P_bar)
                             or vle.k_raoult(species_list, T, P_bar)
    local s = 0
    for sp, yi in pairs(z) do
      local ki = K[sp] or 1.0
      s = s + yi / math.max(ki, 1e-9)
    end
    return s - 1.0
  end

  local T_lo, T_hi = T_guess_celsius - 200, T_guess_celsius + 100
  for _ = 1, 60 do
    local T_mid = 0.5*(T_lo + T_hi)
    if residual(T_lo) * residual(T_mid) < 0 then
      T_hi = T_mid
    else
      T_lo = T_mid
    end
    if math.abs(T_hi - T_lo) < 0.05 then break end
  end
  return 0.5*(T_lo + T_hi)
end

return vle
