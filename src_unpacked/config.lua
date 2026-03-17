-- Configuration and Constants

local config = {}

-- Base Window Settings (reference size for scaling)
config.BASE_WINDOW_W = 1280
config.BASE_WINDOW_H = 720

-- Current Window Settings (updated on resize)
config.WINDOW_W = config.BASE_WINDOW_W
config.WINDOW_H = config.BASE_WINDOW_H

-- Scale factors (calculated based on current window size)
config.scaleX = 1.0
config.scaleY = 1.0
config.scale = 1.0  -- Uniform scale (use smaller of scaleX/scaleY to maintain aspect)

-- Grid Settings - Scaled dynamically
config.GRID_SIZE = 8
config.BASE_CELL_SIZE = 58  -- Base cell size for reference window
config.BASE_SPACING = 3  -- Base spacing for reference window

-- Function to update window dimensions and scale
function config.updateWindowSize(w, h)
    if w and h then
        config.WINDOW_W = w
        config.WINDOW_H = h
    else
        config.WINDOW_W, config.WINDOW_H = love.window.getMode()
    end
    
    -- Calculate scale factors - use independent scaling for better flexibility
    -- Clamp scale factors to prevent UI from becoming too small or too large
    config.scaleX = math.max(0.6, math.min(1.5, config.WINDOW_W / config.BASE_WINDOW_W))
    config.scaleY = math.max(0.6, math.min(1.5, config.WINDOW_H / config.BASE_WINDOW_H))
    -- Use average scale for UI elements to maintain proportions (also clamped)
    config.scale = math.max(0.6, math.min(1.5, (config.scaleX + config.scaleY) / 2))
    
    -- Update grid settings - use uniform scale for grid to maintain square cells
    local gridScale = math.min(config.scaleX, config.scaleY) * 0.9  -- Smaller to ensure fit with header
    config.CELL_SIZE = math.max(45, math.floor(config.BASE_CELL_SIZE * gridScale))
    config.SPACING = math.max(2, math.floor(config.BASE_SPACING * gridScale))
    config.BOARD_W = config.GRID_SIZE * (config.CELL_SIZE + config.SPACING) - config.SPACING
    config.GRID_START_X = (config.WINDOW_W - config.BOARD_W) / 2
    -- Position grid below header (score box + money + spacing)
    config.GRID_START_Y = math.floor(140 * config.scaleY)
    
    -- Update tray settings - ensure tray is below grid with proper spacing
    local gridHeight = config.GRID_SIZE * (config.CELL_SIZE + config.SPACING) - config.SPACING
    config.TRAY_Y = config.GRID_START_Y + gridHeight + math.floor(40 * config.scaleY)
    config.TRAY_SPACING = math.floor(220 * config.scaleX)
end

-- Initialize with base size
config.updateWindowSize(config.BASE_WINDOW_W, config.BASE_WINDOW_H)

