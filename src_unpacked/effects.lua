-- Visual Effects System

local effects = {}
local config = require("config")
local gameState = require("game_state")

effects.particles = {}
effects.texts = {}
effects.animations = {}
effects.lasers = {}

function effects.fireLaser(x, y, w, h)
    table.insert(effects.lasers, {x=x, y=y, w=w, h=h, life=1.0})
end

function effects.spawnParticles(x, y, colorIdx)
    local themeIdx = config.getThemeIndex(gameState.activeTheme or gameState.currentTheme or "classic")
    local c = config.THEMES[themeIdx].palette[colorIdx]
    for _ = 1, 6 do
        table.insert(effects.particles, {
            x = x + config.CELL_SIZE/2, 
            y = y + config.CELL_SIZE/2,
            vx = love.math.random(-200, 200), 
            vy = love.math.random(-300, 0),
            life = love.math.random(40, 90) / 100, 
            color = c
        })
    end
end

function effects.popText(msg, x, y, size, color, fonts)
    table.insert(effects.texts, { 
        text = msg, 
        x = x, 
        y = y, 
        life = 1.5, 
        size = size or (fonts and fonts.large or nil), 
        color = color or {1,1,1} 
    })
end

function effects.update(dt)
    -- Update Particles
    for i = #effects.particles, 1, -1 do
        local pt = effects.particles[i]
        pt.x, pt.y = pt.x + pt.vx * dt, pt.y + pt.vy * dt
        pt.vy = pt.vy + 1000 * dt -- Gravity
        pt.life = pt.life - dt
        if pt.life <= 0 then 
            table.remove(effects.particles, i) 
        end
    end
    
    -- Update Texts - NO MOVEMENT, only fade
    for i = #effects.texts, 1, -1 do
        local t = effects.texts[i]
        -- Text stays in place, only fades
        t.life = t.life - dt
        if t.life <= 0 then 
            table.remove(effects.texts, i) 
        end
    end
    
    -- Update Animations
    for i = #effects.animations, 1, -1 do
        local a = effects.animations[i]
        a.timer = a.timer - dt
        a.scale = math.max(0, a.timer / a.duration)
        if a.timer <= 0 then 
            table.remove(effects.animations, i) 
        end
    end
    
    -- Update Lasers
    for i = #effects.lasers, 1, -1 do
        local l = effects.lasers[i]
        l.life = l.life - dt * 2.5
        if l.life <= 0 then 
            table.remove(effects.lasers, i) 
        end
    end
end

function effects.clear()
    effects.particles = {}
    effects.texts = {}
    effects.animations = {}
    effects.lasers = {}
end

return effects
