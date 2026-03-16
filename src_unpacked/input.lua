-- Input Handling

local input = {}
local config = require("config")
local gameLogic = require("game_logic")
local audio = require("audio")
local effects = require("effects")

function input.handleMousePressed(mx, my, button, gameState, tray)
    if button ~= 1 then return end

    -- Handle reset dialog FIRST (it can appear over any state)
    if gameState.showResetDialog then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogH = 320 * config.scaleY
        local dialogTop = dialogY - dialogH/2
        local buttonY = dialogTop + 240 * config.scaleY
        local buttonW, buttonH = 140 * config.scaleX, 60 * config.scaleY
        
        -- YES button (left)
        local yesBtnX = dialogX - 100 * config.scaleX
        if mx >= yesBtnX - buttonW/2 and mx <= yesBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            
            -- Perform full reset - COMPLETE RESET OF ALL PERSISTENT DATA
            -- Set reset flag FIRST to prevent auto-save from interfering
            gameState.isResetting = true
            gameState.pendingSave = false
            gameState.autoSaveTimer = 0
            
            -- Delete score/money/audio save files FIRST to ensure clean slate
            -- (keep block_upgrades.txt so premium purchases / redeem perks persist)
            love.filesystem.remove("block_highscore.txt")
            love.filesystem.remove("block_money.txt")
            love.filesystem.remove("block_audio.txt")
            
            -- Reset ALL persistent game state variables to defaults
            gameState.highScore = 0
            gameState.money = 100
            gameState.displayMoney = 100
            gameState.score = 0
            gameState.displayScore = 0
            
            -- Reset all upgrades to 0
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
            
            -- Reset all themes (only classic owned)
            gameState.themes = {
                classic = true,
                neon = false,
                pastel = false,
                ocean = false
            }
            gameState.activeTheme = "classic"
            gameState.currentTheme = config.getThemeIndex("classic")
            
            -- Reset audio settings to defaults
            audio.enabled = true
            audio.musicEnabled = true
            audio.musicVolume = 0.105
            
            -- Write files DIRECTLY with correct values (don't use save functions that might read current state)
            love.filesystem.write("block_highscore.txt", "0")
            love.filesystem.write("block_money.txt", "100")
            audio.saveSettings()
            
            -- Now use save functions to ensure consistency (they should write the same values we just set)
            gameState.saveHighScore(true)
            gameState.saveMoney(true)
            gameState.saveUpgrades(true)
            
            -- Regenerate block canvases with classic theme
            require("graphics").generateBlockCanvases(gameState.currentTheme)
            
            -- Close all dialogs
            gameState.showResetDialog = false
            gameState.state = "PLAYING"
            gameState.stateTransition = 0
            
            -- Reset current game state (grid, score, combo, etc.)
            gameState.init()
            require("effects").clear()
            
            -- Ensure persistent values are still correct after init()
            gameState.highScore = 0
            gameState.money = 100
            gameState.displayMoney = 100
            gameState.score = 0
            gameState.displayScore = 0
            
            -- Reset upgrades again (in case init() modified them)
            gameState.upgrades.moneyMagnet = 0
            gameState.upgrades.scoreBoost = 0
            gameState.upgrades.hintMaster = 0
            gameState.upgrades.comboKing = 0
            gameState.upgrades.luckyStart = 0
            gameState.upgrades.rowBlast = 0
            gameState.upgrades.columnBlast = 0
            gameState.upgrades.colorWipe = 0
            
            -- Reset themes again
            gameState.themes.classic = true
            gameState.themes.neon = false
            gameState.themes.pastel = false
            gameState.themes.ocean = false
            gameState.activeTheme = "classic"
            gameState.currentTheme = config.getThemeIndex("classic")
            
            -- Reset premium items again
            gameState.premiumItems.unlimited_lives = false
            gameState.premiumItems.unlimited_hints = false
            gameState.premiumItems.unlock_everything = false
            
            -- Final save with verified values
            love.filesystem.write("block_highscore.txt", "0")
            love.filesystem.write("block_money.txt", "100")
            love.filesystem.write("block_upgrades.txt", 
                "moneyMagnet=0\n" ..
                "scoreBoost=0\n" ..
                "hintMaster=0\n" ..
                "comboKing=0\n" ..
                "luckyStart=0\n" ..
                "rowBlast=0\n" ..
                "columnBlast=0\n" ..
                "colorWipe=0\n" ..
                "theme_neon=false\n" ..
                "theme_pastel=false\n" ..
                "theme_ocean=false\n" ..
                "activeTheme=classic\n" ..
                "premium_unlimited_lives=false\n" ..
                "premium_unlimited_hints=false\n" ..
                "premium_unlock_everything=false"
            )
            gameState.saveHighScore(true)
            gameState.saveMoney(true)
            gameState.saveUpgrades(true)
            
            -- Verify files were written correctly by reading them back
            local verifyHighScore = love.filesystem.read("block_highscore.txt")
            local verifyMoney = love.filesystem.read("block_money.txt")
            local verifyUpgrades = love.filesystem.read("block_upgrades.txt")
            
            -- If files don't match, force write again
            if verifyHighScore and tonumber(verifyHighScore:match("^(%d+)")) ~= 0 then
                love.filesystem.write("block_highscore.txt", "0")
                gameState.highScore = 0
            end
            if verifyMoney and tonumber(verifyMoney:match("^(%d+)")) ~= 100 then
                love.filesystem.write("block_money.txt", "100")
                gameState.money = 100
                gameState.displayMoney = 100
            end
            if verifyUpgrades and not verifyUpgrades:match("moneyMagnet=0") then
                love.filesystem.write("block_upgrades.txt", 
                    "moneyMagnet=0\n" ..
                    "scoreBoost=0\n" ..
                    "hintMaster=0\n" ..
                    "comboKing=0\n" ..
                    "luckyStart=0\n" ..
                    "rowBlast=0\n" ..
                    "columnBlast=0\n" ..
                    "colorWipe=0\n" ..
                    "theme_neon=false\n" ..
                    "theme_pastel=false\n" ..
                    "theme_ocean=false\n" ..
                    "activeTheme=classic"
                )
            end
            
            -- Ensure auto-save won't interfere
            gameState.pendingSave = false
            gameState.autoSaveTimer = 0
            
            -- Clear reset flag LAST - after all saves are complete
            gameState.isResetting = false
            
            audio.playSFX("clear")
            -- Play a second sound for effect
            audio.playSFX("pickup", 0.8)
            
            return "RESTART" -- Signal to main.lua to re-init if needed
        end
        
        -- NO button (right)
        local noBtnX = dialogX + 100 * config.scaleX
        if mx >= noBtnX - buttonW/2 and mx <= noBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            gameState.showResetDialog = false
            gameState.stateTransition = 0
            audio.playSFX("ui_click")
            return
        end
        return
    end

    if gameState.state == "SETTINGS" then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        -- Fixed size dialog (no scaling)
        local dialogW = 400  -- Fixed width 400px (min and max both 400)
        local dialogH = 500  -- Fixed height 500px (min and max both 500)
        local dialogTop = dialogY - dialogH/2
        
        -- Close button - Must match render.lua exactly (fixed positions, no scaling)
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if math.sqrt((mx - closeX)^2 + (my - closeY)^2) < 20 then
            audio.playSFX("ui_click")
            gameState.previousState = gameState.state
            gameState.state = "PLAYING"
            gameState.stateTransition = 0
            return
        end
        
        -- Button Params (matching render.lua) - Fixed size (no scaling)
        local btnW = 360  -- Fixed width (no scaling)
        local btnH = 60  -- Fixed height (no scaling)
        local halfW = btnW / 2
        local halfH = btnH / 2
        
        -- Button Y positions (matching render.lua exactly) - Fixed positions (no scaling)
        local soundBtnY = dialogTop + 153  -- Fixed position (no scaling)
        local musicBtnY = dialogTop + 223  -- Fixed position (no scaling)
        local restartBtnY = dialogTop + 293  -- Fixed position (no scaling)
        local resumeBtnY = dialogTop + 363  -- Fixed position (no scaling)
        local resetBtnY = dialogTop + 433  -- Fixed position (no scaling)
        local resetBtnH = 55  -- Fixed height (no scaling)
        
        -- Sound button
        if mx > dialogX - halfW and mx < dialogX + halfW and my > soundBtnY - halfH and my < soundBtnY + halfH then
            audio.enabled = not audio.enabled
            audio.saveSettings()
            gameState.markForSave()
            if audio.enabled then audio.playSFX("ui_click") end
        -- Music button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > musicBtnY - halfH and my < musicBtnY + halfH then
            audio.musicEnabled = not audio.musicEnabled
            audio.saveSettings()
            gameState.markForSave()
            if audio.enabled then audio.playSFX("ui_click") end
        -- Restart button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > restartBtnY - halfH and my < restartBtnY + halfH then
            audio.playSFX("ui_click")
            return "RESTART"
        -- Resume button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > resumeBtnY - halfH and my < resumeBtnY + halfH then
            audio.playSFX("ui_click")
            gameState.previousState = gameState.state
            gameState.state = "PLAYING"
            gameState.stateTransition = 0
        -- Reset Everything button
        elseif mx > dialogX - halfW and mx < dialogX + halfW and my > resetBtnY - resetBtnH/2 and my < resetBtnY + resetBtnH/2 then
            audio.playSFX("ui_click")
            gameState.showResetDialog = true
            gameState.stateTransition = 0
        end
        return
    end

    if gameState.state == "GAMEOVER" then
        -- Check continue button - Must match render.drawGameOver exactly
        local continueBtnX = config.WINDOW_W/2
        local continueBtnY = config.WINDOW_H/2 + 40 * config.scaleY
        local continueBtnW = 280 * config.scaleX
        local continueBtnH = 80 * config.scaleY
        
        if mx >= continueBtnX - continueBtnW/2 and mx <= continueBtnX + continueBtnW/2 and
           my >= continueBtnY - continueBtnH/2 and my <= continueBtnY + continueBtnH/2 then
            -- Continue button clicked - handled in main.lua
            return "CONTINUE"
        else
            -- Clicked elsewhere - restart
            audio.playSFX("ui_click")
            return "RESTART"
        end
    end

    -- Hint Button Hitbox (left side center) - Only when not dragging
    -- Must match render.drawHintButton exactly
    if gameState.state == "PLAYING" and not gameState.dragging then
        local hintBtnW = math.max(60, 70 * config.scaleX)
        local hintBtnH = math.max(55, 65 * config.scaleY)
        local hintBtnX = math.max(50, 60 * config.scaleX)
        local hintBtnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
        if mx >= hintBtnX - hintBtnW/2 and mx <= hintBtnX + hintBtnW/2 and
           my >= hintBtnY - hintBtnH/2 and my <= hintBtnY + hintBtnH/2 then
            return "HINT"
        end
    end
    
    -- Shop Button Hitbox (right side center) - Only when not dragging
    -- Must match render.drawShopButton exactly
    if gameState.state == "PLAYING" and not gameState.dragging then
        local shopBtnW = math.max(60, 70 * config.scaleX)
        local shopBtnH = math.max(55, 65 * config.scaleY)
        local shopBtnX = config.WINDOW_W - math.max(50, 60 * config.scaleX)
        local shopBtnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
        if mx >= shopBtnX - shopBtnW/2 and mx <= shopBtnX + shopBtnW/2 and
           my >= shopBtnY - shopBtnH/2 and my <= shopBtnY + shopBtnH/2 then
            return "SHOP"
        end
    end
    
    -- Settings Gear Hitbox (scaled) - Must match render.drawHeader gear position
    local gearX = config.WINDOW_W - math.max(40, 50 * config.scaleX)
    local gearY = math.max(35, 65 * config.scaleY)
    if input.dist(mx, my, gearX, gearY) < 30 * config.scale then
        gameState.previousState = gameState.state
        gameState.state = "SETTINGS"
        audio.playSFX("ui_click")
        gameState.stateTransition = 0
        return
    end

    -- Block Pickup Hitbox (scaled)
    for _, p in ipairs(tray) do
        if not p.used then
            -- Scale hitbox based on cell size for better accuracy
            local hw = math.max(60, config.CELL_SIZE * 1.5)
            local hh = math.max(60, config.CELL_SIZE * 1.5)
            if mx >= p.x - hw and mx <= p.x + hw and my >= p.y - hh and my <= p.y + hh then
                gameState.dragging = p
                gameState.dragging.targetScale = 1.0
                local pitch = 1.0 + (love.math.random() * 0.1 - 0.05)
                audio.playSFX("pickup", pitch)
                break
            end
        end
    end
end

function input.handleMouseMoved(mx, my, gameState)
    -- Update gear hover state (scaled) - Must match render.drawHeader gear position
    local gearX = config.WINDOW_W - math.max(40, 50 * config.scaleX)
    local gearY = math.max(35, 65 * config.scaleY)
    gameState.gearHover = (input.dist(mx, my, gearX, gearY) < 35 * config.scale)
    
    if gameState.dragging then
        gameState.dragging.x, gameState.dragging.y = mx, my
        gameLogic.updatePrediction(gameState.dragging, gameState.grid, gameState.predictedClears)
        -- When dragging, use grab cursor
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
    else
        -- Check if hovering over any interactive element
        input.updateCursor(mx, my, gameState)
    end
end

function input.handleMouseReleased(mx, my, button, gameState, tray, checkLinesAndScore, checkGameOver)
    if button == 1 and gameState.dragging then
        -- Desktop: blocks snap directly to mouse position, no fingerOffset
        local gx, gy = gameLogic.getSnapGridPos(
            gameState.dragging, 
            gameState.dragging.x, 
            gameState.dragging.y
        )
        
        if gameLogic.canPlace(gameState.dragging.shape, gx, gy, gameState.grid) then
            local pitch = 1.0 + (love.math.random() * 0.1 - 0.05)
            audio.playSFX("drop", pitch)
            for r = 1, gameState.dragging.h do
                for c = 1, gameState.dragging.w do
                    if gameState.dragging.shape[r][c] == 1 then
                        gameState.grid[gy+r-1][gx+c-1] = { 
                            active = true, 
                            colorIdx = gameState.dragging.colorIdx 
                        }
                        gameState.score = gameState.score + 10
                    end
                end
            end
            gameState.dragging.used = true
            gameState.screenShake = 3
            checkLinesAndScore()
            checkGameOver()
        else
            audio.playSFX("error")
            gameState.dragging.targetScale = 0.55
        end
        gameState.dragging = nil
        gameState.predictedClears = { rows = {}, cols = {} }
    end
end

function input.updateCursor(mx, my, gameState)
    -- Desktop cursor management: show pointer on hoverable elements
    
    -- Check if over blocks in tray (when playing and not dragging)
    if gameState.state == "PLAYING" and not gameState.dragging then
        for _, p in ipairs(gameState.tray) do
            if not p.used then
                local hw = math.max(60, config.CELL_SIZE * 1.5)
                local hh = math.max(60, config.CELL_SIZE * 1.5)
                if mx >= p.x - hw and mx <= p.x + hw and my >= p.y - hh and my <= p.y + hh then
                    love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                    return
                end
            end
        end
        
        -- Check hint button
        local hintBtnW = math.max(60, 70 * config.scaleX)
        local hintBtnH = math.max(55, 65 * config.scaleY)
        local hintBtnX = math.max(50, 60 * config.scaleX)
        local hintBtnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
        if mx >= hintBtnX - hintBtnW/2 and mx <= hintBtnX + hintBtnW/2 and
           my >= hintBtnY - hintBtnH/2 and my <= hintBtnY + hintBtnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- Check shop button
        local shopBtnW = math.max(60, 70 * config.scaleX)
        local shopBtnH = math.max(55, 65 * config.scaleY)
        local shopBtnX = config.WINDOW_W - math.max(50, 60 * config.scaleX)
        local shopBtnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
        if mx >= shopBtnX - shopBtnW/2 and mx <= shopBtnX + shopBtnW/2 and
           my >= shopBtnY - shopBtnH/2 and my <= shopBtnY + shopBtnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
    end
    
    -- Check settings gear (always visible)
    local gearX = config.WINDOW_W - math.max(40, 50 * config.scaleX)
    local gearY = math.max(35, 65 * config.scaleY)
    if input.dist(mx, my, gearX, gearY) < 35 * config.scale then
        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
        return
    end
    
    -- Check dialog buttons based on current state
    if gameState.state == "SETTINGS" then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW, dialogH = 400, 500
        local dialogTop = dialogY - dialogH/2
        local btnW, btnH = 360, 60
        
        -- Sound button
        local soundBtnY = dialogTop + 153
        if mx >= dialogX - btnW/2 and mx <= dialogX + btnW/2 and
           my >= soundBtnY - btnH/2 and my <= soundBtnY + btnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- Music button
        local musicBtnY = dialogTop + 223
        if mx >= dialogX - btnW/2 and mx <= dialogX + btnW/2 and
           my >= musicBtnY - btnH/2 and my <= musicBtnY + btnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- Restart button
        local restartBtnY = dialogTop + 293
        if mx >= dialogX - btnW/2 and mx <= dialogX + btnW/2 and
           my >= restartBtnY - btnH/2 and my <= restartBtnY + btnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- Resume button
        local resumeBtnY = dialogTop + 363
        if mx >= dialogX - btnW/2 and mx <= dialogX + btnW/2 and
           my >= resumeBtnY - btnH/2 and my <= resumeBtnY + btnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- Reset Everything button
        local resetBtnY = dialogTop + 433
        local resetBtnH = 55
        if mx >= dialogX - btnW/2 and mx <= dialogX + btnW/2 and
           my >= resetBtnY - resetBtnH/2 and my <= resetBtnY + resetBtnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- Close button
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if input.dist(mx, my, closeX, closeY) < 15 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
    end
    
    -- Check hint dialog buttons
    if gameState.showHintDialog then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW, dialogH = 375, 300
        local dialogTop = dialogY - dialogH/2
        local buttonW, buttonH = 140, 60
        local buttonY = dialogTop + 240
        
        -- YES button
        local yesBtnX = dialogX - 100
        if mx >= yesBtnX - buttonW/2 and mx <= yesBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- NO button
        local noBtnX = dialogX + 100
        if mx >= noBtnX - buttonW/2 and mx <= noBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
    end
    
    -- Check shop dialog buttons
    if gameState.showShopDialog then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogW, dialogH = 475, 600
        local dialogTop = dialogY - dialogH/2
        local scrollOffset = gameState.shopScrollOffset or 0
        local contentStartY = dialogTop + 155
        local shopPage = gameState.shopPage or 1
        
        -- Close button
        local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25
        if input.dist(mx, my, closeX, closeY) < 15 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- NEXT/PREV button
        local nextPrevW, nextPrevH = 70, 32
        local nextPrevX = dialogX + dialogW/2 - 30 - nextPrevW/2
        local nextPrevY = contentStartY + scrollOffset + 5
        if mx >= nextPrevX - nextPrevW/2 and mx <= nextPrevX + nextPrevW/2 and
           my >= nextPrevY - nextPrevH/2 and my <= nextPrevY + nextPrevH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        if shopPage == 1 then
            -- Upgrade buttons
            local upgradeOrder = {"moneyMagnet", "scoreBoost", "hintMaster", "comboKing"}
            local itemHeight = 50
            local buttonW = 80
            local buttonX = dialogX + dialogW/2 - 30 - buttonW/2
            local upgradesLabelY = contentStartY + scrollOffset
            
            for i = 1, #upgradeOrder do
                local itemY = upgradesLabelY + 55 + (i - 1) * itemHeight
                if my >= itemY - itemHeight/2 and my <= itemY + itemHeight/2 then
                    if mx >= buttonX - buttonW/2 and mx <= buttonX + buttonW/2 then
                        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                        return
                    end
                end
            end
            
            -- Theme cards
            local themesLabelY = upgradesLabelY + 55 + (#upgradeOrder * itemHeight) + 20
            local themesStartY = themesLabelY + 82
            local cardW, cardH = 85, 100
            local cardSpacing = 15
            local startX = dialogX - (cardW * 1.5 + cardSpacing * 1.5)
            
            for i = 1, 4 do
                local cardX = startX + (i - 1) * (cardW + cardSpacing)
                local cardY = themesStartY
                if mx >= cardX - cardW/2 and mx <= cardX + cardW/2 and
                   my >= cardY - cardH/2 and my <= cardY + cardH/2 then
                    love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                    return
                end
            end
        elseif shopPage == 2 then
            -- Gameplay upgrade buttons
            local gameplayUpgradeOrder = {"rowBlast", "columnBlast", "colorWipe"}
            local itemHeight = 50
            local buttonW = 80
            local buttonX = dialogX + dialogW/2 - 30 - buttonW/2
            local gameplayLabelY = contentStartY + scrollOffset
            
            for i = 1, #gameplayUpgradeOrder do
                local itemY = gameplayLabelY + 55 + (i - 1) * itemHeight
                if my >= itemY - itemHeight/2 and my <= itemY + itemHeight/2 then
                    if mx >= buttonX - buttonW/2 and mx <= buttonX + buttonW/2 then
                        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                        return
                    end
                end
            end
            
            -- Premium item buttons
            local premiumOrder = {
                {id = "unlimited_lives", name = "Unlimited Lives", icon = "lives", cost = "$4.99", url = "https://buymeacoffee.com/galore/e/520853"},
                {id = "unlimited_hints", name = "Unlimited Hints", icon = "hints", cost = "$4.99", url = "https://buymeacoffee.com/galore/e/520854"},
                {id = "unlock_everything", name = "Unlock Everything", icon = "unlock", cost = "$4.99", url = "https://buymeacoffee.com/galore/e/520856"}
            }
            local pItemHeight = 60
            local pButtonW = 80
            local pButtonX = dialogX + dialogW/2 - 30 - pButtonW/2
            local premiumLabelY = gameplayLabelY + 55 + (#gameplayUpgradeOrder * itemHeight) + 20
            
            for i = 1, #premiumOrder do
                local itemY = premiumLabelY + 55 + (i - 1) * pItemHeight
                if my >= itemY - pItemHeight/2 and my <= itemY + pItemHeight/2 then
                    if mx >= pButtonX - pButtonW/2 and mx <= pButtonX + pButtonW/2 then
                        love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
                        return
                    end
                end
            end
        end
        
        -- Support Dev button
        local footerW, footerH = 220, 45
        local footerX = config.WINDOW_W - 120
        local footerY = config.WINDOW_H - 60
        if mx >= footerX - footerW/2 and mx <= footerX + footerW/2 and
           my >= footerY - footerH/2 and my <= footerY + footerH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
    end
    
    -- Check game over continue button
    if gameState.state == "GAMEOVER" then
        local continueBtnX = config.WINDOW_W/2
        local continueBtnY = config.WINDOW_H/2 + 40 * config.scaleY
        local continueBtnW = 280 * config.scaleX
        local continueBtnH = 80 * config.scaleY
        if mx >= continueBtnX - continueBtnW/2 and mx <= continueBtnX + continueBtnW/2 and
           my >= continueBtnY - continueBtnH/2 and my <= continueBtnY + continueBtnH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
    end
    
    -- Check reset confirm dialog
    if gameState.showResetDialog then
        local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
        local dialogH = 320 * config.scaleY
        local dialogTop = dialogY - dialogH/2
        local buttonY = dialogTop + 240 * config.scaleY
        local buttonW, buttonH = 140 * config.scaleX, 60 * config.scaleY
        
        -- YES button
        local yesBtnX = dialogX - 100 * config.scaleX
        if mx >= yesBtnX - buttonW/2 and mx <= yesBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
        
        -- NO button
        local noBtnX = dialogX + 100 * config.scaleX
        if mx >= noBtnX - buttonW/2 and mx <= noBtnX + buttonW/2 and
           my >= buttonY - buttonH/2 and my <= buttonY + buttonH/2 then
            love.mouse.setCursor(love.mouse.getSystemCursor("hand"))
            return
        end
    end
    
    -- Default cursor (arrow)
    love.mouse.setCursor()
end

function input.dist(x1, y1, x2, y2) 
    return math.sqrt((x2-x1)^2 + (y2-y1)^2) 
end

return input
