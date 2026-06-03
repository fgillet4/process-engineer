-- Recipe categories — one per unit operation type
-- Allows different machines to handle different operation classes

data:extend({
  { type = "recipe-category", name = "pe-reforming"       },  -- Steam methane reforming
  { type = "recipe-category", name = "pe-wgs"             },  -- Water-gas shift
  { type = "recipe-category", name = "pe-haber-bosch"     },  -- NH3 synthesis loop
  { type = "recipe-category", name = "pe-compression"     },  -- Gas compression
  { type = "recipe-category", name = "pe-heat-exchange"   },  -- Shell-and-tube HX
  { type = "recipe-category", name = "pe-flash"           },  -- Flash separator / VLE
  { type = "recipe-category", name = "pe-cracking"        },  -- Steam cracking
  { type = "recipe-category", name = "pe-methanol"        },  -- Methanol synthesis
  { type = "recipe-category", name = "pe-urea"            },  -- Urea synthesis
  { type = "recipe-category", name = "pe-syngas-split"    },  -- H2/CO separation (PSA)
})