-- Themes Definition
config.THEMES = {
    {
        id = "classic",
        name = "CLASSIC",
        price = 0,
        palette = {
            {235/255, 64/255,  52/255},  -- Red
            {230/255, 126/255, 34/255},  -- Orange
            {241/255, 196/255, 15/255},  -- Yellow
            {76/255,  217/255, 100/255}, -- Green
            {26/255,  188/255, 156/255}, -- Cyan
            {52/255,  152/255, 219/255}, -- Blue
            {155/255, 89/255,  182/255}  -- Purple
        },
        ui = {
            bgStart     = {25/255, 33/255, 62/255},
            bgEnd       = {15/255, 20/255, 40/255},
            boardBg     = {20/255, 30/255, 50/255},
            boardBorder = {60/255, 90/255, 150/255},
            cellEmpty   = {25/255, 33/255, 62/255},
            popupBg     = {40/255, 55/255, 90/255},
            popupBorder = {60/255, 80/255, 140/255},
            textMain    = {1, 1, 1},
            textShadow  = {0, 0, 0, 0.6},
            accent      = {255/255, 220/255, 0/255}
        }
    },
    {
        id = "neon",
        name = "NEON",
        price = 0,  -- FREE for testing
        palette = {
            {255/255, 0/255, 128/255},   -- Hot Pink
            {255/255, 165/255, 0/255},   -- Neon Orange
            {255/255, 255/255, 0/255},   -- Neon Yellow
            {57/255, 255/255, 20/255},   -- Neon Green
            {0/255, 255/255, 255/255},   -- Cyan
            {138/255, 43/255, 226/255},  -- Blue Violet
            {255/255, 20/255, 147/255}   -- Deep Pink
        },
        ui = {
            bgStart     = {5/255,  5/255,  10/255},
            bgEnd       = {0/255,  0/255,  0/255},
            boardBg     = {15/255, 15/255, 20/255},
            boardBorder = {255/255, 0/255, 128/255},
            cellEmpty   = {10/255, 10/255, 15/255},
            popupBg     = {20/255, 20/255, 25/255},
            popupBorder = {57/255, 255/255, 20/255},
            textMain    = {1, 1, 1},
            textShadow  = {1, 0, 1, 0.4},
            accent      = {0/255, 255/255, 255/255}
        }
    },
    {
        id = "pastel",
        name = "PASTEL",
        price = 0,  -- FREE for testing
        palette = {
            {255/255, 179/255, 186/255}, -- Pastel Red
            {255/255, 223/255, 186/255}, -- Pastel Orange
            {255/255, 255/255, 186/255}, -- Pastel Yellow
            {186/255, 255/255, 201/255}, -- Pastel Green
            {186/255, 225/255, 255/255}, -- Pastel Blue
            {212/255, 165/255, 255/255}, -- Pastel Purple
            {255/255, 204/255, 229/255}  -- Pastel Pink
        },
        ui = {
            bgStart     = {255/255, 245/255, 255/255},
            bgEnd       = {240/255, 250/255, 255/255},
            boardBg     = {255/255, 255/255, 255/255},
            boardBorder = {200/255, 200/255, 220/255},
            cellEmpty   = {245/255, 245/255, 245/255},
            popupBg     = {255/255, 255/255, 255/255},
            popupBorder = {220/255, 220/255, 230/255},
            textMain    = {80/255, 80/255, 90/255},
            textShadow  = {0, 0, 0, 0.1},
            accent      = {255/255, 150/255, 150/255}
        }
    },
    {
        id = "ocean",
        name = "OCEAN",
        price = 0,  -- FREE for testing
        palette = {
            {0/255, 105/255, 148/255},   -- Deep Cerulean
            {0/255, 168/255, 204/255},   -- Bright Cerulean
            {39/255, 175/255, 176/255},  -- Teal
            {117/255, 208/255, 192/255}, -- Seafoam Green
            {166/255, 226/255, 215/255}, -- Light Aqua
            {64/255, 224/255, 208/255},  -- Turquoise
            {0/255, 128/255, 128/255}    -- Dark Teal
        },
        ui = {
            bgStart     = {0/255,  60/255,  100/255},
            bgEnd       = {0/255,  20/255,  50/255},
            boardBg     = {0/255,  40/255,  80/255},
            boardBorder = {0/255, 168/255, 204/255},
            cellEmpty   = {0/255,  50/255,  90/255},
            popupBg     = {0/255,  45/255,  85/255},
            popupBorder = {39/255, 175/255, 176/255},
            textMain    = {230/255, 250/255, 255/255},
            textShadow  = {0, 0, 0, 0.8},
            accent      = {166/255, 226/255, 215/255}
        }
    }
}

-- Block Shapes
config.SHAPES = {
    {{1}}, {{1,1}}, {{1},{1}}, {{1,1,1}}, {{1},{1},{1}}, 
    {{1,1,1,1}}, {{1},{1},{1},{1}}, {{1,1,1,1,1}}, {{1},{1},{1},{1},{1}},
    {{1,1},{1,1}}, {{1,1,1},{1,1,1},{1,1,1}}, 
    {{1,0},{1,1}}, {{0,1},{1,1}}, {{1,1},{1,0}}, {{1,1},{0,1}},
    {{1,0,0},{1,0,0},{1,1,1}}, {{0,0,1},{0,0,1},{1,1,1}}, 
    {{1,1,1},{1,0,0},{1,0,0}}, {{1,1,1},{0,0,1},{0,0,1}},
    {{0,1,0},{1,1,1}}, {{1,0},{1,1},{1,0}}, {{1,1,1},{0,1,0}}, {{0,1},{1,1},{0,1}}
}

-- Ambient Texts
config.AMBIENT_TEXTS = {
    "RELAXING!", 
    "STRATEGIC!", 
    "ADDICTIVE!", 
    "EPIC!", 
    "INTENSE!", 
    "FUN!", 
    "CHALLENGING!", 
    "SMOOTH!", 
    "FAST!", 
    "MINDBLOWING!", 
    "AWESOME!", 
    "INSANE!", 
    "LEGENDARY!", 
    "PERFECT!", 
    "AMAZING!"
}

