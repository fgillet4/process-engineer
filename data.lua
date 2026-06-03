-- =============================================================================
-- Process Engineer — main data stage loader
-- Load order matters: categories → fluids → items → entities → recipes → tech
-- =============================================================================

require("prototypes/recipe-categories")
require("prototypes/fluids")
require("prototypes/items")
require("prototypes/entities")
require("prototypes/recipes")
require("prototypes/technologies")
