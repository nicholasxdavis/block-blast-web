-- Rendering Functions - Clean Professional UI

local render = {}
local config = require("config")
local graphics = require("graphics")
local effects = require("effects")
local utils = require("utils")
local gameState = require("game_state")

-- Helper functions for clamped UI sizes (prevents choppy scaling)
function render.clampSize(baseSize, scale, minSize, maxSize)
    minSize = minSize or baseSize * 0.6
    maxSize = maxSize or baseSize * 1.5
    return math.max(minSize, math.min(maxSize, baseSize * scale))
end

function render.clampSizeX(baseSize, minSize, maxSize)
    return render.clampSize(baseSize, config.scaleX, minSize, maxSize)
end

function render.clampSizeY(baseSize, minSize, maxSize)
    return render.clampSize(baseSize, config.scaleY, minSize, maxSize)
end

function render.clampSizeUniform(baseSize, minSize, maxSize)
    return render.clampSize(baseSize, config.scale, minSize, maxSize)
end

-- Clean text rendering - NO ANIMATIONS
function render.drawTextWithStyle(text, x, y, font, align, style)
    style = style or {}
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local shadow = style.shadow ~= false
    local color = style.color or themeUI.textMain
    local alpha = style.alpha or 1
    
    love.graphics.setFont(font)
    
    -- Shadow only - no glow, no pulse, no movement
    if shadow then
        love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.4) * alpha)
        love.graphics.printf(text, x + 2, y + 2, config.WINDOW_W, align)
    end
    
    -- Main text - STATIC
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    love.graphics.printf(text, x, y, config.WINDOW_W, align)
end

function render.drawBackground(shaderTime)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    love.graphics.setShader(graphics.bgShader)
    graphics.bgShader:send("time", shaderTime)
    if graphics.bgShader:hasUniform("bgStart") then
        graphics.bgShader:send("bgStart", themeUI.bgStart)
        graphics.bgShader:send("bgEnd",   themeUI.bgEnd)
    end
    love.graphics.rectangle("fill", 0, 0, config.WINDOW_W, config.WINDOW_H)
    love.graphics.setShader()
end

function render.drawHeader(highScore, displayScore, fonts, shaderTime, gearRotation, gearHover, displayMoney)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    -- Crown - positioned for desktop layout (scaled with minimums)
    local crownCenterX = math.max(60, 80 * config.scaleX)
    local crownY = math.max(30, 50 * config.scaleY)
    local crownScale = config.scale
    local c15 = 15 * crownScale
    local c20 = 20 * crownScale
    local c5 = 5 * crownScale
    local c10 = 10 * crownScale
    
    -- Crown main
    love.graphics.setColor(themeUI.accent[1], themeUI.accent[2], themeUI.accent[3])
    love.graphics.polygon("fill", 
        crownCenterX-c15, crownY+c5, crownCenterX-c20, crownY-c10, crownCenterX-c5, crownY, crownCenterX, crownY-c15, 
        crownCenterX+c5, crownY, crownCenterX+c20, crownY-c10, crownCenterX+c15, crownY+c5, crownCenterX+c15, crownY+c15, 
        crownCenterX-c15, crownY+c15)
    
    -- Crown highlight
    love.graphics.setColor(255/255, 255/255, 200/255, 0.6)
    love.graphics.polygon("fill", 
        crownCenterX-c15, crownY+c5, crownCenterX-c20, crownY-c10, crownCenterX-c5, crownY, crownCenterX, crownY-c15, 
        crownCenterX+c5, crownY, crownCenterX+c20, crownY-c10, crownCenterX+c15, crownY+c5, crownCenterX+c15, crownY+c10, 
        crownCenterX-c15, crownY+c10)
    
    -- High score - Centered to crown
    love.graphics.setFont(fonts.small)
    local highScoreText = tostring(math.floor(highScore))
    local highScoreW = fonts.small:getWidth(highScoreText)
    local highScoreX = crownCenterX - highScoreW/2  -- Center to crown center
    local highScoreY = math.max(55, crownY + 25 * config.scaleY)  -- Position below crown
    
    -- Stronger shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6))
    love.graphics.print(highScoreText, highScoreX + 2, highScoreY + 2)
    
    -- Main text with brighter color
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3])
    love.graphics.print(highScoreText, highScoreX, highScoreY)
    
    -- Money display - Positioned directly below high score
    if displayMoney then
        love.graphics.setFont(fonts.small)
        local moneyText = "$" .. math.floor(displayMoney)
        local moneyW = fonts.small:getWidth(moneyText)
        local moneyH = fonts.small:getHeight()
        -- Position centered under high score, same X alignment
        local moneyX = crownCenterX - moneyW/2  -- Center to crown center (same as high score)
        local moneyY = highScoreY + moneyH + math.max(5, math.floor(8 * config.scaleY))  -- Below high score with spacing
        
        -- Stronger shadow
        love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6))
        love.graphics.print(moneyText, moneyX + 2, moneyY + 2)
        
        -- Main text - brighter gold
        love.graphics.setColor(themeUI.accent[1], themeUI.accent[2], themeUI.accent[3])
        love.graphics.print(moneyText, moneyX, moneyY)
    end

    -- Score Box - More vibrant and polished (scaled)
    local scoreBoxW = 200 * config.scaleX
    local scoreBoxH = math.max(80, math.floor(75 * config.scaleY))  -- Ensure minimum height for text
    local scoreBoxX = config.WINDOW_W/2 - scoreBoxW/2
    local scoreBoxY = math.max(20, math.floor(30 * config.scaleY))  -- Ensure minimum top margin
    
    -- Score box background - simple blue
    local scoreBoxRadius = math.max(8, math.floor(12 * config.scale))
    love.graphics.setColor(themeUI.popupBg[1], themeUI.popupBg[2], themeUI.popupBg[3], themeUI.popupBg[4] or 0.98)
    love.graphics.rectangle("fill", scoreBoxX, scoreBoxY, scoreBoxW, scoreBoxH, scoreBoxRadius, scoreBoxRadius)
    
    -- Score box border - simple
    love.graphics.setColor(themeUI.popupBorder[1], themeUI.popupBorder[2], themeUI.popupBorder[3], themeUI.popupBorder[4] or 0.8)
    love.graphics.setLineWidth(math.max(2, math.floor(3 * config.scale)))
    love.graphics.rectangle("line", scoreBoxX, scoreBoxY, scoreBoxW, scoreBoxH, scoreBoxRadius, scoreBoxRadius)
    love.graphics.setLineWidth(1)
    
    -- Score text - Enhanced (ensure it fits in box)
    love.graphics.setFont(fonts.huge)
    local scoreText = tostring(math.floor(displayScore))
    local textW = fonts.huge:getWidth(scoreText)
    local textH = fonts.huge:getHeight()
    local textX = config.WINDOW_W/2 - textW/2
    -- Center text vertically in box with proper padding
    local textY = scoreBoxY + math.max(5, (scoreBoxH - textH) / 2)
    
    -- Stronger shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6))
    love.graphics.print(scoreText, textX + 3, textY + 3)
    
    -- Main text - brighter white
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3])
    love.graphics.print(scoreText, textX, textY)
    
    
    -- Settings Icon - Enhanced with glow (scaled)
    local gearX = config.WINDOW_W - math.max(40, 50 * config.scaleX)
    local gearY = math.max(35, 65 * config.scaleY)
    local gearScale = gearHover and 1.15 or 1.0
    local gearAlpha = gearHover and 1.0 or 0.9
    
    -- No gear glow - cleaner look
    
    if graphics.settingsIcon then
        love.graphics.push()
        love.graphics.translate(gearX, gearY)
        love.graphics.rotate(gearRotation)
        love.graphics.scale(gearScale, gearScale)
        
        local iconW = graphics.settingsIcon:getWidth()
        local iconH = graphics.settingsIcon:getHeight()
        local iconSize = 26 * config.scale  -- Scaled
        
        love.graphics.setShader(graphics.whiteShader)
        love.graphics.setColor(1, 1, 1, gearAlpha)
        love.graphics.draw(graphics.settingsIcon, -iconSize/2, -iconSize/2, 0, iconSize/iconW, iconSize/iconH)
        love.graphics.setShader()
        love.graphics.pop()
    else
        love.graphics.push()
        love.graphics.translate(gearX, gearY)
        love.graphics.rotate(gearRotation)
        love.graphics.scale(gearScale, gearScale)
        
        local gearRadius = 14 * config.scale
        local gearOuter = 20 * config.scale
        love.graphics.setColor(1, 1, 1, gearAlpha)
        love.graphics.circle("line", 0, 0, gearRadius, 4)
        love.graphics.setLineWidth(math.max(2, math.floor(3 * config.scale)))
        for i = 1, 8 do
            local a = (i/8) * math.pi * 2
            love.graphics.line(
                math.cos(a)*gearRadius, math.sin(a)*gearRadius,
                math.cos(a)*gearOuter, math.sin(a)*gearOuter
            )
        end
        love.graphics.setLineWidth(1)
        love.graphics.pop()
    end
end