-- Hint System
config.HINT_COST_BASE = 75  -- Increased base cost (was 50) - tighter economy

-- Continue System
config.CONTINUE_COST_BASE = 150  -- Increased base cost (was 100) - tighter economy

-- Economy Scaling Functions
-- Higher score = more expensive costs, but also more earnings
function config.getHintCost(score, premiumItems)
    premiumItems = premiumItems or {}
    -- If unlimited hints is purchased, hints are free
    if premiumItems.unlimited_hints then
        return 0
    end
    -- Base cost scales with score: 75 + (score / 180)
    -- At score 0: $75, at score 1000: $80, at score 5000: $103, at score 10000: $130
    local scaledCost = config.HINT_COST_BASE + math.floor(score / 180)
    return math.max(config.HINT_COST_BASE, scaledCost)  -- Minimum is base cost
end

function config.getContinueCost(score, premiumItems)
    premiumItems = premiumItems or {}
    -- If unlimited lives is purchased, continue is free
    if premiumItems.unlimited_lives then
        return 0
    end
    -- Continue cost scales more aggressively: 150 + (score / 45)
    -- At score 0: $150, at score 1000: $172, at score 5000: $261, at score 10000: $372
    local scaledCost = config.CONTINUE_COST_BASE + math.floor(score / 45)
    return math.max(config.CONTINUE_COST_BASE, scaledCost)  -- Minimum is base cost
end

function config.getScoreMoneyMultiplier(score)
    -- Higher score = earn more money per line clear
    -- Base multiplier: 1.0, scales up to 1.8x at very high scores (reduced from 2.0x for tighter economy)
    -- Formula: 1.0 + (score / 12500), capped at 1.8x
    local multiplier = 1.0 + (score / 12500)
    return math.min(1.8, math.max(1.0, multiplier))  -- Clamp between 1.0 and 1.8
end

-- Upgrade Configuration
-- Economy is tighter - upgrades are more expensive and prices increase every 5 purchases
config.UPGRADES = {
    moneyMagnet = {
        name = "Money Magnet",
        icon = "happy",
        description = "+25% money per level",
        maxLevel = 5,
        baseCost = 350,  -- Increased base cost (harder to afford)
        costMultiplier = 1.4,  -- Each level costs 1.4x previous
        tierMultiplier = 1.3,  -- Every 5 purchases, multiply base cost by this
        effectPerLevel = 0.25   -- +25% per level
    },
    scoreBoost = {
        name = "Score Boost",
        icon = "robot",
        description = "+20% score per level",
        maxLevel = 5,
        baseCost = 400,  -- Increased base cost
        costMultiplier = 1.4,
        tierMultiplier = 1.3,
        effectPerLevel = 0.20
    },
    hintMaster = {
        name = "Hint Master",
        icon = "shocked",
        description = "+2s hint duration per level",
        maxLevel = 3,
        baseCost = 250,  -- Increased base cost
        costMultiplier = 1.6,
        tierMultiplier = 1.3,
        effectPerLevel = 2.0   -- +2 seconds per level
    },
    comboKing = {
        name = "Combo King",
        icon = "crazy",
        description = "+10% combo bonus per level",
        maxLevel = 4,
        baseCost = 450,  -- Increased base cost
        costMultiplier = 1.5,
        tierMultiplier = 1.3,
        effectPerLevel = 0.10
    },
    luckyStart = {
        name = "Lucky Start",
        icon = "pumkin",
        description = "+$50 starting money per level",
        maxLevel = 3,
        baseCost = 600,  -- Increased base cost (most expensive)
        costMultiplier = 1.8,
        tierMultiplier = 1.3,
        effectPerLevel = 50   -- +$50 per level
    },
    rowBlast = {
        name = "Row Blast",
        icon = "alien",
        description = "Clears bottom row instantly",
        maxLevel = 999,  -- Can be purchased multiple times (consumable)
        baseCost = 400,  -- Increased base cost
        costMultiplier = 1.15,  -- Each purchase costs 15% more
        tierMultiplier = 1.25,  -- Every 5 purchases, multiply base by this
        isGameplayUpgrade = true  -- Flag to indicate this triggers gameplay action
    },
    columnBlast = {
        name = "Column Blast",
        icon = "skull",
        description = "Clears random column instantly",
        maxLevel = 999,  -- Can be purchased multiple times (consumable)
        baseCost = 450,  -- Increased base cost
        costMultiplier = 1.15,
        tierMultiplier = 1.25,
        isGameplayUpgrade = true
    },
    colorWipe = {
        name = "Color Wipe",
        icon = "dead",
        description = "Clears all blocks of one color",
        maxLevel = 999,  -- Can be purchased multiple times (consumable)
        baseCost = 500,  -- Increased base cost (most powerful)
        costMultiplier = 1.15,
        tierMultiplier = 1.25,
        isGameplayUpgrade = true
    }
}

