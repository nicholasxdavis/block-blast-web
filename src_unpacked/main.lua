-- Block Blast! Clone - The Ultimate Edition
-- Complete with Procedural Synth Audio, Lasers, Shaders, and Settings UI
-- Refactored into modular components

local config = require("config")
local audio = require("audio")
local graphics = require("graphics")
local gameState = require("game_state")
local gameLogic = require("game_logic")
local effects = require("effects")
local input = require("input")
local render = require("render")
local utils = require("utils")
local ui = require("ui")

function love.load()
    love.window.setMode(config.BASE_WINDOW_W, config.BASE_WINDOW_H, {resizable = true, highdpi = true, minwidth = 800, minheight = 600})
    love.window.setTitle("Block Blast - Windows Edition")
    
    -- Initialize cursor to default (arrow) for desktop
    love.mouse.setCursor()
    
    -- Update window size and scale
    config.updateWindowSize()
    
    gameState.loadFonts()
    gameState.loadHighScore()
    gameState.loadMoney()
    gameState.loadUpgrades()
    
    -- Load audio settings
    audio.loadSettings()
    
    -- Ensure currentTheme is synced with activeTheme after loading
    gameState.currentTheme = config.getThemeIndex(gameState.activeTheme or "classic")
    
    audio.generateSFX()
    audio.initMusic()
    graphics.loadSettingsIcon()
    graphics.loadShopIcons()
    graphics.generateBlockCanvases(gameState.currentTheme)
    initGame()
end

function love.resize(w, h)
    config.updateWindowSize(w, h)
    -- Regenerate block canvases with new cell size
    graphics.generateBlockCanvases(gameState.currentTheme)
    -- Update tray positions for existing pieces
    if gameState.tray then
        for i, p in ipairs(gameState.tray) do
            if not p.used then
                local tx = (config.WINDOW_W / 2) + ((i - 2) * config.TRAY_SPACING)
                p.baseX = tx
                p.baseY = config.TRAY_Y
                p.x = tx
                p.y = config.TRAY_Y + 80
            end
        end
    end
end