function render.drawBoard(grid, predictedClears, shaderTime, blockCanvases, state)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    -- Board Backdrop - Simple, clean (scaled)
    -- Calculate actual board size including all cells and spacing
    local actualBoardW = config.BOARD_W
    local boardPadding = math.max(10, math.floor(15 * config.scale))
    local boardX = config.GRID_START_X - boardPadding
    local boardY = config.GRID_START_Y - boardPadding
    local boardSize = actualBoardW + (boardPadding * 2)
    
    -- Board background - simple dark blue (scaled)
    local boardRadius = math.max(8, math.floor(12 * config.scale))
    love.graphics.setColor(themeUI.boardBg[1], themeUI.boardBg[2], themeUI.boardBg[3], themeUI.boardBg[4] or 0.95)
    love.graphics.rectangle("fill", boardX, boardY, boardSize, boardSize, boardRadius, boardRadius)
    
    -- Board border - simple (scaled)
    love.graphics.setColor(themeUI.boardBorder[1], themeUI.boardBorder[2], themeUI.boardBorder[3], themeUI.boardBorder[4] or 0.7)
    love.graphics.setLineWidth(math.max(1, math.floor(2 * config.scale)))
    love.graphics.rectangle("line", boardX, boardY, boardSize, boardSize, boardRadius, boardRadius)
    love.graphics.setLineWidth(1)

    -- Draw Grid Cells
    for y = 1, config.GRID_SIZE do
        for x = 1, config.GRID_SIZE do
            local bx = config.GRID_START_X + (x - 1) * (config.CELL_SIZE + config.SPACING)
            local by = config.GRID_START_Y + (y - 1) * (config.CELL_SIZE + config.SPACING)
            
            local cellRadius = math.max(3, math.floor(6 * config.scale))
            if predictedClears.rows[y] or predictedClears.cols[x] then
                -- Valid prediction - subtle highlight, NO PULSE
                love.graphics.setColor(themeUI.accent[1], themeUI.accent[2], themeUI.accent[3], 0.6)
                love.graphics.rectangle("fill", bx, by, config.CELL_SIZE, config.CELL_SIZE, cellRadius, cellRadius)
            else
                love.graphics.setColor(themeUI.cellEmpty[1], themeUI.cellEmpty[2], themeUI.cellEmpty[3], 0.9)
                love.graphics.rectangle("fill", bx, by, config.CELL_SIZE, config.CELL_SIZE, cellRadius, cellRadius)
            end
            
            if grid[y][x].active then
                local blockAlpha = state == "GAMEOVER" and 0.4 or 1
                love.graphics.setColor(1, 1, 1, blockAlpha)
                love.graphics.draw(blockCanvases[grid[y][x].colorIdx], bx, by)
            end
        end
    end
end

function render.drawLasers()
    love.graphics.setBlendMode("add")
    for _, l in ipairs(effects.lasers) do
        local intensity = l.life
        love.graphics.setColor(1, 1, 0.8, intensity * 0.8)
        love.graphics.rectangle("fill", l.x - 15, l.y - 15, l.w + 30, l.h + 30, 12, 12)
        love.graphics.setColor(1, 1, 1, intensity * 1.5)
        love.graphics.rectangle("fill", l.x, l.y, l.w, l.h, 5, 5)
        
        -- Core glow
        love.graphics.setColor(1, 1, 0.5, intensity * 2)
        love.graphics.rectangle("fill", l.x + l.w/4, l.y + l.h/4, l.w/2, l.h/2, 3, 3)
    end
    love.graphics.setBlendMode("alpha")
end

function render.drawAnimations(blockCanvases)
    for _, a in ipairs(effects.animations) do
        local offset = (config.CELL_SIZE - (config.CELL_SIZE * a.scale)) / 2
        love.graphics.setColor(1, 1, 1, a.scale)
        love.graphics.draw(blockCanvases[a.colorIdx], a.x + offset, a.y + offset, 0, a.scale, a.scale)
    end
end

function render.drawGhostBlock(dragging, blockCanvases, grid)
    if not dragging then return end
    
    local gameLogic = require("game_logic")
    -- Desktop: blocks snap directly to mouse position, no fingerOffset
    local gx, gy = gameLogic.getSnapGridPos(dragging, dragging.x, dragging.y)
    local ghostX = config.GRID_START_X + (gx - 1) * (config.CELL_SIZE+config.SPACING) + (dragging.w * (config.CELL_SIZE+config.SPACING)) / 2
    local ghostY = config.GRID_START_Y + (gy - 1) * (config.CELL_SIZE+config.SPACING) + (dragging.h * (config.CELL_SIZE+config.SPACING)) / 2
    
    -- Drop shadow (desktop: subtle shadow offset)
    love.graphics.setColor(0, 0, 0, 0.3)
    graphics.drawShape(dragging.shape, dragging.x + 5, dragging.y + 5, 
        dragging.scale, dragging.colorIdx, 1, blockCanvases)

    if gameLogic.canPlace(dragging.shape, gx, gy, grid) then
        -- Valid placement
        graphics.drawShape(dragging.shape, ghostX, ghostY, 1.0, dragging.colorIdx, 0.5, blockCanvases)
        love.graphics.setColor(0.2, 0.7, 1, 0.25)
        love.graphics.rectangle("fill", 
            config.GRID_START_X + (gx - 1) * (config.CELL_SIZE+config.SPACING) - 4, 
            config.GRID_START_Y + (gy - 1) * (config.CELL_SIZE+config.SPACING) - 4, 
            dragging.w * (config.CELL_SIZE+config.SPACING) + 8, 
            dragging.h * (config.CELL_SIZE+config.SPACING) + 8, 6, 6)
    else
        -- Invalid placement
        love.graphics.setColor(1, 0.3, 0.3, 0.2)
        love.graphics.rectangle("fill", 
            config.GRID_START_X + (gx - 1) * (config.CELL_SIZE+config.SPACING) - 4, 
            config.GRID_START_Y + (gy - 1) * (config.CELL_SIZE+config.SPACING) - 4, 
            dragging.w * (config.CELL_SIZE+config.SPACING) + 8, 
            dragging.h * (config.CELL_SIZE+config.SPACING) + 8, 6, 6)
    end
end

function render.drawTray(tray, dragging, blockCanvases, state)
    for _, p in ipairs(tray) do
        if not p.used and p ~= dragging then 
            local alpha = state == "GAMEOVER" and 0.4 or 1
            graphics.drawShape(p.shape, p.x, p.y, p.scale, p.colorIdx, alpha, blockCanvases)
        end
    end
    
    -- Desktop: dragging block follows mouse cursor directly, no offset
    if dragging then 
        graphics.drawShape(dragging.shape, dragging.x, dragging.y, 
            dragging.scale, dragging.colorIdx, 1, blockCanvases)
    end
end

function render.drawParticles()
    love.graphics.setBlendMode("add")
    for _, p in ipairs(effects.particles) do
        love.graphics.setColor(p.color[1], p.color[2], p.color[3], p.life * 2.5)
        love.graphics.rectangle("fill", p.x, p.y, 12, 12, 4, 4)
    end
    love.graphics.setBlendMode("alpha")
end

-- STATIC text - NO MOVEMENT, NO BOUNCE
function render.drawAmbientText(combo, ambientIndex, ambientTexts, fonts, state, dragging)
    if not dragging and state == "PLAYING" then
        local text = combo > 0 and "COMBO x"..combo or ambientTexts[ambientIndex]
        local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
        local isPastel = (themeIdx == 3)
        local ambientColor = isPastel and {0, 0, 0} or {1, 1, 1}
        
        -- Calculate position below tray, but ensure it's within window bounds
        local textY = config.TRAY_Y + math.floor(80 * config.scaleY)
        -- Clamp to window bounds
        textY = math.min(textY, config.WINDOW_H - math.floor(40 * config.scaleY))
        
        if combo > 0 then
            -- Combo text - STATIC
            render.drawTextWithStyle(
                text,
                0, textY,
                fonts.medium, "center",
                {color = {1, 0.85, 0.2}, shadow = true}
            )
        else
            -- Ambient text - STATIC
            render.drawTextWithStyle(
                text,
                0, textY,
                fonts.medium, "center",
                {color = ambientColor, shadow = true, alpha = 0.7}
            )
        end
    end
end

-- Floating texts - only scale/alpha fade, NO MOVEMENT
function render.drawFloatingTexts(fonts)
    for _, t in ipairs(effects.texts) do
        local alpha = math.min(1, t.life * 2)
        love.graphics.setFont(t.size)
        
        -- Shadow
        love.graphics.setColor(0, 0, 0, alpha * 0.4)
        love.graphics.printf(t.text, t.x - config.WINDOW_W/2 + 2, t.y + 2, config.WINDOW_W, "center")
        
        -- Main text
        love.graphics.setColor(t.color[1], t.color[2], t.color[3], alpha)
        love.graphics.printf(t.text, t.x - config.WINDOW_W/2, t.y, config.WINDOW_W, "center")
    end
end

-- Draw icon helper
function render.drawIcon(iconType, x, y, size, color, alpha)
    alpha = alpha or 1
    color = color or {1, 1, 1}
    love.graphics.setColor(color[1], color[2], color[3], alpha)
    
    if iconType == "sound" then
        -- Speaker icon
        love.graphics.rectangle("fill", x - size*0.3, y - size*0.4, size*0.2, size*0.8)
        love.graphics.polygon("fill", 
            x - size*0.1, y - size*0.5,
            x + size*0.2, y - size*0.3,
            x + size*0.2, y + size*0.3,
            x - size*0.1, y + size*0.5
        )
        -- Sound waves
        for i = 1, 2 do
            local waveX = x + size*0.25 + i * size*0.15
            love.graphics.arc("line", "open", waveX, y, size*0.15, -math.pi/4, math.pi/4, 4)
        end
    elseif iconType == "sound_off" then
        -- Speaker with X
        love.graphics.rectangle("fill", x - size*0.3, y - size*0.4, size*0.2, size*0.8)
        love.graphics.polygon("fill", 
            x - size*0.1, y - size*0.5,
            x + size*0.2, y - size*0.3,
            x + size*0.2, y + size*0.3,
            x - size*0.1, y + size*0.5
        )
        -- X line
        love.graphics.setLineWidth(3)
        love.graphics.line(x + size*0.3, y - size*0.3, x + size*0.6, y + size*0.3)
        love.graphics.setLineWidth(1)
    elseif iconType == "restart" then
        -- Circular arrow
        love.graphics.arc("line", "open", x, y, size*0.4, 0, math.pi * 1.5, 8)
        love.graphics.polygon("fill", 
            x + size*0.3, y - size*0.2,
            x + size*0.5, y,
            x + size*0.3, y + size*0.2
        )
    elseif iconType == "close" then
        -- X icon
        local lineWidth = math.max(2, math.floor(3 * config.scale))
        love.graphics.setLineWidth(lineWidth)
        love.graphics.line(x - size*0.3, y - size*0.3, x + size*0.3, y + size*0.3)
        love.graphics.line(x + size*0.3, y - size*0.3, x - size*0.3, y + size*0.3)
        love.graphics.setLineWidth(1)
    end
