-- Game State Management

local gameState = {}
local config = require("config")

-- State Variables
gameState.grid = {}
gameState.tray = {}
gameState.dragging = nil
gameState.score = 0
gameState.displayScore = 0
gameState.highScore = 0
gameState.combo = 0
gameState.state = "PLAYING" -- PLAYING, GAMEOVER, SETTINGS
gameState.shaderTime = 0
gameState.playTime = 0
gameState.fonts = {}
gameState.screenShake = 0
gameState.predictedClears = { rows = {}, cols = {} }
gameState.ambientIndex = 1
gameState.stateTransition = 0 -- 0-1 for smooth state transitions
gameState.previousState = "PLAYING"
gameState.gearRotation = 0
gameState.gearHover = false
gameState.money = 100  -- Starting money
gameState.displayMoney = 100
gameState.hintPosition = nil  -- {x, y, pieceIndex} when hint is active
gameState.hintTimer = 0  -- How long hint is visible
gameState.hintButtonHover = false
gameState.showHintDialog = false  -- Show hint confirmation dialog
    gameState.shopButtonHover = false
    gameState.showShopDialog = false  -- Show shop dialog
    gameState.shopScrollOffset = 0  -- Scroll offset for shop dialog
    gameState.shopPage = 1  -- Shop page (1 = upgrades/themes, 2 = gameplay upgrades)
    gameState.showResetDialog = false -- Show reset confirmation dialog

-- Upgrades and Themes
gameState.upgrades = {
    moneyMagnet = 0,  -- Level 0-5 (+25% per level)
    scoreBoost = 0,   -- Level 0-5 (+20% per level)
    hintMaster = 0,   -- Level 0-3 (+2s per level)
    comboKing = 0,    -- Level 0-4 (+10% per level)
    luckyStart = 0,   -- Level 0-3 (+$50 per level)
    rowBlast = 0,     -- Level 0-1 (gameplay upgrade)
    columnBlast = 0,  -- Level 0-1 (gameplay upgrade)
    colorWipe = 0     -- Level 0-1 (gameplay upgrade)
}
gameState.themes = {
    classic = true,   -- Always owned
    neon = false,
    pastel = false,
    ocean = false
}
gameState.activeTheme = "classic"
gameState.currentTheme = 1  -- Numeric index for backward compatibility (synced with activeTheme)

-- Premium items tracking
gameState.premiumItems = {
    unlimited_lives = false,
    unlimited_hints = false,
    unlock_everything = false
}

-- Auto-save system
gameState.autoSaveTimer = 0
gameState.autoSaveInterval = 5.0  -- Auto-save every 5 seconds
gameState.pendingSave = false  -- Flag to indicate if save is needed
gameState.isResetting = false  -- Flag to prevent auto-save during reset

function gameState.init()
    gameState.grid = {}
    for y = 1, config.GRID_SIZE do
        gameState.grid[y] = {}
        for x = 1, config.GRID_SIZE do 
            gameState.grid[y][x] = { active = false, colorIdx = 0 } 
        end
    end
    gameState.score = 0
    gameState.displayScore = 0
    gameState.combo = 0
    gameState.state = "PLAYING"
    gameState.screenShake = 0
    gameState.predictedClears = { rows = {}, cols = {} }
    gameState.dragging = nil
    gameState.hintPosition = nil
    gameState.hintTimer = 0
    gameState.showShopDialog = false
    gameState.shopPage = 1  -- Reset to page 1
    gameState.showResetDialog = false
end

function gameState.loadFonts()
    -- Load the custom font from font folder
    local fontPath = "font/EvilEmpire-lx5R0.ttf"
    
    if love.filesystem.getInfo(fontPath) then
        -- Load custom font with different sizes
        gameState.fonts.huge = love.graphics.newFont(fontPath, 64)
        gameState.fonts.large = love.graphics.newFont(fontPath, 48)
        gameState.fonts.medium = love.graphics.newFont(fontPath, 36)
        gameState.fonts.small = love.graphics.newFont(fontPath, 24)
        gameState.fonts.tiny = love.graphics.newFont(fontPath, 18)
    else
        -- Fallback to default font if custom font not found
        gameState.fonts.huge = love.graphics.setNewFont(64)
        gameState.fonts.large = love.graphics.setNewFont(48)
        gameState.fonts.medium = love.graphics.setNewFont(36)
        gameState.fonts.small = love.graphics.setNewFont(24)
        gameState.fonts.tiny = love.graphics.setNewFont(18)
    end
    
    -- Set bold/outline effect by using multiple renders
    gameState.fonts.bold = true
end