-- Theme Configuration (matching backup themes)
-- Themes are expensive and progressively more expensive - something to look forward to after hours of playing
config.THEMES_SHOP = {
    classic = {
        name = "Classic",
        icon = nil,  -- No icon for default theme
        cost = 0,  -- Always free
        description = "Standard colorful blocks"
    },
    neon = {
        name = "Neon",
        icon = nil,  -- No icon available
        cost = 500,  -- First premium theme - affordable after a few games
        description = "Bright neon colors",
        costMultiplier = 1.0  -- Base cost
    },
    pastel = {
        name = "Pastel",
        icon = nil,  -- No icon available
        cost = 1000,  -- More expensive - requires more playtime
        description = "Soft pastel colors",
        costMultiplier = 1.0  -- Base cost
    },
    ocean = {
        name = "Ocean",
        icon = nil,  -- No icon available
        cost = 2000,  -- Very expensive - late game reward
        description = "Ocean blue tones",
        costMultiplier = 1.0  -- Base cost
    }
}

-- Function to get theme cost (can scale with number of themes owned for future expansion)
function config.getThemeCost(themeId, premiumItems)
    premiumItems = premiumItems or {}
    -- If unlock everything is purchased, all themes are free
    if premiumItems.unlock_everything then
        return 0
    end
    local theme = config.THEMES_SHOP[themeId]
    if not theme then
        return 0
    end
    
    -- For now, return base cost
    -- In the future, could scale based on number of themes owned
    return theme.cost or 0
end

-- Helper function to get theme index from theme ID
function config.getThemeIndex(themeId)
    if type(themeId) == "number" then
        return themeId  -- Already a number
    end
    -- Find theme by ID string
    for i, theme in ipairs(config.THEMES) do
        if theme.id == themeId then
            return i
        end
    end
    return 1  -- Default to classic
end

-- Helper function to calculate upgrade cost at a given level
-- Implements tier-based pricing: every 5 purchases, the base cost increases
function config.getUpgradeCost(upgradeId, currentLevel, premiumItems)
    premiumItems = premiumItems or {}
    -- If unlock everything is purchased, all upgrades are free
    if premiumItems.unlock_everything then
        -- Still check if maxed out
        local upgrade = config.UPGRADES[upgradeId]
        if not upgrade then
            return nil  -- Invalid upgrade ID
        end
        currentLevel = currentLevel or 0
        if currentLevel < 0 then currentLevel = 0 end
        if currentLevel >= upgrade.maxLevel then
            return nil  -- Maxed out
        end
        return 0  -- Free if unlock everything is purchased
    end
    
    local upgrade = config.UPGRADES[upgradeId]
    if not upgrade then
        return nil  -- Invalid upgrade ID
    end
    
    -- Validate current level
    currentLevel = currentLevel or 0
    if currentLevel < 0 then currentLevel = 0 end
    if currentLevel >= upgrade.maxLevel then
        return nil  -- Maxed out
    end
    
    -- Calculate tier (every 5 purchases = new tier)
    local tier = math.floor(currentLevel / 5)
    local tierMultiplier = upgrade.tierMultiplier or 1.0
    
    -- Calculate base cost with tier multiplier applied
    local tieredBaseCost = upgrade.baseCost
    for t = 1, tier do
        tieredBaseCost = tieredBaseCost * tierMultiplier
    end
    
    -- For gameplay upgrades (consumable), cost increases with each purchase within tier
    if upgrade.isGameplayUpgrade then
        local cost = tieredBaseCost
        -- Each purchase within current tier increases cost by multiplier
        local purchasesInTier = currentLevel % 5
        for i = 1, purchasesInTier do
            cost = cost * upgrade.costMultiplier
        end
        return math.floor(cost)
    end
    
    -- For regular upgrades, apply cost multiplier within current tier
    local cost = tieredBaseCost
    local purchasesInTier = currentLevel % 5
    for i = 1, purchasesInTier do
        cost = cost * upgrade.costMultiplier
    end
    return math.floor(cost)
end

return config