end

function render.drawButton(x, y, w, h, label, font, hoverScale, isActive)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local scale = hoverScale or 1.0
    local activeColor = isActive and themeUI.accent or {themeUI.popupBorder[1]*1.5, themeUI.popupBorder[2]*1.5, themeUI.popupBorder[3]*1.5}
    
    -- Apply hover scale
    if scale ~= 1.0 then
        w = w * scale
        h = h * scale
        x = x - (w * (scale - 1)) / 2
        y = y - (h * (scale - 1)) / 2
    end
    
    -- Button background - brighter
    local btnRadius = math.max(8, math.floor(12 * config.scale))
    love.graphics.setColor(activeColor[1], activeColor[2], activeColor[3], 0.98)
    love.graphics.rectangle("fill", x - w/2, y - h/2, w, h, btnRadius, btnRadius)
    
    -- Button border - simple
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", x - w/2, y - h/2, w, h, btnRadius, btnRadius)
    love.graphics.setLineWidth(1)
    
    -- Button text - centered both horizontally and vertically
    love.graphics.setFont(font)
    local textW = font:getWidth(label)
    local textH = font:getHeight()
    local textY = y - textH / 2
    
    -- Stronger shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6))
    love.graphics.printf(label, 0, textY + 2, config.WINDOW_W, "center")
    
    -- Main text - brighter
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], 1)
    love.graphics.printf(label, 0, textY, config.WINDOW_W, "center")
end

function render.drawGameOver(score, money, continueCost, fonts, hoverButton, transitionAlpha)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local alpha = transitionAlpha or 1
    local isPastel = (themeIdx == 3)
    
    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.92 * alpha)
    love.graphics.rectangle("fill", 0, 0, config.WINDOW_W, config.WINDOW_H)
    
    -- Title - STATIC
    render.drawTextWithStyle(
        "OUT OF MOVES",
        0, config.WINDOW_H/2 - 140,
        fonts.huge, "center",
        {color = themeUI.accent, shadow = true, alpha = alpha}
    )
    
    -- Score - STATIC
    local scoreColor = isPastel and {1, 1, 1} or themeUI.textMain
    render.drawTextWithStyle(
        "Score: " .. math.floor(score),
        0, config.WINDOW_H/2 - 60,
        fonts.medium, "center",
        {color = scoreColor, shadow = true, alpha = alpha}
    )
    
    -- Continue Button with Crying Icon
    local continueBtnX = config.WINDOW_W/2
    local continueBtnY = config.WINDOW_H/2 + 40 * config.scaleY
    local continueBtnW = 280 * config.scaleX
    local continueBtnH = 80 * config.scaleY
    local canAfford = money >= continueCost
    local isHovered = (hoverButton == 1)
    
    -- Hover scale effect
    local hoverScale = (isHovered and canAfford) and 1.05 or 1.0
    if hoverScale ~= 1.0 then
        continueBtnW = continueBtnW * hoverScale
        continueBtnH = continueBtnH * hoverScale
        continueBtnX = continueBtnX - (continueBtnW * (hoverScale - 1)) / 2
        continueBtnY = continueBtnY - (continueBtnH * (hoverScale - 1)) / 2
    end
    
    -- Button background
    local btnColor = canAfford and themeUI.accent or {0.4, 0.4, 0.4}
    love.graphics.setColor(btnColor[1], btnColor[2], btnColor[3], 0.95 * alpha)
    love.graphics.rectangle("fill", continueBtnX - continueBtnW/2, continueBtnY - continueBtnH/2, continueBtnW, continueBtnH, 12, 12)
    
    -- Inner highlight
    love.graphics.setColor(1, 1, 1, 0.2 * alpha)
    love.graphics.rectangle("fill", continueBtnX - continueBtnW/2 + 2, continueBtnY - continueBtnH/2 + 2, continueBtnW - 4, continueBtnH/2 - 2, 10, 10)
    
    -- Button border
    love.graphics.setColor(1, 1, 1, 0.5 * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", continueBtnX - continueBtnW/2, continueBtnY - continueBtnH/2, continueBtnW, continueBtnH, 12, 12)
    love.graphics.setLineWidth(1)
    
    -- Crying icon
    local cryingIcon = graphics.shopIcons["crying"]
    if cryingIcon then
        local iconSize = 40
        local iconX = continueBtnX - continueBtnW/2 + 30 * config.scaleX
        local iconY = continueBtnY
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(cryingIcon, iconX, iconY, 0, iconSize/cryingIcon:getWidth(), iconSize/cryingIcon:getHeight(), cryingIcon:getWidth()/2, cryingIcon:getHeight()/2)
    end
    
    -- Button text - "CONTINUE $X" on single line, dynamically sized to fit
    local continueText = "CONTINUE $" .. continueCost
    local textX = continueBtnX + (cryingIcon and 20 or 0)
    local textY = continueBtnY
    
    -- Try medium font first, fall back to small if needed
    love.graphics.setFont(fonts.medium)
    local textW = fonts.medium:getWidth(continueText)
    local availableWidth = continueBtnW - (cryingIcon and 50 or 20)  -- Account for icon space
    local useFont = fonts.medium
    if textW > availableWidth then
        useFont = fonts.small
        textW = fonts.small:getWidth(continueText)
    end
    
    love.graphics.setFont(useFont)
    local textH = useFont:getHeight()
    
    -- Text shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(continueText, textX - textW/2 + 2, textY - textH/2 + 2)
    
    -- Main text (white)
    love.graphics.setColor(1, 1, 1, (canAfford and 1.0 or 0.6) * alpha)
    love.graphics.print(continueText, textX - textW/2, textY - textH/2)
    
    -- Retry text - STATIC (below continue button)
    local retryColor = isPastel and {1, 1, 1} or {1, 1, 1} -- Keeping it white always, but explicitly showing the logic
    render.drawTextWithStyle(
        "Tap Anywhere Else to Retry",
        0, config.WINDOW_H/2 + 140,
        fonts.small, "center",
        {color = retryColor, shadow = true, alpha = alpha * 0.7}
    )
end

function render.drawSettings(audioEnabled, musicEnabled, fonts, hoverButton, transitionAlpha)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local alpha = transitionAlpha or 1
    
    -- Backdrop - simple dark
    love.graphics.setColor(0, 0, 0, 0.85 * alpha)
    love.graphics.rectangle("fill", 0, 0, config.WINDOW_W, config.WINDOW_H)
    
    -- Settings dialog box (matching hint/shop UI style)
    local dialogW = 400  -- Fixed width 400px (min and max both 400)
    local dialogH = 500  -- Fixed height 500px (min and max both 500)
    local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
    local dialogTop = dialogY - dialogH/2
    
    -- Dialog background - matching hint/shop style
    love.graphics.setColor(themeUI.popupBg[1], themeUI.popupBg[2], themeUI.popupBg[3], (themeUI.popupBg[4] or 0.98) * alpha)
    love.graphics.rectangle("fill", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    
    -- Dialog border - matching hint/shop style (simple, fixed)
    love.graphics.setColor(themeUI.popupBorder[1], themeUI.popupBorder[2], themeUI.popupBorder[3], (themeUI.popupBorder[4] or 0.8) * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    love.graphics.setLineWidth(1)
    
    -- Title - matching hint/shop style
    love.graphics.setFont(fonts.large)
    local titleText = "SETTINGS"
    local titleW = fonts.large:getWidth(titleText)
    local titleX = dialogX - titleW/2
    local titleY = dialogTop + 45  -- Match hint/shop style (dialogTop is already scaled)
    
    -- Shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(titleText, titleX + 3, titleY + 3)
    
    -- Main text
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
    love.graphics.print(titleText, titleX, titleY)
    
    -- Close button - matching shop UI style exactly
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local isPastel = (themeIdx == 3)
    local closeColor = isPastel and {0, 0, 0} or {1, 1, 1}
    local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25  -- Fixed position (no scaling)
    local closeIconSize = 22  -- Fixed size (no scaling)
    render.drawIcon("close", closeX, closeY, closeIconSize, closeColor, alpha)
    
    -- Audio section label - matching hint/shop style
    love.graphics.setFont(fonts.medium)
    local audioLabel = "AUDIO"
    local audioLabelX = dialogX - dialogW/2 + 30  -- Fixed position (no scaling)
    local audioLabelY = dialogTop + 85  -- Fixed position (no scaling)
    
    -- Stronger shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(audioLabel, audioLabelX + 2, audioLabelY + 2)
    
    -- Main text - brighter
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
    love.graphics.print(audioLabel, audioLabelX, audioLabelY)
    
    -- Sound toggle button - fixed size (no scaling) to match default window
    local soundBtnY = dialogTop + 153  -- Fixed position (no scaling)
    local soundHover = (hoverButton == 1)
    local btnW = 360  -- Fixed width (no scaling)
    local btnH = 60  -- Fixed height (no scaling)
    render.drawButton(
        dialogX, soundBtnY, btnW, btnH,
        audioEnabled and "SOUND: ON" or "SOUND: OFF",
        fonts.medium,
        soundHover and 1.05 or 1.0,
        audioEnabled
    )
    
    -- Music toggle button
    local musicBtnY = dialogTop + 223  -- Fixed position (no scaling)
    local musicHover = (hoverButton == 4)
    render.drawButton(
        dialogX, musicBtnY, btnW, btnH,
        musicEnabled and "MUSIC: ON" or "MUSIC: OFF",
        fonts.medium,
        musicHover and 1.05 or 1.0,
        musicEnabled
    )
    
    -- Action buttons
    local actionBtnPositions = { 
        dialogTop + 293,  -- Fixed position (no scaling)
        dialogTop + 363   -- Fixed position (no scaling)
    } 
    local buttonLabels = { "RESTART GAME", "RESUME" }
    
    for i, lbl in ipairs(buttonLabels) do
        local btnY = actionBtnPositions[i]
        local btnHover = (hoverButton == i + 1)
        render.drawButton(
            dialogX, btnY, btnW, btnH,
            lbl, fonts.medium,
            btnHover and 1.05 or 1.0,
            false
        )
    end
    
    -- Reset everything button - with spacing from bottom
    local resetBtnY = dialogTop + 433  -- Fixed position (no scaling)
    local resetHover = (hoverButton == 10)
    
    -- Custom render button with red color
    local hoverScale = resetHover and 1.05 or 1.0
    local resetBtnW = 360  -- Fixed width (no scaling)
    local resetBtnH = 55  -- Fixed height (no scaling)
    local curW, curH = resetBtnW * hoverScale, resetBtnH * hoverScale
    
    -- Button background with red accent
    love.graphics.setColor(0.9, 0.2, 0.2, 0.98)
    love.graphics.rectangle("fill", dialogX - curW/2, resetBtnY - curH/2, curW, curH, 12, 12)
    
    -- highlight
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("fill", dialogX - curW/2 + 2, resetBtnY - curH/2 + 2, curW - 4, curH/2 - 2, 10, 10)
    
    -- border
    love.graphics.setColor(1, 1, 1, 0.3)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", dialogX - curW/2, resetBtnY - curH/2, curW, curH, 12, 12)
    
    -- Text centering without icon
    love.graphics.setFont(fonts.medium)
    local resetText = "RESET EVERYTHING"
    local textW = fonts.medium:getWidth(resetText)
    local startX = dialogX - textW/2
    
    love.graphics.setColor(0, 0, 0, 0.6)
    love.graphics.print(resetText, startX + 2, resetBtnY - fonts.medium:getHeight()/2 + 2)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(resetText, startX, resetBtnY - fonts.medium:getHeight()/2)
end

function render.drawHintDialog(money, hintCost, fonts, hoverButton, transitionAlpha)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local alpha = transitionAlpha or 1
    
    -- Backdrop - simple dark
    love.graphics.setColor(0, 0, 0, 0.85 * alpha)
    love.graphics.rectangle("fill", 0, 0, config.WINDOW_W, config.WINDOW_H)
    
    -- Dialog box - Fixed size (no scaling)
    local dialogW = 375  -- Fixed width 375px
    local dialogH = 300  -- Fixed height 300px
    local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
    local dialogTop = dialogY - dialogH/2
    
    -- Dialog background - simple solid color
    love.graphics.setColor(themeUI.popupBg[1], themeUI.popupBg[2], themeUI.popupBg[3], (themeUI.popupBg[4] or 0.98) * alpha)
    local dialogRadius = 15  -- Fixed radius (no scaling)
    love.graphics.rectangle("fill", dialogX - dialogW/2, dialogTop, dialogW, dialogH, dialogRadius, dialogRadius)
    
    -- Dialog border - simple
    love.graphics.setColor(themeUI.popupBorder[1], themeUI.popupBorder[2], themeUI.popupBorder[3], (themeUI.popupBorder[4] or 0.8) * alpha)
    love.graphics.setLineWidth(2)  -- Fixed line width (no scaling)
    love.graphics.rectangle("line", dialogX - dialogW/2, dialogTop, dialogW, dialogH, dialogRadius, dialogRadius)
    love.graphics.setLineWidth(1)
    
    -- Title - enhanced
    love.graphics.setFont(fonts.large)
    local titleText = "USE HINT?"
    local titleW = fonts.large:getWidth(titleText)
    local titleH = fonts.large:getHeight()
    local titleX = dialogX - titleW/2
    local titleY = dialogTop + 45
    
    local isPastel = (themeIdx == 3)
    
    -- Stronger shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(titleText, titleX + 3, titleY + 3)
    
    -- Main text - brighter
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
    love.graphics.print(titleText, titleX, titleY)
    
    -- Cost text - enhanced
    love.graphics.setFont(fonts.medium)
    local costText = "COST: $" .. hintCost
    local costW = fonts.medium:getWidth(costText)
    local costX = dialogX - costW/2
    local costY = dialogTop + 105
    
    -- Shadow
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(costText, costX + 2, costY + 2)
    
    -- Main text - brighter
    local textColor = isPastel and themeUI.textMain or {1, 1, 1}
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], alpha)
    love.graphics.print("COST: $" .. hintCost, costX, costY)
    
    -- "You have" text
    love.graphics.setFont(fonts.small)
    local moneyText = "YOU HAVE: $" .. math.floor(money)
    local moneyW = fonts.small:getWidth(moneyText)
    local moneyX = dialogX - moneyW/2
    local moneyY = dialogTop + 145
    
    -- Shadow
    love.graphics.setColor(0, 0, 0, 0.6 * alpha)
    love.graphics.print(moneyText, moneyX + 2, moneyY + 2)
    
    -- Main text - brighter
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], alpha)
    love.graphics.print(moneyText, moneyX, moneyY)
    
    -- Buttons - enhanced
    local canAfford = money >= hintCost
    local buttonLabels = { "YES", "NO" }
    local buttonY = dialogTop + 240  -- Fixed position (no scaling)
    local buttonW, buttonH = 140, 60  -- Fixed sizes (no scaling)
    
    for i, lbl in ipairs(buttonLabels) do
        local btnX = dialogX + (i == 1 and -100 or 100)  -- Fixed position (no scaling)
        local btnHover = (hoverButton == i)
        local btnColor = (i == 1 and canAfford) and {100/255, 240/255, 130/255} or 
                        (i == 1) and {100/255, 100/255, 100/255} or {100/255, 180/255, 255/255}
        
        -- No hover glow - cleaner look
        
        -- Button background - brighter
        love.graphics.setColor(btnColor[1], btnColor[2], btnColor[3], 0.98)
        love.graphics.rectangle("fill", btnX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 12, 12)
        
        -- Inner highlight
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle("fill", btnX - buttonW/2 + 2, buttonY - buttonH/2 + 2, buttonW - 4, buttonH/2 - 2, 10, 10)
        
        -- Button border - simple
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btnX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 12, 12)
        love.graphics.setLineWidth(1)
        
        -- Button text
        love.graphics.setFont(fonts.medium)
        local textW = fonts.medium:getWidth(lbl)
        local textH = fonts.medium:getHeight()
        local textX = btnX - textW/2
        local textY = buttonY - textH/2
        
        -- Stronger shadow
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(lbl, textX + 2, textY + 2)
        
        -- Main text - brighter
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(lbl, textX, textY)
    end