function gameState.loadHighScore()
    if love.filesystem.getInfo("block_highscore.txt") then
        local content = love.filesystem.read("block_highscore.txt")
        -- Extract just the number (ignore cache buster comments)
        local scoreValue = tonumber(content:match("^(%d+)")) or 0
        gameState.highScore = scoreValue
    else
        gameState.highScore = 0  -- Reset to 0 if file doesn't exist
    end
end

function gameState.loadMoney()
    if love.filesystem.getInfo("block_money.txt") then
        local content = love.filesystem.read("block_money.txt")
        -- Extract just the number (ignore cache buster comments)
        local moneyValue = tonumber(content:match("^(%d+)")) or 100
        gameState.money = math.max(0, moneyValue)  -- Prevent negative money
        gameState.displayMoney = gameState.money
    else
        gameState.money = 100
        gameState.displayMoney = 100
    end
end

function gameState.saveMoney(skipPendingFlag)
    love.filesystem.write("block_money.txt", tostring(gameState.money))
    if not skipPendingFlag then
        gameState.pendingSave = true  -- Mark for auto-save
    end
end

function gameState.loadUpgrades()
    -- CRITICAL: Initialize all upgrades to defaults FIRST
    -- This ensures missing keys in the file result in 0, not old values
    gameState.upgrades = {
        moneyMagnet = 0,
        scoreBoost = 0,
        hintMaster = 0,
        comboKing = 0,
        luckyStart = 0,
        rowBlast = 0,
        columnBlast = 0,
        colorWipe = 0
    }
    gameState.themes = {
        classic = true,
        neon = false,
        pastel = false,
        ocean = false
    }
    gameState.activeTheme = "classic"
    gameState.premiumItems = {
        unlimited_lives = false,
        unlimited_hints = false,
        unlock_everything = false
    }
    
    if love.filesystem.getInfo("block_upgrades.txt") then
        local data = love.filesystem.read("block_upgrades.txt")
        if data then
            -- Parse key=value format
            for line in data:gmatch("[^\r\n]+") do
                local key, value = line:match("([^=]+)=(.+)")
                if key and value then
                    key = key:match("^%s*(.-)%s*$")  -- Trim whitespace
                    value = value:match("^%s*(.-)%s*$")  -- Trim whitespace
                    
                    if key == "moneyMagnet" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.moneyMagnet = math.max(0, math.min(level, 5))  -- Clamp to 0-5
                    elseif key == "scoreBoost" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.scoreBoost = math.max(0, math.min(level, 5))  -- Clamp to 0-5
                    elseif key == "hintMaster" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.hintMaster = math.max(0, math.min(level, 3))  -- Clamp to 0-3
                    elseif key == "comboKing" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.comboKing = math.max(0, math.min(level, 4))  -- Clamp to 0-4
                    elseif key == "luckyStart" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.luckyStart = math.max(0, math.min(level, 3))  -- Clamp to 0-3
                    elseif key == "rowBlast" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.rowBlast = math.max(0, math.min(level, 999))  -- No max for consumables
                    elseif key == "columnBlast" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.columnBlast = math.max(0, math.min(level, 999))  -- No max for consumables
                    elseif key == "colorWipe" then
                        local level = tonumber(value) or 0
                        gameState.upgrades.colorWipe = math.max(0, math.min(level, 999))  -- No max for consumables
                    elseif key == "theme_neon" then
                        gameState.themes.neon = (value == "true")
                    elseif key == "theme_pastel" then
                        gameState.themes.pastel = (value == "true")
                    elseif key == "theme_ocean" then
                        gameState.themes.ocean = (value == "true")
                    elseif key == "activeTheme" then
                        -- Validate theme ID
                        if config.THEMES_SHOP[value] then
                            gameState.activeTheme = value
                        else
                            gameState.activeTheme = "classic"  -- Fallback to classic
                        end
                    elseif key == "premium_unlimited_lives" then
                        gameState.premiumItems.unlimited_lives = (value == "true")
                    elseif key == "premium_unlimited_hints" then
                        gameState.premiumItems.unlimited_hints = (value == "true")
                    elseif key == "premium_unlock_everything" then
                        gameState.premiumItems.unlock_everything = (value == "true")
                    end
                end
            end
        end
    end
    -- Note: If file doesn't exist, we already initialized to defaults above
    -- Ensure classic theme is always owned
    gameState.themes.classic = true
    -- Ensure activeTheme is valid
    if not config.THEMES_SHOP[gameState.activeTheme] then
        gameState.activeTheme = "classic"
    end
    -- Check for web redeem flags passed as command-line arguments (from index.html)
    if type(arg) == "table" then
        local changed = false
        for _, v in ipairs(arg) do
            if v == "--ul" then
                gameState.premiumItems.unlimited_lives = true
                changed = true
            elseif v == "--uh" then
                gameState.premiumItems.unlimited_hints = true
                changed = true
            elseif v == "--ua" then
                gameState.premiumItems.unlock_everything = true
                changed = true
            end
        end
        if changed then
            -- Persist the unlocks so they stay after reload
            gameState.saveUpgrades(true)
        end
    end

    -- If unlock_everything is active (from purchase or redeem), max out permanent upgrades
    -- but keep gameplay consumables (rowBlast/columnBlast/colorWipe) as repeatable purchases.
    if gameState.premiumItems.unlock_everything then
        for id, upgrade in pairs(config.UPGRADES) do
            if upgrade.isGameplayUpgrade then
                -- Leave consumable gameplay upgrades at their current count
                -- cost will be forced to $0 by config.getUpgradeCost when unlock_everything is true
                gameState.upgrades[id] = gameState.upgrades[id] or 0
            else
                gameState.upgrades[id] = upgrade.maxLevel or gameState.upgrades[id] or 0
            end
        end
        -- Unlock all themes
        for themeId, _ in pairs(config.THEMES_SHOP) do
            gameState.themes[themeId] = true
        end
        gameState.activeTheme = "classic"
    end

    -- Sync currentTheme (numeric index) with activeTheme (string ID)
    gameState.currentTheme = config.getThemeIndex(gameState.activeTheme)