function initGame()
    gameState.init()
    effects.clear()
    gameState.tray = gameLogic.fillTray(gameState.currentTheme)
    gameState.stateTransition = 0
    gameState.previousState = "PLAYING"
    gameState.gearRotation = 0
    gameState.gearHover = false
    gameState.showHintDialog = false
    gameState.showShopDialog = false
    
    -- Apply lucky start bonus (doesn't affect persistent money, just for this game)
    local startingBonus = gameState.upgrades.luckyStart * 50
    if startingBonus > 0 then
        -- This is handled per-game, not added to persistent money
        -- The bonus is applied when calculating starting resources if needed
    end
end

function love.update(dt)
    audio.update()
    gameState.shaderTime = gameState.shaderTime + dt
    gameState.playTime = gameState.playTime + dt
    gameState.displayScore = gameState.displayScore + (gameState.score - gameState.displayScore) * 15 * dt
    gameState.displayMoney = gameState.displayMoney + (gameState.money - gameState.displayMoney) * 15 * dt
    
    -- Update high score if current score exceeds it (for real-time display)
    if gameState.score > gameState.highScore then
        gameState.highScore = gameState.score
        gameState.markForSave()  -- Mark for auto-save when high score changes
    end
    
    -- Update auto-save system
    gameState.updateAutoSave(dt)
    
    -- Update hint timer
    if gameState.hintPosition then
        gameState.hintTimer = gameState.hintTimer - dt
        if gameState.hintTimer <= 0 then
            gameState.hintPosition = nil
        end
    end
    
    if gameState.screenShake > 0 then 
        gameState.screenShake = math.max(0, gameState.screenShake - 60 * dt) 
    end

    -- Update gear rotation
    if gameState.gearHover then
        gameState.gearRotation = gameState.gearRotation + dt * 2
    else
        gameState.gearRotation = gameState.gearRotation + dt * 0.5
    end

    -- Update state transition
    if gameState.stateTransition < 1 then
        gameState.stateTransition = math.min(1, gameState.stateTransition + dt * 5)
    end

    if gameState.state == "PLAYING" and math.floor(gameState.playTime) % 10 == 0 then
        -- Cycle ambient text every 10 seconds
        gameState.ambientIndex = (math.floor(gameState.playTime / 10) % #config.AMBIENT_TEXTS) + 1
    end

    -- Update tray pieces with spring physics (desktop-first: no fingerOffset)
    for _, p in ipairs(gameState.tray) do
        if not p.used then
            p.scale, p.scaleVel = utils.spring(p.scale, p.scaleVel, p.targetScale, 150, 12, dt)
            -- Desktop: blocks follow mouse cursor directly, no offset needed
            p.fingerOffset = 0
            if p == gameState.dragging then
                -- Dragging block position is set directly by mouse in input.handleMouseMoved
                -- No spring physics needed for dragging
            else
                p.x, p.vx = utils.spring(p.x, p.vx, p.baseX, 100, 12, dt)
                p.y, p.vy = utils.spring(p.y, p.vy, p.baseY, 100, 12, dt)
            end
        end
    end

    -- Update FX
    effects.update(dt)
    
    -- Update UI
    local mx, my = love.mouse.getPosition()
    ui.setMousePos(mx, my)
    ui.update(dt, gameState.state)
end

function love.mousepressed(mx, my, button)
    if button ~= 1 then return end
    
    -- Handle hint dialog
    if gameState.showHintDialog then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW = 375  -- Fixed width (no scaling)
        local dialogH = 300  -- Fixed height (no scaling)
        local dialogTop = dialogY - dialogH/2
        local buttonY = dialogTop + 240  -- Fixed position (no scaling)
        local buttonW, buttonH = 140, 60  -- Fixed sizes (no scaling)
        
        -- Close button - Fixed position (no scaling)
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if math.sqrt((mx - closeX)^2 + (my - closeY)^2) < 20 then
            gameState.showHintDialog = false
            gameState.stateTransition = 0
            audio.playSFX("ui_click")
            return
        end
        
        -- YES button (left)
        local yesBtnX = dialogX - 100  -- Fixed position (no scaling)
        if mx >= yesBtnX - buttonW/2 and mx <= yesBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            local hintCost = config.getHintCost(gameState.score, gameState.premiumItems)
            if gameState.money >= hintCost then
                gameState.money = gameState.money - hintCost
                gameState.saveMoney()
                gameState.hintPosition = gameLogic.findHint(gameState.tray, gameState.grid)
                if gameState.hintPosition then
                    -- Base 3 seconds + 2 seconds per hintMaster level
                    gameState.hintTimer = 3.0 + (gameState.upgrades.hintMaster * 2.0)
                    audio.playSFX("pickup")
        end
    else
                audio.playSFX("error")
            end
            gameState.showHintDialog = false
            gameState.stateTransition = 0
            return
        end
        
        -- NO button (right)
        local noBtnX = dialogX + 100  -- Fixed position (no scaling)
        if mx >= noBtnX - buttonW/2 and mx <= noBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            gameState.showHintDialog = false
            gameState.stateTransition = 0
            audio.playSFX("ui_click")
            return
        end
        return
    end

    -- (Real money dialog removed; premium buttons now open external links directly)

    -- Handle shop dialog interactions first
    if gameState.showShopDialog then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW, dialogH = 475, 600  -- Fixed sizes (no scaling) - min and max both 475 and 600
        local dialogTop = dialogY - dialogH/2
        local scrollOffset = gameState.shopScrollOffset or 0
        local contentStartY = dialogTop + 155  -- Fixed position (no scaling)
        
        -- Close button - Fixed position (no scaling)
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if math.sqrt((mx - closeX)^2 + (my - closeY)^2) < 20 then
            gameState.showShopDialog = false
            gameState.shopScrollOffset = 0  -- Reset scroll when closing
            gameState.shopPage = 1  -- Reset to page 1
            gameState.stateTransition = 0
            audio.playSFX("ui_click")
            return
        end
        
        local shopPage = gameState.shopPage or 1
        
        -- NEXT/PREV button (same line as section title) - Fixed sizes (no scaling)
        local nextPrevW = 70  -- Fixed width (no scaling)
        local nextPrevH = 32  -- Fixed height (no scaling)
        local nextPrevX = dialogX + dialogW/2 - 30 - nextPrevW/2  -- Fixed position (no scaling)
        local nextPrevY = contentStartY + scrollOffset + 5  -- Fixed position (no scaling)
        
        if mx >= nextPrevX - nextPrevW/2 and mx <= nextPrevX + nextPrevW/2 and
           my >= nextPrevY - nextPrevH/2 and my <= nextPrevY + nextPrevH/2 then
            gameState.shopPage = (shopPage == 1) and 2 or 1
            gameState.shopScrollOffset = 0  -- Reset scroll when changing pages
            audio.playSFX("ui_click")
            return
        end
        
        local shopPage = gameState.shopPage or 1
        
        if shopPage == 1 then
            -- PAGE 1: Regular upgrades - Fixed sizes (no scaling)
            local upgradeOrder = {"moneyMagnet", "scoreBoost", "hintMaster", "comboKing"}
            local itemHeight = 50  -- Fixed height (no scaling)
            local iconX = dialogX - dialogW/2 + 30  -- Fixed position (no scaling)
            local buttonW = 80  -- Fixed width (no scaling)
            local buttonX = dialogX + dialogW/2 - 30 - buttonW/2  -- Fixed position (no scaling)
            local upgradesLabelY = contentStartY + scrollOffset
            
            for i = 1, #upgradeOrder do
                local upgradeId = upgradeOrder[i]
                local upgrade = config.UPGRADES[upgradeId]
                local itemY = upgradesLabelY + 55 + (i - 1) * itemHeight  -- Fixed position (no scaling)
                local currentLevel = gameState.upgrades[upgradeId] or 0
                local isMaxed = currentLevel >= upgrade.maxLevel
                local nextCost = isMaxed and nil or config.getUpgradeCost(upgradeId, currentLevel, gameState.premiumItems)
                
                -- Check if clicking on this upgrade's button
                if my >= itemY - itemHeight/2 and my <= itemY + itemHeight/2 and
                   mx >= buttonX - buttonW/2 and mx <= buttonX + buttonW/2 then
                    
                    if isMaxed then
                        -- Already maxed
                        audio.playSFX("error")
                    elseif nextCost and gameState.money >= nextCost then
                        -- Purchase upgrade
                        gameState.money = math.max(0, gameState.money - nextCost)  -- Prevent negative money
                        gameState.saveMoney()
                        -- Clamp upgrade level to max
                        local newLevel = math.min(currentLevel + 1, upgrade.maxLevel)
                        gameState.upgrades[upgradeId] = newLevel
                        gameState.saveUpgrades()
                        audio.playSFX("pickup")
                    else
                        -- Can't afford
                        audio.playSFX("error")
                    end
                    return
                end
            end
        else
            -- PAGE 2: Gameplay upgrades - Fixed sizes (no scaling)
            local gameplayUpgradeOrder = {"rowBlast", "columnBlast", "colorWipe"}
            local itemHeight = 50  -- Fixed height (no scaling)
            local buttonW = 80  -- Fixed width (no scaling)
            local buttonX = dialogX + dialogW/2 - 30 - buttonW/2  -- Fixed position (no scaling)
            local gameplayLabelY = contentStartY + scrollOffset
            
            for i = 1, #gameplayUpgradeOrder do
                local upgradeId = gameplayUpgradeOrder[i]
                local upgrade = config.UPGRADES[upgradeId]
                if not upgrade then break end
                
                local itemY = gameplayLabelY + 55 + (i - 1) * itemHeight  -- Fixed position (no scaling)
                local currentLevel = gameState.upgrades[upgradeId] or 0
                local isMaxed = currentLevel >= upgrade.maxLevel
                local nextCost = isMaxed and nil or config.getUpgradeCost(upgradeId, currentLevel, gameState.premiumItems)
                
                -- Check if clicking on this upgrade's button
                if my >= itemY - itemHeight/2 and my <= itemY + itemHeight/2 and
                   mx >= buttonX - buttonW/2 and mx <= buttonX + buttonW/2 then
                    
                    if nextCost and gameState.money >= nextCost then
                        -- Purchase gameplay upgrade (consumable - can buy multiple times)
                        gameState.money = math.max(0, gameState.money - nextCost)
                        gameState.saveMoney()
                        -- Increment level to track purchase count (for cost scaling)
                        gameState.upgrades[upgradeId] = (gameState.upgrades[upgradeId] or 0) + 1
                        gameState.saveUpgrades()
                        
                        -- Close shop and execute gameplay action
                        gameState.showShopDialog = false
                        gameState.shopPage = 1
                        gameState.shopScrollOffset = 0
                        gameState.stateTransition = 0
                        
                        -- Execute the gameplay action
                        if upgradeId == "rowBlast" then
                            -- Clear bottom row
                            local cleared = gameLogic.clearRow(gameState.grid, effects, config.GRID_SIZE)
                            if cleared > 0 then
                                gameState.screenShake = 15
                                audio.playSFX("clear", 1.2)
                                effects.popText("ROW BLAST!", config.WINDOW_W/2, config.GRID_START_Y - 30, 
                                    gameState.fonts.large, {1, 0.8, 0}, gameState.fonts)
                                -- Check for new lines after clearing
                                gameLogic.checkLinesAndScore(gameState.grid, gameState, effects, audio)
                            end
                        elseif upgradeId == "columnBlast" then
                            -- Clear random column
                            local randomCol = love.math.random(1, config.GRID_SIZE)
                            local cleared = gameLogic.clearColumn(gameState.grid, effects, randomCol)
                            if cleared > 0 then
                                gameState.screenShake = 15
                                audio.playSFX("clear", 1.2)
                                effects.popText("COLUMN BLAST!", config.WINDOW_W/2, config.GRID_START_Y - 30, 
                                    gameState.fonts.large, {1, 0.8, 0}, gameState.fonts)
                                -- Check for new lines after clearing
                                gameLogic.checkLinesAndScore(gameState.grid, gameState, effects, audio)
                            end
                        elseif upgradeId == "colorWipe" then
                            -- Find all colors that exist on the grid
                            local colorsOnGrid = {}
                            for y = 1, config.GRID_SIZE do
                                for x = 1, config.GRID_SIZE do
                                    if gameState.grid[y][x].active and gameState.grid[y][x].colorIdx > 0 then
                                        local colorIdx = gameState.grid[y][x].colorIdx
                                        -- Add to set if not already present
                                        local found = false
                                        for _, c in ipairs(colorsOnGrid) do
                                            if c == colorIdx then
                                                found = true
                                                break
                                            end
                                        end
                                        if not found then
                                            table.insert(colorsOnGrid, colorIdx)
                                        end
                                    end
                                end
                            end
                            
                            -- Only clear if there are colors on the grid
                            if #colorsOnGrid > 0 then
                                -- Pick a random color from those that exist
                                local randomColor = colorsOnGrid[love.math.random(#colorsOnGrid)]
                                local cleared = gameLogic.clearColor(gameState.grid, effects, randomColor)
                                if cleared > 0 then
                                    gameState.screenShake = 20
                                    audio.playSFX("clear", 1.3)
                                    effects.popText("COLOR WIPE!", config.WINDOW_W/2, config.GRID_START_Y - 30, 
                                        gameState.fonts.large, {1, 0.5, 1}, gameState.fonts)
                                    -- Check for new lines after clearing
                                    gameLogic.checkLinesAndScore(gameState.grid, gameState, effects, audio)
                                end
                            else
                                -- Grid is empty, play error sound
                                audio.playSFX("error")
                            end
                        end
                        
                        audio.playSFX("pickup")
                    else
                        -- Can't afford
                        audio.playSFX("error")
                    end
                    return
                end
            end
            
            -- PREMIUM ITEMS on Page 2 - Fixed sizes (no scaling)
            local premiumOrder = {"unlimited_lives", "unlimited_hints", "unlock_everything"}
            local itemNames = {"Unlimited Lives", "Unlimited Hints", "Unlock Everything"}
            local pItemHeight = 60  -- Fixed height (no scaling)
            local pButtonW = 80  -- Fixed width (no scaling)
            local pButtonX = dialogX + dialogW/2 - 30 - pButtonW/2  -- Fixed position (no scaling)
            local premiumLabelY = gameplayLabelY + 55 + (#gameplayUpgradeOrder * itemHeight) + 20  -- Fixed position (no scaling)
            
            for i = 1, #premiumOrder do
                local itemY = premiumLabelY + 55 + (i - 1) * pItemHeight  -- Fixed position (no scaling)
                if my >= itemY - pItemHeight/2 and my <= itemY + pItemHeight/2 and
                   mx >= pButtonX - pButtonW/2 and mx <= pButtonX + pButtonW/2 then

                    -- Open external purchase link directly instead of in-game confirmation
                    local premiumId = premiumOrder[i]
                    local url = nil
                    if premiumId == "unlimited_lives" then
                        url = "https://buymeacoffee.com/galore/e/520853"
                    elseif premiumId == "unlimited_hints" then
                        url = "https://buymeacoffee.com/galore/e/520854"
                    elseif premiumId == "unlock_everything" then
                        url = "https://buymeacoffee.com/galore/e/520856"
                    end

                    if url and love.system and love.system.openURL then
                        love.system.openURL(url)
                    end

                    gameState.showShopDialog = false
                    gameState.stateTransition = 0
                    audio.playSFX("ui_click")
                    return
                end
            end
        end
        
        -- Check Support Dev Footer Button - Positioned at bottom right of screen - Fixed sizes (no scaling)
        local footerW = 220  -- Fixed width (no scaling)
        local footerH = 45  -- Fixed height (no scaling)
        local footerX = config.WINDOW_W - 120  -- Fixed position (no scaling)
        local footerY = config.WINDOW_H - 60  -- Fixed position (no scaling)
        
        if mx >= footerX - footerW/2 and mx <= footerX + footerW/2 and
           my >= footerY - footerH/2 and my <= footerY + footerH/2 then
            -- Use system.openURL (love.js handles this automatically in web)
            if love.system and love.system.openURL then
                love.system.openURL("https://buymeacoffee.com/galore")
            else
                -- Fallback for web (love.js should handle this, but just in case)
                print("Support the developer: https://buymeacoffee.com/galore")
            end
            gameState.showShopDialog = false
            gameState.stateTransition = 0
            audio.playSFX("ui_click")
            return
        end
        
        -- Check theme card clicks (only on page 1) - Fixed sizes (no scaling)
        if shopPage == 1 then
            local themesMap = {
                { id = "classic", name = "CLASSIC", price = config.getThemeCost("classic", gameState.premiumItems), idx = 1 },
                { id = "neon", name = "NEON", price = config.getThemeCost("neon", gameState.premiumItems), idx = 2 },
                { id = "pastel", name = "PASTEL", price = config.getThemeCost("pastel", gameState.premiumItems), idx = 3 },
                { id = "ocean", name = "OCEAN", price = config.getThemeCost("ocean", gameState.premiumItems), idx = 4 }
            }
            local upgradeOrder = {"moneyMagnet", "scoreBoost", "hintMaster", "comboKing"}
            local itemHeight = 50  -- Fixed height (no scaling)
            local upgradesLabelY = contentStartY + scrollOffset
            local themesLabelY = upgradesLabelY + 55 + (#upgradeOrder * itemHeight) + 20  -- Reduced spacing to fit 600px height
            local themesStartY = themesLabelY + 50  -- Reduced spacing to fit 600px height
            local cardW, cardH = 85, 100  -- Fixed sizes (no scaling)
            local cardSpacing = 15  -- Fixed spacing (no scaling)
            local startX = dialogX - (cardW * 1.5 + cardSpacing * 1.5)  -- Fixed position (no scaling)
            
            for i, theme in ipairs(themesMap) do
                local cardX = startX + (i - 1) * (cardW + cardSpacing)
                local cardY = themesStartY
                local isOwned = gameState.themes[theme.id] or (theme.id == "classic")
                local isActive = gameState.activeTheme == theme.id
                local canAfford = gameState.money >= theme.price
                
                -- Check if clicking on this theme card
                if mx >= cardX - cardW/2 and mx <= cardX + cardW/2 and
                   my >= cardY - cardH/2 and my <= cardY + cardH/2 then
                    
                    if isActive then
                        -- Already active
                        audio.playSFX("ui_click")
                    elseif isOwned then
                        -- Select theme
                        gameState.activeTheme = theme.id
                        gameState.currentTheme = config.getThemeIndex(theme.id)  -- Sync numeric index
                        gameState.saveUpgrades()
                        graphics.generateBlockCanvases(gameState.currentTheme)
                        -- Regenerate tray with new theme colors
                        gameState.tray = gameLogic.fillTray(gameState.currentTheme)
                        audio.playSFX("pickup")
                    elseif canAfford then
                        -- Purchase and activate theme
                        gameState.money = math.max(0, gameState.money - theme.price)  -- Prevent negative money
                        gameState.saveMoney()
                        gameState.themes[theme.id] = true
                        gameState.activeTheme = theme.id
                        gameState.currentTheme = config.getThemeIndex(theme.id)  -- Sync numeric index
                        gameState.saveUpgrades()
                        graphics.generateBlockCanvases(gameState.currentTheme)
                        -- Regenerate tray with new theme colors
                        gameState.tray = gameLogic.fillTray(gameState.currentTheme)
                        audio.playSFX("pickup")
                    else
                        -- Can't afford
                        audio.playSFX("error")
                    end
                    return
                end
            end
        end
        
        return
    end
    
    local result = input.handleMousePressed(mx, my, button, gameState, gameState.tray)
    if result == "RESTART" then
        initGame()
    elseif result == "CONTINUE" then
        -- Handle continue purchase
        local continueCost = config.getContinueCost(gameState.score, gameState.premiumItems)
        if gameState.money >= continueCost then
            -- Deduct money (may be 0 if unlimited_lives is purchased)
            gameState.money = math.max(0, gameState.money - continueCost)
            gameState.saveMoney()
            
            -- Clear 2-3 rows from bottom
            local rowsCleared = gameLogic.clearBottomRows(gameState.grid, effects, nil)
            
            -- Reset game state to continue playing
            gameState.state = "PLAYING"
            gameState.stateTransition = 0
            gameState.combo = 0  -- Reset combo
            
            -- Refill tray if needed
            local allUsed = true
            for _, p in ipairs(gameState.tray) do
                if not p.used then
                    allUsed = false
                    break
                end
            end
            if allUsed then
                gameState.tray = gameLogic.fillTray(gameState.currentTheme)
            end
            
            -- Play success sound
            audio.playSFX("pickup")
            
            -- Show feedback text
            if rowsCleared > 0 then
                effects.popText("ROWS CLEARED!", config.WINDOW_W/2, config.GRID_START_Y - 30, 
                    gameState.fonts.large, {0.2, 1, 0.4}, gameState.fonts)
            end
        else
            -- Can't afford
            audio.playSFX("error")
        end
    elseif result == "HINT" then
        -- Show hint confirmation dialog
        gameState.showHintDialog = true
        gameState.stateTransition = 0
        audio.playSFX("ui_click")
    elseif result == "SHOP" then
        -- Show shop dialog
        gameState.showShopDialog = true
        gameState.shopScrollOffset = 0  -- Reset scroll when opening
        gameState.shopPage = 1  -- Reset to page 1 when opening
        gameState.stateTransition = 0
        audio.playSFX("ui_click")
    end
end

function love.mousemoved(mx, my)
    input.handleMouseMoved(mx, my, gameState)
    ui.setMousePos(mx, my)
    
    -- Check hint button hover (only when not dragging) - Must match render.drawHintButton exactly
    if gameState.state == "PLAYING" and not gameState.dragging then
        local hintBtnW = math.max(60, 70 * config.scaleX)
        local hintBtnH = math.max(55, 65 * config.scaleY)
        local hintBtnX = math.max(50, 60 * config.scaleX)
        local hintBtnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
        gameState.hintButtonHover = (mx >= hintBtnX - hintBtnW/2 and mx <= hintBtnX + hintBtnW/2 and
                                     my >= hintBtnY - hintBtnH/2 and my <= hintBtnY + hintBtnH/2)
    else
        gameState.hintButtonHover = false
    end
    
    -- Check shop button hover (only when not dragging) - Must match render.drawShopButton exactly
    if gameState.state == "PLAYING" and not gameState.dragging then
        local shopBtnW = math.max(60, 70 * config.scaleX)
        local shopBtnH = math.max(55, 65 * config.scaleY)
        local shopBtnX = config.WINDOW_W - math.max(50, 60 * config.scaleX)
        local shopBtnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
        gameState.shopButtonHover = (mx >= shopBtnX - shopBtnW/2 and mx <= shopBtnX + shopBtnW/2 and
                                     my >= shopBtnY - shopBtnH/2 and my <= shopBtnY + shopBtnH/2)
    else
        gameState.shopButtonHover = false
    end
    
    -- Cursor is updated in input.handleMouseMoved
end

function love.mousereleased(mx, my, button)
    local function checkLinesAndScore()
        gameLogic.checkLinesAndScore(gameState.grid, gameState, effects, audio)
    end
    
    local function checkGameOver()
        local result = gameLogic.checkGameOver(gameState.tray, gameState.grid, gameState, audio)
        if result == "REFILL" then
            gameState.tray = gameLogic.fillTray(gameState.currentTheme)
        end
    end
    
    input.handleMouseReleased(mx, my, button, gameState, gameState.tray, checkLinesAndScore, checkGameOver)
end

function love.wheelmoved(x, y)
    -- Handle shop scrolling
    if gameState.showShopDialog then
        local scrollSpeed = 30
        gameState.shopScrollOffset = gameState.shopScrollOffset - (y * scrollSpeed)
        
        -- Calculate total content height (card layout for themes) - Fixed sizes (no scaling)
        local upgradeOrder = {"moneyMagnet", "scoreBoost", "hintMaster", "comboKing", "luckyStart"}
        local itemHeight = 50  -- Fixed height (no scaling)
        local themesCardHeight = 100  -- Fixed card height (no scaling)
        local totalHeight = 55 + (#upgradeOrder * itemHeight) + 30 + 80 + themesCardHeight  -- Fixed positions (no scaling)
        local visibleHeight = 600 - 155 - 20  -- Dialog height (600) minus header and padding (no scaling)
        
        -- Clamp scroll offset
        local maxScroll = math.max(0, totalHeight - visibleHeight)
        gameState.shopScrollOffset = math.max(0, math.min(maxScroll, gameState.shopScrollOffset))
    end
end

function love.keypressed(key, scancode, isrepeat)
    -- Toggle fullscreen with F11 or Alt+Enter
    if key == "f11" or (key == "return" and love.keyboard.isDown("lalt", "ralt")) then
        local fullscreen = love.window.getFullscreen()
        love.window.setFullscreen(not fullscreen)
        if not fullscreen then
            -- Going fullscreen - update size
            local w, h = love.window.getDesktopDimensions()
            config.updateWindowSize(w, h)
            graphics.generateBlockCanvases(gameState.currentTheme)
        else
            -- Exiting fullscreen - restore base size
            config.updateWindowSize(config.BASE_WINDOW_W, config.BASE_WINDOW_H)
            graphics.generateBlockCanvases(gameState.currentTheme)
        end
    end
    -- Escape to exit fullscreen
    if key == "escape" and love.window.getFullscreen() then
        love.window.setFullscreen(false)
        config.updateWindowSize(config.BASE_WINDOW_W, config.BASE_WINDOW_H)
        graphics.generateBlockCanvases(gameState.currentTheme)
    end
end

function love.quit()
    -- Save everything when quitting
    gameState.autoSave()
end

function love.draw()
    -- 1. Animated Shader Background
    render.drawBackground(gameState.shaderTime)

    local dx, dy = 0, 0
    if gameState.screenShake > 0 then
        dx, dy = love.math.random(-gameState.screenShake, gameState.screenShake), 
                 love.math.random(-gameState.screenShake, gameState.screenShake)
        love.graphics.translate(dx, dy)
    end

    -- 2. Header UI (Crown, Score, Gear)
    render.drawHeader(gameState.highScore, gameState.displayScore, gameState.fonts, 
        gameState.shaderTime, gameState.gearRotation, gameState.gearHover, gameState.displayMoney)

    -- 3. Board
    render.drawBoard(gameState.grid, gameState.predictedClears, gameState.shaderTime, 
        graphics.blockCanvases, gameState.state)

    -- 4. Lasers
    render.drawLasers()

    -- 5. Clear Animations
    render.drawAnimations(graphics.blockCanvases)

    -- 6. Ghost Block and Drop Shadow
    render.drawGhostBlock(gameState.dragging, graphics.blockCanvases, gameState.grid)

    -- 7. Tray Pieces
    render.drawTray(gameState.tray, gameState.dragging, graphics.blockCanvases, gameState.state)

    -- 8. Particles
    render.drawParticles()

    -- 9. Ambient Bottom Text - STATIC
    render.drawAmbientText(gameState.combo, gameState.ambientIndex, 
        config.AMBIENT_TEXTS, gameState.fonts, gameState.state, gameState.dragging)

    -- 10. Floating Texts (Combo popups)
    render.drawFloatingTexts(gameState.fonts)
    
    -- 11. Hint Button (left side center) - Hide when dragging
    if gameState.state == "PLAYING" and not gameState.dragging then
        local hintCost = config.getHintCost(gameState.score, gameState.premiumItems)
        render.drawHintButton(gameState.money, hintCost, gameState.fonts, 
            gameState.hintButtonHover, gameState.shaderTime)
    end
    
    -- 13. Shop Button (right side center) - Hide when dragging
    if gameState.state == "PLAYING" and not gameState.dragging then
        render.drawShopButton(gameState.fonts, gameState.shopButtonHover, gameState.shaderTime)
    end
    
    -- 12. Hint Indicator
    if gameState.hintPosition and gameState.hintTimer > 0 then
        render.drawHintIndicator(gameState.hintPosition, gameState.tray, 
            graphics.blockCanvases, gameState.hintTimer)
    end

    -- --- MENUS & OVERLAYS ---
    love.graphics.origin() -- Remove shake for UI

    if gameState.state == "GAMEOVER" then
        -- Check continue button hover
        local hoverButton = nil
        local mx, my = love.mouse.getPosition()
        local continueBtnX = config.WINDOW_W/2
        local continueBtnY = config.WINDOW_H/2 + 40 * config.scaleY
        local continueBtnW = 280 * config.scaleX
        local continueBtnH = 80 * config.scaleY
        
        if mx >= continueBtnX - continueBtnW/2 and mx <= continueBtnX + continueBtnW/2 and
           my >= continueBtnY - continueBtnH/2 and my <= continueBtnY + continueBtnH/2 then
            hoverButton = 1
        end
        
        local continueCost = config.getContinueCost(gameState.score, gameState.premiumItems)
        render.drawGameOver(gameState.score, gameState.money, continueCost, gameState.fonts, hoverButton, gameState.stateTransition)
    elseif gameState.state == "SETTINGS" then
        local hoverButton = nil
        local mx, my = love.mouse.getPosition()
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW = 400  -- Fixed width 400px (min and max both 400)
        local dialogH = 500  -- Fixed height 500px (min and max both 500)
        local dialogTop = dialogY - dialogH/2
        
        -- Close button - matching shop UI style exactly (fixed positions, no scaling)
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if math.sqrt((mx - closeX)^2 + (my - closeY)^2) < 20 then
            hoverButton = 0
        end
        
        -- Button dimensions - fixed size (no scaling) to match default window
        local btnW = 360  -- Fixed width (no scaling)
        local btnH = 60  -- Fixed height (no scaling)
        local halfW = btnW / 2
        local halfH = btnH / 2
        
        -- Button Y positions - fixed positions (no scaling) matching render.lua exactly
        local soundBtnY = dialogTop + 153  -- Fixed position (no scaling)
        local musicBtnY = dialogTop + 223  -- Fixed position (no scaling)
        local restartBtnY = dialogTop + 293  -- Fixed position (no scaling)
        local resumeBtnY = dialogTop + 363  -- Fixed position (no scaling)
        local resetBtnY = dialogTop + 433  -- Fixed position (no scaling)
        local resetBtnH = 55  -- Fixed height (no scaling)
        
        -- Sound button
        if mx > dialogX - halfW and mx < dialogX + halfW and my > soundBtnY - halfH and my < soundBtnY + halfH then
            hoverButton = 1
        -- Music button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > musicBtnY - halfH and my < musicBtnY + halfH then
            hoverButton = 4
        -- Restart button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > restartBtnY - halfH and my < restartBtnY + halfH then
            hoverButton = 2
        -- Resume button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > resumeBtnY - halfH and my < resumeBtnY + halfH then
            hoverButton = 3
        -- Reset Everything button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > resetBtnY - resetBtnH/2 and my < resetBtnY + resetBtnH/2 then
            hoverButton = 10
        end
        
        if gameState.showResetDialog then
            local resetHover = nil
            local dialogH = 320 * config.scaleY
            local dialogTop = dialogY - dialogH/2
            local buttonY = dialogTop + 240 * config.scaleY
            local buttonW, buttonH = 140 * config.scaleX, 60 * config.scaleY
            
            -- YES button (left)
            local yesBtnX = dialogX - 100 * config.scaleX
            if mx >= yesBtnX - buttonW/2 and mx <= yesBtnX + buttonW/2 and
               my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
                resetHover = 1
            -- NO button (right)
            elseif mx >= dialogX + 100 * config.scaleX - buttonW/2 and mx <= dialogX + 100 * config.scaleX + buttonW/2 and
               my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
                resetHover = 2
            end
            
            render.drawResetConfirmDialog(gameState.fonts, resetHover, gameState.stateTransition)
        else
            render.drawSettings(audio.enabled, audio.musicEnabled, gameState.fonts, hoverButton, gameState.stateTransition)
        end
    end
    
    -- Dialog overlays (can appear in any state)
    if gameState.showHintDialog then
        local hoverButton = nil
        local mx, my = love.mouse.getPosition()
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW = 375  -- Fixed width (no scaling)
        local dialogH = 300  -- Fixed height (no scaling)
        local dialogTop = dialogY - dialogH/2
        local buttonY = dialogTop + 240  -- Fixed position (no scaling)
        local buttonW, buttonH = 140, 60  -- Fixed sizes (no scaling)
        
        -- Close button - Fixed position (no scaling)
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if math.sqrt((mx - closeX)^2 + (my - closeY)^2) < 20 then
            hoverButton = 0
        -- YES button (left)
        elseif mx >= dialogX - 100 - buttonW/2 and mx <= dialogX - 100 + buttonW/2 and
               my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            hoverButton = 1
        -- NO button (right)
        elseif mx >= dialogX + 100 - buttonW/2 and mx <= dialogX + 100 + buttonW/2 and
               my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            hoverButton = 2
        end
        local hintCost = config.getHintCost(gameState.score, gameState.premiumItems)
        render.drawHintDialog(gameState.money, hintCost, gameState.fonts, hoverButton, gameState.stateTransition)
    elseif gameState.showRealMoneyDialog then
        local hoverButton = nil
        local mx, my = love.mouse.getPosition()
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW = 380 * config.scaleX
        local dialogH = 320 * config.scaleY
        local dialogTop = dialogY - dialogH/2
        local buttonY = dialogTop + 240 * config.scaleY
        local buttonW, buttonH = 140 * config.scaleX, 60 * config.scaleY
        
        -- YES button (left)
        local yesBtnX = dialogX - 100 * config.scaleX
        if mx >= yesBtnX - buttonW/2 and mx <= yesBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            hoverButton = 1
        -- NO button (right)
            elseif mx >= dialogX + 100 * config.scaleX - buttonW/2 and mx <= dialogX + 100 * config.scaleX + buttonW/2 and
               my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            hoverButton = 2
        end
        render.drawRealMoneyDialog(gameState.pendingIAPName or "Item", gameState.pendingIAPCost or "$4.99", gameState.fonts, hoverButton, gameState.stateTransition)
    elseif gameState.showShopDialog then
        local hoverButton = nil
        local mx, my = love.mouse.getPosition()
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW, dialogH = 475, 600  -- Fixed sizes (no scaling) - min and max both 475 and 600
        local dialogTop = dialogY - dialogH/2
        local scrollOffset = gameState.shopScrollOffset or 0
        local contentStartY = dialogTop + 155  -- Fixed position (no scaling)
        
        -- Close button - Fixed position (no scaling)
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if math.sqrt((mx - closeX)^2 + (my - closeY)^2) < 20 then
            hoverButton = 0
        else
            local shopPage = gameState.shopPage or 1
            local scrollOffset = gameState.shopScrollOffset or 0
            local contentStartY = dialogTop + 155
            
            -- NEXT/PREV button (same line as section title) - Fixed sizes (no scaling)
            local nextPrevW = 70  -- Fixed width (no scaling)
            local nextPrevH = 32  -- Fixed height (no scaling)
            local nextPrevX = dialogX + dialogW/2 - 30 - nextPrevW/2  -- Fixed position (no scaling)
            local nextPrevY = contentStartY + scrollOffset + 5  -- Same Y as section title (no scaling)
            
            if mx >= nextPrevX - nextPrevW/2 and mx <= nextPrevX + nextPrevW/2 and
               my >= nextPrevY - nextPrevH/2 and my <= nextPrevY + nextPrevH/2 then
                hoverButton = 100
            elseif shopPage == 1 then
                -- Check upgrade items (1-5) - Fixed sizes (no scaling)
                local upgradeOrder = {"moneyMagnet", "scoreBoost", "hintMaster", "comboKing", "luckyStart"}
                local itemHeight = 50  -- Fixed height (no scaling)
                local iconX = dialogX - dialogW/2 + 30  -- Fixed position (no scaling)
                local buttonW = 80  -- Fixed width (no scaling)
                local buttonX = dialogX + dialogW/2 - 30 - buttonW/2  -- Fixed position (no scaling)
                local upgradesLabelY = contentStartY + scrollOffset
                
                for i = 1, #upgradeOrder do
                    local itemY = upgradesLabelY + 55 + (i - 1) * itemHeight  -- Fixed position (no scaling)
                    if my >= itemY - itemHeight/2 and my <= itemY + itemHeight/2 then
                        if mx >= buttonX - buttonW/2 and mx <= buttonX + buttonW/2 then
                            hoverButton = i
                            break
                        end
                    end
                end
                
                -- Check theme cards (6-9) if no upgrade hovered (matching backup card layout)
                if not hoverButton then
                    local themesMap = {
                        { id = "classic", name = "CLASSIC", price = 0, idx = 1 },
                        { id = "neon", name = "NEON", price = 0, idx = 2 },  -- FREE for testing
                        { id = "pastel", name = "PASTEL", price = 0, idx = 3 },  -- FREE for testing
                        { id = "ocean", name = "OCEAN", price = 0, idx = 4 }  -- FREE for testing
                    }
                    local themesLabelY = upgradesLabelY + 55 + (#upgradeOrder * itemHeight) + 20  -- Reduced spacing to fit 600px height
                    local themesStartY = themesLabelY + 50  -- Reduced spacing to fit 600px height
                    local cardW, cardH = 85, 100  -- Fixed sizes (no scaling)
                    local cardSpacing = 15  -- Fixed spacing (no scaling)
                    local startX = dialogX - (cardW * 1.5 + cardSpacing * 1.5)  -- Fixed position (no scaling)
                    
                    for i, theme in ipairs(themesMap) do
                        local cardX = startX + (i - 1) * (cardW + cardSpacing)
                        local cardY = themesStartY
                        
                        if mx >= cardX - cardW/2 and mx <= cardX + cardW/2 and
                           my >= cardY - cardH/2 and my <= cardY + cardH/2 then
                            hoverButton = i + 5  -- 6, 7, 8, 9 for themes
                            break
                        end
                    end
                end
            elseif shopPage == 2 then
                -- PAGE 2: Gameplay upgrades - Fixed sizes (no scaling)
                local gameplayUpgradeOrder = {"rowBlast", "columnBlast", "colorWipe"}
                local itemHeight = 50  -- Fixed height (no scaling)
                local buttonW = 80  -- Fixed width (no scaling)
                local buttonX = dialogX + dialogW/2 - 30 - buttonW/2  -- Fixed position (no scaling)
                local gameplayLabelY = contentStartY + scrollOffset
                
                for i = 1, #gameplayUpgradeOrder do
                    local itemY = gameplayLabelY + 55 + (i - 1) * itemHeight  -- Fixed position (no scaling)
                    if my >= itemY - itemHeight/2 and my <= itemY + itemHeight/2 then
                        if mx >= buttonX - buttonW/2 and mx <= buttonX + buttonW/2 then
                            hoverButton = i + 10  -- 11, 12, 13 for gameplay upgrades
                            break
                        end
                    end
                end
                
                -- Premium Items Hover (21-23) - Fixed sizes (no scaling)
                if not hoverButton then
                    local pItemHeight = 60  -- Fixed height (no scaling)
                    local pButtonW = 80  -- Fixed width (no scaling)
                    local pButtonX = dialogX + dialogW/2 - 30 - pButtonW/2  -- Fixed position (no scaling)
                    local premiumLabelY = gameplayLabelY + 55 + (#gameplayUpgradeOrder * itemHeight) + 20  -- Fixed position (no scaling)
                    
                    for i = 1, 3 do
                        local itemY = premiumLabelY + 55 + (i - 1) * pItemHeight  -- Fixed position (no scaling)
                        if my >= itemY - pItemHeight/2 and my <= itemY + pItemHeight/2 then
                            if mx >= pButtonX - pButtonW/2 and mx <= pButtonX + pButtonW/2 then
                                hoverButton = i + 20  -- 21, 22, 23
                                break
                            end
                        end
                    end
                end
            end
            
            if not hoverButton then
                -- Check Support Dev Footer Button - Positioned at bottom right of screen - Fixed sizes (no scaling)
                local footerW = 220  -- Fixed width (no scaling)
                local footerH = 45  -- Fixed height (no scaling)
                local footerX = config.WINDOW_W - 120  -- Fixed position (no scaling)
                local footerY = config.WINDOW_H - 60  -- Fixed position (no scaling)
                
                if mx >= footerX - footerW/2 and mx <= footerX + footerW/2 and
                   my >= footerY - footerH/2 and my <= footerY + footerH/2 then
                    hoverButton = 50
                end
            end
        end
        render.drawShopDialog(gameState.money, gameState.fonts, hoverButton, gameState.stateTransition)
    end
end