end

function render.drawHintButton(money, hintCost, fonts, hover, shaderTime)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local btnW = render.clampSizeX(75, 65, 105)
    local btnH = render.clampSizeY(65, 55, 85)
    local btnX = math.max(50, 60 * config.scaleX)
    local btnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
    local canAfford = money >= hintCost
    
    -- Hover effect
    local hoverScale = hover and canAfford and 1.05 or 1.0
    if hover and canAfford then
        btnW = btnW * hoverScale
        btnH = btnH * hoverScale
        btnX = btnX - (btnW * (hoverScale - 1)) / 2
        btnY = btnY - (btnH * (hoverScale - 1)) / 2
    end
    
    -- Button background - greyish for all themes
    local btnRadius = math.max(8, math.floor(12 * config.scale))
    local bgColor = {0.5, 0.5, 0.5}
    love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.95)
    love.graphics.rectangle("fill", btnX - btnW/2, btnY - btnH/2, btnW, btnH, btnRadius, btnRadius)
    
    -- Inner highlight
    local highlightPadding = math.max(1, math.floor(2 * config.scale))
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("fill", btnX - btnW/2 + highlightPadding, btnY - btnH/2 + highlightPadding, btnW - highlightPadding*2, btnH/2 - highlightPadding, math.max(6, math.floor(10 * config.scale)), math.max(6, math.floor(10 * config.scale)))
    
    -- Button border - brighter
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(math.max(1, math.floor(2 * config.scale)))
    love.graphics.rectangle("line", btnX - btnW/2, btnY - btnH/2, btnW, btnH, btnRadius, btnRadius)
    love.graphics.setLineWidth(1)
    
    -- HINT text - larger and bolder (7px bigger)
    love.graphics.setFont(fonts.small)  -- Use small font instead of tiny
    local hintText = "HINT"
    local baseTextH = fonts.small:getHeight()
    local scaleFactor = (baseTextH + 7) / baseTextH
    local textW = fonts.small:getWidth(hintText) * scaleFactor
    local textH = baseTextH * scaleFactor
    local textX = btnX - textW/2
    local textY = btnY - textH/2
    
    -- Text shadow (stronger) - scaled
    love.graphics.push()
    love.graphics.translate(textX, textY)
    love.graphics.scale(scaleFactor, scaleFactor)
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6))
    love.graphics.print(hintText, 2/scaleFactor, 2/scaleFactor)
    love.graphics.pop()
    
    -- Main text - scaled
    love.graphics.push()
    love.graphics.translate(textX, textY)
    love.graphics.scale(scaleFactor, scaleFactor)
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], canAfford and 1.0 or 0.6)
    love.graphics.print(hintText, 0, 0)
    love.graphics.pop()
end