end

function gameState.saveUpgrades(skipPendingFlag)
    local lines = {}
    table.insert(lines, "moneyMagnet=" .. gameState.upgrades.moneyMagnet)
    table.insert(lines, "scoreBoost=" .. gameState.upgrades.scoreBoost)
    table.insert(lines, "hintMaster=" .. gameState.upgrades.hintMaster)
    table.insert(lines, "comboKing=" .. gameState.upgrades.comboKing)
    table.insert(lines, "luckyStart=" .. gameState.upgrades.luckyStart)
    table.insert(lines, "rowBlast=" .. gameState.upgrades.rowBlast)
    table.insert(lines, "columnBlast=" .. gameState.upgrades.columnBlast)
    table.insert(lines, "colorWipe=" .. gameState.upgrades.colorWipe)
    table.insert(lines, "theme_neon=" .. tostring(gameState.themes.neon))
    table.insert(lines, "theme_pastel=" .. tostring(gameState.themes.pastel))
    table.insert(lines, "theme_ocean=" .. tostring(gameState.themes.ocean))
    table.insert(lines, "activeTheme=" .. gameState.activeTheme)
    table.insert(lines, "premium_unlimited_lives=" .. tostring(gameState.premiumItems.unlimited_lives))
    table.insert(lines, "premium_unlimited_hints=" .. tostring(gameState.premiumItems.unlimited_hints))
    table.insert(lines, "premium_unlock_everything=" .. tostring(gameState.premiumItems.unlock_everything))
    
    love.filesystem.write("block_upgrades.txt", table.concat(lines, "\n"))
    if not skipPendingFlag then
        gameState.pendingSave = true  -- Mark for auto-save
    end
end

function gameState.getStartingMoney()
    -- Base starting money + lucky start bonus
    local baseMoney = 100
    local bonus = gameState.upgrades.luckyStart * 50
    return baseMoney + bonus
end

function gameState.saveHighScore(skipPendingFlag)
    -- Always save high score (even if it's 0 or lower than current)
    -- This allows reset to work properly
    love.filesystem.write("block_highscore.txt", tostring(gameState.highScore))
    if not skipPendingFlag then
        gameState.pendingSave = true  -- Mark for auto-save
    end
    -- Return true if this was a new high score
    return gameState.score > (gameState.highScore or 0)
end

-- Auto-save function that saves ALL persistent data
function gameState.autoSave()
    -- Save all persistent data (skip pending flag to avoid loop)
    gameState.saveMoney(true)
    gameState.saveUpgrades(true)
    gameState.saveHighScore(true)
    
    -- Save audio settings
    local audio = require("audio")
    audio.saveSettings()
    
    gameState.pendingSave = false
end

-- Update auto-save timer (call this from love.update)
function gameState.updateAutoSave(dt)
    -- Don't auto-save if we're in the middle of a reset
    if gameState.isResetting then
        return
    end
    
    gameState.autoSaveTimer = gameState.autoSaveTimer + dt
    
    -- Auto-save periodically or if there's a pending save
    if gameState.autoSaveTimer >= gameState.autoSaveInterval or gameState.pendingSave then
        gameState.autoSave()
        gameState.autoSaveTimer = 0
    end
end

-- Mark that a save is needed (call after any state change)
function gameState.markForSave()
    gameState.pendingSave = true
end

return gameState