function render.drawShopButton(fonts, hover, shaderTime)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local btnW = render.clampSizeX(75, 65, 105)
    local btnH = render.clampSizeY(65, 55, 85)
    local btnX = config.WINDOW_W - math.max(50, 60 * config.scaleX)
    local btnY = config.GRID_START_Y + (config.GRID_SIZE * (config.CELL_SIZE + config.SPACING)) / 2
    
    -- Hover effect
    local hoverScale = hover and 1.05 or 1.0
    if hover then
        btnW = btnW * hoverScale
        btnH = btnH * hoverScale
        btnX = btnX - (btnW * (hoverScale - 1)) / 2
        btnY = btnY - (btnH * (hoverScale - 1)) / 2
    end
    
    -- Button background - vibrant green
    local btnRadius = math.max(8, math.floor(12 * config.scale))
    local bgColor = themeUI.accent
    love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.95)
    love.graphics.rectangle("fill", btnX - btnW/2, btnY - btnH/2, btnW, btnH, btnRadius, btnRadius)
    
    -- Inner highlight
    local highlightPadding = math.max(1, math.floor(2 * config.scale))
    love.graphics.setColor(1, 1, 1, 0.2)
    love.graphics.rectangle("fill", btnX - btnW/2 + highlightPadding, btnY - btnH/2 + highlightPadding, btnW - highlightPadding*2, btnH/2 - highlightPadding, math.max(6, math.floor(10 * config.scale)), math.max(6, math.floor(10 * config.scale)))
    
    -- Button border - brighter
    love.graphics.setColor(1, 1, 1, 0.5)
    love.graphics.setLineWidth(math.max(1, math.floor(2 * config.scale)))
    love.graphics.rectangle("line", btnX - btnW/2, btnY - btnH/2, btnW, btnH, btnRadius, btnRadius)
    love.graphics.setLineWidth(1)
    
    -- SHOP text - larger and bolder (7px bigger)
    love.graphics.setFont(fonts.small)  -- Use small font instead of tiny
    local shopText = "SHOP"
    local baseTextH = fonts.small:getHeight()
    local scaleFactor = (baseTextH + 7) / baseTextH
    local textW = fonts.small:getWidth(shopText) * scaleFactor
    local textH = baseTextH * scaleFactor
    local textX = btnX - textW/2
    local textY = btnY - textH/2
    
    -- Text shadow (stronger) - scaled
    love.graphics.push()
    love.graphics.translate(textX, textY)
    love.graphics.scale(scaleFactor, scaleFactor)
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6))
    love.graphics.print(shopText, 2/scaleFactor, 2/scaleFactor)
    love.graphics.pop()
    
    -- Main text - scaled
    love.graphics.push()
    love.graphics.translate(textX, textY)
    love.graphics.scale(scaleFactor, scaleFactor)
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], 1.0)
    love.graphics.print(shopText, 0, 0)
    love.graphics.pop()
end

function render.drawShopDialog(money, fonts, hoverButton, transitionAlpha)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local alpha = transitionAlpha or 1
    
    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.85 * alpha)
    love.graphics.rectangle("fill", 0, 0, config.WINDOW_W, config.WINDOW_H)
    
    -- Dialog box - Fixed size (no scaling)
    local dialogW = 475  -- Fixed width 475px (min and max both 475)
    local dialogH = 600  -- Fixed height 600px (min and max both 600)
    local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
    local dialogTop = dialogY - dialogH/2
    
    -- Dialog background
    love.graphics.setColor(themeUI.popupBg[1], themeUI.popupBg[2], themeUI.popupBg[3], (themeUI.popupBg[4] or 0.98) * alpha)
    love.graphics.rectangle("fill", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    
    -- Dialog border
    love.graphics.setColor(themeUI.popupBorder[1], themeUI.popupBorder[2], themeUI.popupBorder[3], (themeUI.popupBorder[4] or 0.8) * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    love.graphics.setLineWidth(1)
    
    -- Title
    love.graphics.setFont(fonts.large)
    local titleText = "SHOP"
    local titleW = fonts.large:getWidth(titleText)
    local titleX = dialogX - titleW/2
    local titleY = dialogTop + 45
    
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(titleText, titleX + 3, titleY + 3)
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
    love.graphics.print(titleText, titleX, titleY)
    
    -- Close button
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local isPastel = (themeIdx == 3)
    local closeColor = isPastel and {0, 0, 0} or {1, 1, 1}
    local closeX, closeY = dialogX + dialogW/2 - 35, dialogY - dialogH/2 + 25  -- Fixed position (no scaling)
    local closeIconSize = 22  -- Fixed size (no scaling)
    render.drawIcon("close", closeX, closeY, closeIconSize, closeColor, alpha)
    
    -- Money display
    love.graphics.setFont(fonts.medium)
    local moneyText = "MONEY: $" .. math.floor(money)
    local moneyW = fonts.medium:getWidth(moneyText)
    local moneyX = dialogX - moneyW/2
    local moneyY = dialogTop + 105
    
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(moneyText, moneyX + 2, moneyY + 2)
    love.graphics.setColor(themeUI.accent[1], themeUI.accent[2], themeUI.accent[3], alpha)
    love.graphics.print(moneyText, moneyX, moneyY)
    
    -- Apply scroll offset
    local scrollOffset = gameState.shopScrollOffset or 0
    local contentStartY = dialogTop + 155  -- Fixed position (no scaling)
    
    -- Show different content based on page
    local shopPage = gameState.shopPage or 1
    if shopPage == 1 then
        -- PAGE 1: Regular upgrades and themes
        -- UPGRADES Section
        love.graphics.setFont(fonts.small)
        local upgradesLabelY = contentStartY + scrollOffset
        
        -- UPGRADES title
        love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
        love.graphics.print("UPGRADES", dialogX - dialogW/2 + 30 + 2, upgradesLabelY + 2)  -- Fixed position (no scaling)
        love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
        love.graphics.print("UPGRADES", dialogX - dialogW/2 + 30, upgradesLabelY)  -- Fixed position (no scaling)
        
        -- NEXT button (same line as UPGRADES title, right-aligned)
        local nextPrevText = "NEXT"
        local nextPrevW = 70  -- Fixed width (no scaling)
        local nextPrevH = 32  -- Fixed height (no scaling)
        local nextPrevX = dialogX + dialogW/2 - 30 - nextPrevW/2  -- Fixed position (no scaling)
        local nextPrevY = upgradesLabelY + 5  -- Fixed position (no scaling)
        local isNextPrevHovered = (hoverButton == 100)  -- Use button ID 100 for NEXT/PREV
        
        local nextPrevColor = isNextPrevHovered and {100/255, 180/255, 255/255} or {100/255, 140/255, 200/255}
        love.graphics.setColor(nextPrevColor[1], nextPrevColor[2], nextPrevColor[3], 0.98 * alpha)
        love.graphics.rectangle("fill", nextPrevX - nextPrevW/2, nextPrevY - nextPrevH/2, nextPrevW, nextPrevH, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.3 * alpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", nextPrevX - nextPrevW/2, nextPrevY - nextPrevH/2, nextPrevW, nextPrevH, 8, 8)
        
        love.graphics.setFont(fonts.tiny)
        local nextPrevTextW = fonts.tiny:getWidth(nextPrevText)
        love.graphics.setColor(0, 0, 0, 0.6 * alpha)
        love.graphics.print(nextPrevText, nextPrevX - nextPrevTextW/2 + 1, nextPrevY - fonts.tiny:getHeight()/2 + 1)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(nextPrevText, nextPrevX - nextPrevTextW/2, nextPrevY - fonts.tiny:getHeight()/2)
    
    -- Draw upgrade items
    local upgradeOrder = {"moneyMagnet", "scoreBoost", "hintMaster", "comboKing"}
    local itemHeight = 50  -- Fixed height (no scaling)
    local iconSize = 32  -- Fixed size (no scaling)
    local iconX = dialogX - dialogW/2 + 30  -- Fixed position (no scaling)
    local buttonW = 80  -- Fixed width (no scaling)
    
    for i, upgradeId in ipairs(upgradeOrder) do
        local upgrade = config.UPGRADES[upgradeId]
        if not upgrade then break end  -- Skip if upgrade config missing
        
        local itemY = upgradesLabelY + 55 + (i - 1) * itemHeight  -- Fixed position (no scaling)
        local currentLevel = gameState.upgrades[upgradeId] or 0
        currentLevel = math.max(0, math.min(currentLevel, upgrade.maxLevel))  -- Clamp level
        local isMaxed = currentLevel >= upgrade.maxLevel
        local nextCost = isMaxed and nil or config.getUpgradeCost(upgradeId, currentLevel, gameState.premiumItems)
        local canAfford = nextCost and money >= nextCost
        local isHovered = (hoverButton == i)
        
        -- Item background on hover
        if isHovered then
            love.graphics.setColor(1, 1, 1, 0.1 * alpha)
            love.graphics.rectangle("fill", dialogX - dialogW/2 + 20, itemY - itemHeight/2, dialogW - 40, itemHeight, 8, 8)
        end
        
        -- Icon
        local icon = graphics.shopIcons[upgrade.icon]
        if icon then
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.draw(icon, iconX, itemY, 0, iconSize/icon:getWidth(), iconSize/icon:getHeight(), icon:getWidth()/2, icon:getHeight()/2)
        end
        
        -- Name and level
        local textX = iconX + iconSize/2 + 12
        love.graphics.setFont(fonts.small)
        local nameText = upgrade.name .. " LV " .. currentLevel .. "/" .. upgrade.maxLevel
        love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
        love.graphics.print(nameText, textX + 1, itemY - 14 + 1)
        love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
        love.graphics.print(nameText, textX, itemY - 14)
        
        -- Level info
        love.graphics.setFont(fonts.tiny)
        local levelText = "(" .. upgrade.description .. ")"
        love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.4) * alpha)
        love.graphics.print(levelText, textX + 1, itemY + 12 + 1)
        love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha * 0.8)
        love.graphics.print(levelText, textX, itemY + 12)
        
        -- Buy button
        local buttonX = dialogX + dialogW/2 - 30 - buttonW/2
        local buttonY = itemY
        local buttonH = 32
        local buttonText = ""
        local buttonColor = {0.4, 0.4, 0.4}
        
        if isMaxed then
            buttonText = "MAXED"
            buttonColor = {0.5, 0.5, 0.5}
        elseif nextCost then
            buttonText = "$" .. nextCost
            buttonColor = canAfford and {100/255, 240/255, 130/255} or {0.4, 0.4, 0.4}
        end
        
        local hoverScale = (isHovered and not isMaxed and canAfford) and 1.05 or 1.0
        if hoverScale ~= 1.0 then
            buttonW = buttonW * hoverScale
            buttonH = buttonH * hoverScale
            buttonX = buttonX - (buttonW * (hoverScale - 1)) / 2
            buttonY = buttonY - (buttonH * (hoverScale - 1)) / 2
        end
        
        love.graphics.setColor(buttonColor[1], buttonColor[2], buttonColor[3], 0.98 * alpha)
        love.graphics.rectangle("fill", buttonX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.3 * alpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", buttonX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 8, 8)
        
        love.graphics.setFont(fonts.tiny)
        local btnTextW = fonts.tiny:getWidth(buttonText)
        love.graphics.setColor(0, 0, 0, 0.6 * alpha)
        love.graphics.print(buttonText, buttonX - btnTextW/2 + 1, buttonY - fonts.tiny:getHeight()/2 + 1)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(buttonText, buttonX - btnTextW/2, buttonY - fonts.tiny:getHeight()/2)
    end
    
    -- THEMES Section - Adjusted spacing to fit 600px height
    local themesLabelY = upgradesLabelY + 55 + (#upgradeOrder * itemHeight) + 20  -- Reduced spacing from 30 to 20
    love.graphics.setFont(fonts.small)
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print("THEMES", dialogX - dialogW/2 + 30 + 2, themesLabelY + 2)  -- Fixed position (no scaling)
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
    love.graphics.print("THEMES", dialogX - dialogW/2 + 30, themesLabelY)  -- Fixed position (no scaling)
    
    -- Themes section - Card layout (adjusted spacing to prevent overlap with label)
    -- Cards are centered at themesStartY, so top is at themesStartY - 50 (cardH/2)
    -- Need enough space for label height (~25px) + padding, so themesStartY should be themesLabelY + 80+
    local themesStartY = themesLabelY + 82  -- Ensures cards don't overlap label, +2px extra spacing
    local themesMap = {
        { id = "classic", name = "CLASSIC", price = config.getThemeCost("classic", gameState.premiumItems), idx = 1 },
        { id = "neon", name = "NEON", price = config.getThemeCost("neon", gameState.premiumItems), idx = 2 },
        { id = "pastel", name = "PASTEL", price = config.getThemeCost("pastel", gameState.premiumItems), idx = 3 },
        { id = "ocean", name = "OCEAN", price = config.getThemeCost("ocean", gameState.premiumItems), idx = 4 }
    }
    
    local cardW = 85  -- Fixed width (no scaling)
    local cardH = 100  -- Fixed height (no scaling)
    local cardSpacing = 15  -- Fixed spacing (no scaling)
    local startX = dialogX - (cardW * 1.5 + cardSpacing * 1.5)  -- Fixed position (no scaling)
    
    for i, theme in ipairs(themesMap) do
        local cardX = startX + (i - 1) * (cardW + cardSpacing)
        local cardY = themesStartY
        local isHovered = (hoverButton == i + 5) -- 6, 7, 8, 9 for themes
        local isOwned = gameState.themes[theme.id] or (theme.id == "classic")
        local isEquipped = gameState.activeTheme == theme.id
        local canAfford = money >= theme.price
        
        -- Hover scale
        local scale = (isHovered and not isEquipped and (isOwned or canAfford)) and 1.05 or 1.0
        local cx, cy, cw, ch = cardX, cardY, cardW, cardH
        if scale ~= 1.0 then
            cw = cw * scale
            ch = ch * scale
            cx = cx - (cw * (scale - 1)) / 2
            cy = cy - (ch * (scale - 1)) / 2
        end
        
        -- Card background
        local bgColor = isEquipped and {100/255, 240/255, 130/255} or 
                        isOwned and {100/255, 180/255, 255/255} or
                        canAfford and {180/255, 180/255, 180/255} or
                        {80/255, 80/255, 80/255}
                        
        love.graphics.setColor(bgColor[1], bgColor[2], bgColor[3], 0.98 * alpha)
        love.graphics.rectangle("fill", cx - cw/2, cy - ch/2, cw, ch, 12, 12)
        
        -- Inner highlight
        love.graphics.setColor(1, 1, 1, 0.2 * alpha)
        love.graphics.rectangle("fill", cx - cw/2 + 2, cy - ch/2 + 2, cw - 4, ch/2 - 2, 10, 10)
        
        -- Card border
        love.graphics.setColor(1, 1, 1, (isEquipped and 0.8 or 0.3) * alpha)
        love.graphics.setLineWidth(isEquipped and 3 or 1)
        love.graphics.rectangle("line", cx - cw/2, cy - ch/2, cw, ch, 12, 12)
        love.graphics.setLineWidth(1)
        
        -- Theme Name
        love.graphics.setFont(fonts.small)
        local nameW = fonts.small:getWidth(theme.name)
        love.graphics.setColor(0, 0, 0, 0.6 * alpha)
        love.graphics.print(theme.name, cx - nameW/2 + 2, cy - ch/2 + 10 + 2)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(theme.name, cx - nameW/2, cy - ch/2 + 10)
        
        -- Mini Palette Preview
        local palette = config.THEMES[theme.idx].palette
        local blockW, blockH = 18, 18
        local pStartX = cx - (blockW * 3 + 8) / 2
        local pY = cy - 5
        
        for p = 1, 3 do
            local pX = pStartX + (p - 1) * (blockW + 4)
            love.graphics.setColor(palette[p][1], palette[p][2], palette[p][3], alpha)
            love.graphics.rectangle("fill", pX, pY, blockW, blockH, 3, 3)
            love.graphics.setColor(1, 1, 1, 0.5 * alpha)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", pX, pY, blockW, blockH, 3, 3)
        end
        
        -- Price / Status
        love.graphics.setFont(fonts.tiny)
        local statusText = ""
        local statusColor = {1, 1, 1}
        
        if isEquipped then
            statusText = "EQUIPPED"
            statusColor = {255/255, 255/255, 0/255}
        elseif isOwned then
            statusText = "SELECT"
        else
            statusText = "$" .. theme.price
            statusColor = canAfford and {255/255, 220/255, 0/255} or {1, 0.5, 0.5}
        end
        
        local statW = fonts.tiny:getWidth(statusText)
        love.graphics.setColor(0, 0, 0, 0.8 * alpha)
        love.graphics.print(statusText, cx - statW/2 + 1, cy + ch/2 - 25 + 1)
        love.graphics.setColor(statusColor[1], statusColor[2], statusColor[3], alpha)
        love.graphics.print(statusText, cx - statW/2, cy + ch/2 - 25)
    end
    elseif shopPage == 2 then
        -- PAGE 2: Gameplay upgrades
        local gameplayUpgradeOrder = {"rowBlast", "columnBlast", "colorWipe"}
        local itemHeight = 50  -- Fixed height (no scaling)
        local iconSize = 32  -- Fixed size (no scaling)
        local iconX = dialogX - dialogW/2 + 30  -- Fixed position (no scaling)
        local buttonW = 80  -- Fixed width (no scaling)
        local gameplayLabelY = contentStartY + scrollOffset
        
        -- GAMEPLAY UPGRADES title
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
        love.graphics.print("GAMEPLAY UPGRADES", dialogX - dialogW/2 + 30 + 2, gameplayLabelY + 2)
        love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
        love.graphics.print("GAMEPLAY UPGRADES", dialogX - dialogW/2 + 30, gameplayLabelY)
        
        -- PREV button (same line as GAMEPLAY UPGRADES title, right-aligned)
        local nextPrevText = "PREV"
        local nextPrevW = 70  -- Fixed width (no scaling)
        local nextPrevH = 32  -- Fixed height (no scaling)
        local nextPrevX = dialogX + dialogW/2 - 30 - nextPrevW/2  -- Fixed position (no scaling)
        local nextPrevY = gameplayLabelY + 5  -- Fixed position (no scaling)
        local isNextPrevHovered = (hoverButton == 100)  -- Use button ID 100 for NEXT/PREV
        
        local nextPrevColor = isNextPrevHovered and {100/255, 180/255, 255/255} or {100/255, 140/255, 200/255}
        love.graphics.setColor(nextPrevColor[1], nextPrevColor[2], nextPrevColor[3], 0.98 * alpha)
        love.graphics.rectangle("fill", nextPrevX - nextPrevW/2, nextPrevY - nextPrevH/2, nextPrevW, nextPrevH, 8, 8)
        love.graphics.setColor(1, 1, 1, 0.3 * alpha)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", nextPrevX - nextPrevW/2, nextPrevY - nextPrevH/2, nextPrevW, nextPrevH, 8, 8)
        
        love.graphics.setFont(fonts.tiny)
        local nextPrevTextW = fonts.tiny:getWidth(nextPrevText)
        love.graphics.setColor(0, 0, 0, 0.6 * alpha)
        love.graphics.print(nextPrevText, nextPrevX - nextPrevTextW/2 + 1, nextPrevY - fonts.tiny:getHeight()/2 + 1)
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.print(nextPrevText, nextPrevX - nextPrevTextW/2, nextPrevY - fonts.tiny:getHeight()/2)
        
        for i, upgradeId in ipairs(gameplayUpgradeOrder) do
            local upgrade = config.UPGRADES[upgradeId]
            if not upgrade then break end
            
            local itemY = gameplayLabelY + 55 + (i - 1) * itemHeight
            local currentLevel = gameState.upgrades[upgradeId] or 0
            currentLevel = math.max(0, math.min(currentLevel, upgrade.maxLevel))
            local isMaxed = currentLevel >= upgrade.maxLevel
            local nextCost = isMaxed and nil or config.getUpgradeCost(upgradeId, currentLevel, gameState.premiumItems)
            local canAfford = nextCost and money >= nextCost
            local isHovered = (hoverButton == i + 10)  -- 11, 12, 13 for gameplay upgrades
            
            -- Item background on hover
            if isHovered then
                love.graphics.setColor(1, 1, 1, 0.1 * alpha)
                love.graphics.rectangle("fill", dialogX - dialogW/2 + 20, itemY - itemHeight/2, dialogW - 40, itemHeight, 8, 8)
            end
            
            -- Icon
            local icon = graphics.shopIcons[upgrade.icon]
            if icon then
                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.draw(icon, iconX, itemY, 0, iconSize/icon:getWidth(), iconSize/icon:getHeight(), icon:getWidth()/2, icon:getHeight()/2)
            end
            
            -- Name (no level display for gameplay upgrades)
            local textX = iconX + iconSize/2 + 12
            love.graphics.setFont(fonts.small)
            local nameText = upgrade.name
            love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
            love.graphics.print(nameText, textX + 1, itemY - 14 + 1)
            love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
            love.graphics.print(nameText, textX, itemY - 14)
            
            -- Description
            love.graphics.setFont(fonts.tiny)
            local descText = "(" .. upgrade.description .. ")"
            love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.4) * alpha)
            love.graphics.print(descText, textX + 1, itemY + 12 + 1)
            love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha * 0.8)
            love.graphics.print(descText, textX, itemY + 12)
            
            -- Buy button
            local buttonX = dialogX + dialogW/2 - 30 - buttonW/2
            local buttonY = itemY
            local buttonH = 32
            local buttonText = ""
            local buttonColor = {0.4, 0.4, 0.4}
            
            if nextCost then
                buttonText = "$" .. nextCost
                buttonColor = canAfford and {255/255, 200/255, 0/255} or {0.4, 0.4, 0.4}  -- Gold color for gameplay upgrades
            end
            
            local hoverScale = (isHovered and not isMaxed and canAfford) and 1.05 or 1.0
            local btnW = buttonW
            local btnH = buttonH
            local btnX = buttonX
            local btnY = buttonY
            if hoverScale ~= 1.0 then
                btnW = btnW * hoverScale
                btnH = btnH * hoverScale
                btnX = btnX - (btnW * (hoverScale - 1)) / 2
                btnY = btnY - (btnH * (hoverScale - 1)) / 2
            end
            
            love.graphics.setColor(buttonColor[1], buttonColor[2], buttonColor[3], 0.98 * alpha)
            love.graphics.rectangle("fill", btnX - btnW/2, btnY - btnH/2, btnW, btnH, 8, 8)
            love.graphics.setColor(1, 1, 1, 0.3 * alpha)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", btnX - btnW/2, btnY - btnH/2, btnW, btnH, 8, 8)
            
            love.graphics.setFont(fonts.tiny)
            local btnTextW = fonts.tiny:getWidth(buttonText)
            love.graphics.setColor(0, 0, 0, 0.6 * alpha)
            love.graphics.print(buttonText, btnX - btnTextW/2 + 1, btnY - fonts.tiny:getHeight()/2 + 1)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.print(buttonText, btnX - btnTextW/2, btnY - fonts.tiny:getHeight()/2)
        end
        
        -- PREMIUM ITEMS section (Moved from Page 3)
        local premiumOrder = {
            {id = "unlimited_lives", name = "Unlimited Lives", icon = "lives", cost = "$4.99", desc = "(Never run out of lives again)"},
            {id = "unlimited_hints", name = "Unlimited Hints", icon = "hints", cost = "$4.99", desc = "(Endless puzzle assistance)"},
            {id = "unlock_everything", name = "Unlock Everything", icon = "unlock", cost = "$4.99", desc = "(UNLOCKS EVERYTHING...)"}
        }
        
        local pItemHeight = 60  -- Fixed height (no scaling)
        local pIconSize = 40  -- Fixed size (no scaling)
        local pIconX = dialogX - dialogW/2 + 35  -- Fixed position (no scaling)
        local pButtonW = 80  -- Fixed width (no scaling)
        local premiumLabelY = gameplayLabelY + 55 + (#gameplayUpgradeOrder * itemHeight) + 20
        
        -- PREMIUM ITEMS title
        love.graphics.setFont(fonts.small)
        love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
        love.graphics.print("PREMIUM ITEMS", dialogX - dialogW/2 + 30 + 2, premiumLabelY + 2)
        love.graphics.setColor(themeUI.accent[1], themeUI.accent[2], themeUI.accent[3], alpha)
        love.graphics.print("PREMIUM ITEMS", dialogX - dialogW/2 + 30, premiumLabelY)
        
        for i, item in ipairs(premiumOrder) do
            local itemY = premiumLabelY + 55 + (i - 1) * pItemHeight
            local isHovered = (hoverButton == i + 20)  -- 21, 22, 23
            
            -- Item background on hover
            if isHovered then
                love.graphics.setColor(1, 1, 1, 0.1 * alpha)
                love.graphics.rectangle("fill", dialogX - dialogW/2 + 20, itemY - pItemHeight/2, dialogW - 40, pItemHeight, 8, 8)
            end
            
            -- Icon
            local icon = graphics.shopIcons[item.icon]
            if icon then
                love.graphics.setColor(1, 1, 1, alpha)
                love.graphics.draw(icon, pIconX, itemY, 0, pIconSize/icon:getWidth(), pIconSize/icon:getHeight(), icon:getWidth()/2, icon:getHeight()/2)
            end
            
            -- Name
            local textX = pIconX + pIconSize/2 + 15
            love.graphics.setFont(fonts.small)
            love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
            love.graphics.print(item.name, textX + 1, itemY - 14 + 1)
            love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
            love.graphics.print(item.name, textX, itemY - 14)
            
            -- Description
            love.graphics.setFont(fonts.tiny)
            love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.4) * alpha)
            love.graphics.print(item.desc, textX + 1, itemY + 12 + 1)
            love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha * 0.8)
            love.graphics.print(item.desc, textX, itemY + 12)
            
            -- Buy button
            local buttonX = dialogX + dialogW/2 - 30 - pButtonW/2
            local buttonY = itemY
            local buttonH = 32
            
            local buttonColor = {200/255, 60/255, 60/255}
            
            local hoverScale = isHovered and 1.05 or 1.0
            local btnW = pButtonW
            local btnH = buttonH
            local btnX = buttonX
            local btnY = buttonY
            if hoverScale ~= 1.0 then
                btnW = btnW * hoverScale
                btnH = btnH * hoverScale
                btnX = btnX - (btnW * (hoverScale - 1)) / 2
                btnY = btnY - (btnH * (hoverScale - 1)) / 2
            end
            
            love.graphics.setColor(buttonColor[1], buttonColor[2], buttonColor[3], 0.98 * alpha)
            love.graphics.rectangle("fill", btnX - btnW/2, btnY - btnH/2, btnW, btnH, 8, 8)
            love.graphics.setColor(1, 1, 1, 0.4 * alpha)
            love.graphics.setLineWidth(1)
            love.graphics.rectangle("line", btnX - btnW/2, btnY - btnH/2, btnW, btnH, 8, 8)
            
            love.graphics.setFont(fonts.tiny)
            -- Check if item is purchased
            local isPurchased = gameState.premiumItems[item.id] or false
            local buttonText = isPurchased and "PAID" or item.cost
            local btnTextW = fonts.tiny:getWidth(buttonText)
            love.graphics.setColor(0, 0, 0, 0.6 * alpha)
            love.graphics.print(buttonText, btnX - btnTextW/2 + 1, btnY - fonts.tiny:getHeight()/2 + 1)
            love.graphics.setColor(1, 1, 1, alpha)
            love.graphics.print(buttonText, btnX - btnTextW/2, btnY - fonts.tiny:getHeight()/2)
        end
    end
    
    -- Support Dev Footer Button - Positioned at bottom right of screen
    local footerW = 220  -- Fixed width (no scaling)
    local footerH = 45  -- Fixed height (no scaling)
    local footerX = config.WINDOW_W - 120  -- Fixed position (no scaling)
    local footerY = config.WINDOW_H - 60  -- Fixed position (no scaling)
    local isFooterHovered = (hoverButton == 50)
    
    local footerColor = {50/255, 120/255, 200/255}
    
    local fHoverScale = isFooterHovered and 1.05 or 1.0
    local fBtnW = footerW
    local fBtnH = footerH
    local fBtnX = footerX
    local fBtnY = footerY
    if fHoverScale ~= 1.0 then
        fBtnW = fBtnW * fHoverScale
        fBtnH = fBtnH * fHoverScale
        fBtnX = fBtnX - (fBtnW * (fHoverScale - 1)) / 2
        fBtnY = fBtnY - (fBtnH * (fHoverScale - 1)) / 2
    end
    
    love.graphics.setColor(footerColor[1], footerColor[2], footerColor[3], 0.98 * alpha)
    love.graphics.rectangle("fill", fBtnX - fBtnW/2, fBtnY - fBtnH/2, fBtnW, fBtnH, 10, 10)
    love.graphics.setColor(1, 1, 1, 0.4 * alpha)
    love.graphics.setLineWidth(1)
    love.graphics.rectangle("line", fBtnX - fBtnW/2, fBtnY - fBtnH/2, fBtnW, fBtnH, 10, 10)
    
    love.graphics.setFont(fonts.small)
    local footerText = "SUPPORT THE DEV"
    local fTextW = fonts.small:getWidth(footerText)
    
    local heartIcon = graphics.shopIcons.heart
    local iconSize = 24
    local iconSpacing = 8
    
    local totalW = fTextW
    if heartIcon then
        totalW = totalW + iconSize + iconSpacing
    end
    
    local startX = fBtnX - totalW/2
    
    -- Draw text
    love.graphics.setColor(0, 0, 0, 0.6 * alpha)
    love.graphics.print(footerText, startX + 1, fBtnY - fonts.small:getHeight()/2 + 1)
    love.graphics.setColor(1, 1, 1, alpha)
    love.graphics.print(footerText, startX, fBtnY - fonts.small:getHeight()/2)
    
    -- Draw heart icon right of text
    if heartIcon then
        local heartX = startX + fTextW + iconSpacing + (iconSize/2) - 3
        local heartY = fBtnY - 2
        love.graphics.setColor(1, 1, 1, alpha)
        love.graphics.draw(heartIcon, heartX, heartY, 0, iconSize/heartIcon:getWidth(), iconSize/heartIcon:getHeight(), heartIcon:getWidth()/2, heartIcon:getHeight()/2)
    end
end

function render.drawRealMoneyDialog(itemName, itemCost, fonts, hoverButton, transitionAlpha)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local alpha = transitionAlpha or 1
    local isPastel = (themeIdx == 3)
    
    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.85 * alpha)
    love.graphics.rectangle("fill", 0, 0, config.WINDOW_W, config.WINDOW_H)
    
    -- Dialog box
    local dialogW, dialogH = 400, 320
    local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
    local dialogTop = dialogY - dialogH/2
    
    -- Dialog background
    love.graphics.setColor(themeUI.popupBg[1], themeUI.popupBg[2], themeUI.popupBg[3], (themeUI.popupBg[4] or 0.98) * alpha)
    love.graphics.rectangle("fill", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    
    -- Dialog border
    love.graphics.setColor(themeUI.popupBorder[1], themeUI.popupBorder[2], themeUI.popupBorder[3], (themeUI.popupBorder[4] or 0.8) * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    love.graphics.setLineWidth(1)
    
    -- Title
    love.graphics.setFont(fonts.large)
    local titleText = "CONFIRM PURCHASE"
    local titleW = fonts.large:getWidth(titleText)
    local titleX = dialogX - titleW/2
    local titleY = dialogTop + 45
    
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(titleText, titleX + 3, titleY + 3)
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
    love.graphics.print(titleText, titleX, titleY)
    
    -- Item Name Text
    love.graphics.setFont(fonts.medium)
    local nameText = itemName
    local nameW = fonts.medium:getWidth(nameText)
    local nameX = dialogX - nameW/2
    local nameY = dialogTop + 105
    
    local textColor = isPastel and themeUI.textMain or {1, 1, 1}
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(nameText, nameX + 2, nameY + 2)
    love.graphics.setColor(textColor[1], textColor[2], textColor[3], alpha)
    love.graphics.print(nameText, nameX, nameY)
    
    -- Cost text
    love.graphics.setFont(fonts.small)
    local costText = "COST: " .. itemCost
    local costW = fonts.small:getWidth(costText)
    local costX = dialogX - costW/2
    local costY = dialogTop + 155
    
    love.graphics.setColor(0, 0, 0, 0.6 * alpha)
    love.graphics.print(costText, costX + 2, costY + 2)
    love.graphics.setColor(themeUI.accent[1], themeUI.accent[2], themeUI.accent[3], alpha)
    love.graphics.print(costText, costX, costY)
    
    -- Buttons
    local buttonLabels = { "YES", "NO" }
    local buttonY = dialogTop + 240 * config.scaleY
    local buttonW, buttonH = render.clampSizeX(140, 110, 200), render.clampSizeY(60, 50, 80)
    
    for i, lbl in ipairs(buttonLabels) do
        local btnX = dialogX + (i == 1 and -100 * config.scaleX or 100 * config.scaleX)
        local btnHover = (hoverButton == i)
        local btnColor = (i == 1) and {100/255, 240/255, 130/255} or {100/255, 180/255, 255/255}
        
        love.graphics.setColor(btnColor[1], btnColor[2], btnColor[3], 0.98)
        love.graphics.rectangle("fill", btnX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 12, 12)
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle("fill", btnX - buttonW/2 + 2, buttonY - buttonH/2 + 2, buttonW - 4, buttonH/2 - 2, 10, 10)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btnX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 12, 12)
        love.graphics.setLineWidth(1)
        
        love.graphics.setFont(fonts.medium)
        local textW = fonts.medium:getWidth(lbl)
        local textH = fonts.medium:getHeight()
        local textX = btnX - textW/2
        local textY = buttonY - textH/2
        
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(lbl, textX + 2, textY + 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(lbl, textX, textY)
    end
end

function render.drawHintIndicator(hintPos, tray, blockCanvases, timer)
    if not hintPos or not tray[hintPos.pieceIndex] then return end
    
    local piece = tray[hintPos.pieceIndex]
    if piece.used then return end
    
    local hintX = config.GRID_START_X + (hintPos.x - 1) * (config.CELL_SIZE + config.SPACING) + 
                  (piece.w * (config.CELL_SIZE + config.SPACING)) / 2
    local hintY = config.GRID_START_Y + (hintPos.y - 1) * (config.CELL_SIZE + config.SPACING) + 
                  (piece.h * (config.CELL_SIZE + config.SPACING)) / 2
    
    -- Pulsing glow effect
    local pulse = 0.5 + math.sin(timer * 10) * 0.3
    
    -- Outer glow
    love.graphics.setBlendMode("add")
    love.graphics.setColor(1, 1, 0.5, pulse * 0.4)
    graphics.drawShape(piece.shape, hintX, hintY, 1.1, piece.colorIdx, 0.6, blockCanvases)
    love.graphics.setBlendMode("alpha")
    
    -- Highlight border
    love.graphics.setColor(1, 1, 0.2, pulse)
    love.graphics.setLineWidth(3)
    local borderX = config.GRID_START_X + (hintPos.x - 1) * (config.CELL_SIZE + config.SPACING) - 4
    local borderY = config.GRID_START_Y + (hintPos.y - 1) * (config.CELL_SIZE + config.SPACING) - 4
    love.graphics.rectangle("line", borderX, borderY, 
        piece.w * (config.CELL_SIZE + config.SPACING) + 8, 
        piece.h * (config.CELL_SIZE + config.SPACING) + 8, 6, 6)
    love.graphics.setLineWidth(1)
    
    -- Draw the piece outline
    graphics.drawShape(piece.shape, hintX, hintY, 1.0, piece.colorIdx, 0.8, blockCanvases)
end

function render.drawResetConfirmDialog(fonts, hoverButton, transitionAlpha)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local themeUI = config.THEMES[themeIdx].ui
    local alpha = transitionAlpha or 1
    
    -- Backdrop
    love.graphics.setColor(0, 0, 0, 0.85 * alpha)
    love.graphics.rectangle("fill", 0, 0, config.WINDOW_W, config.WINDOW_H)
    
    -- Dialog box (scaled with min/max constraints)
    local dialogW = render.clampSizeX(400, 320, 580)
    local dialogH = render.clampSizeY(320, 250, 450)
    local dialogX, dialogY = config.WINDOW_W/2, config.WINDOW_H/2
    local dialogTop = dialogY - dialogH/2
    
    -- Dialog background
    love.graphics.setColor(themeUI.popupBg[1], themeUI.popupBg[2], themeUI.popupBg[3], (themeUI.popupBg[4] or 0.98) * alpha)
    love.graphics.rectangle("fill", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    
    -- Dialog border
    love.graphics.setColor(themeUI.popupBorder[1], themeUI.popupBorder[2], themeUI.popupBorder[3], (themeUI.popupBorder[4] or 0.8) * alpha)
    love.graphics.setLineWidth(2)
    love.graphics.rectangle("line", dialogX - dialogW/2, dialogTop, dialogW, dialogH, 15, 15)
    love.graphics.setLineWidth(1)
    
    -- Title
    love.graphics.setFont(fonts.large)
    local titleText = "RESET EVERYTHING?"
    local titleW = fonts.large:getWidth(titleText)
    local titleX = dialogX - titleW/2
    local titleY = dialogTop + 45
    
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(titleText, titleX + 3, titleY + 3)
    love.graphics.setColor(themeUI.textMain[1], themeUI.textMain[2], themeUI.textMain[3], alpha)
    love.graphics.print(titleText, titleX, titleY)
    
    -- Warning Text
    love.graphics.setFont(fonts.medium)
    local warnText = "This action cannot"
    local warnW = fonts.medium:getWidth(warnText)
    local warnX = dialogX - warnW/2
    local warnY = dialogTop + 105
    
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(warnText, warnX + 2, warnY + 2)
    love.graphics.setColor(0.9, 0.2, 0.2, alpha)
    love.graphics.print(warnText, warnX, warnY)
    
    local warnText2 = "be undone!"
    local warnW2 = fonts.medium:getWidth(warnText2)
    local warnX2 = dialogX - warnW2/2
    local warnY2 = dialogTop + 145
    
    love.graphics.setColor(themeUI.textShadow[1], themeUI.textShadow[2], themeUI.textShadow[3], (themeUI.textShadow[4] or 0.6) * alpha)
    love.graphics.print(warnText2, warnX2 + 2, warnY2 + 2)
    love.graphics.setColor(0.9, 0.2, 0.2, alpha)
    love.graphics.print(warnText2, warnX2, warnY2)
    
    -- Buttons
    local buttonLabels = { "YES", "NO" }
    local buttonY = dialogTop + 240 * config.scaleY
    local buttonW, buttonH = render.clampSizeX(140, 110, 200), render.clampSizeY(60, 50, 80)
    
    for i, lbl in ipairs(buttonLabels) do
        local btnX = dialogX + (i == 1 and -100 * config.scaleX or 100 * config.scaleX)
        local btnColor = (i == 1) and {100/255, 240/255, 130/255} or {100/255, 180/255, 255/255}
        
        love.graphics.setColor(btnColor[1], btnColor[2], btnColor[3], 0.98)
        love.graphics.rectangle("fill", btnX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 12, 12)
        love.graphics.setColor(1, 1, 1, 0.25)
        love.graphics.rectangle("fill", btnX - buttonW/2 + 2, buttonY - buttonH/2 + 2, buttonW - 4, buttonH/2 - 2, 10, 10)
        love.graphics.setColor(1, 1, 1, 0.3)
        love.graphics.setLineWidth(1)
        love.graphics.rectangle("line", btnX - buttonW/2, buttonY - buttonH/2, buttonW, buttonH, 12, 12)
        love.graphics.setLineWidth(1)
        
        love.graphics.setFont(fonts.medium)
        local textW = fonts.medium:getWidth(lbl)
        local textH = fonts.medium:getHeight()
        local textX = btnX - textW/2
        local textY = buttonY - textH/2
        
        love.graphics.setColor(0, 0, 0, 0.6)
        love.graphics.print(lbl, textX + 2, textY + 2)
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.print(lbl, textX, textY)
    end
end

return render
