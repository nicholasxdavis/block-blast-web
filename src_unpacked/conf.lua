-- LÖVE Configuration for Web Export
-- This file configures the game for web deployment

function love.conf(t)
    t.title = "Block Blast - Web Edition"
    t.author = "Block Blast Team"
    t.version = "11.4"
    
    -- Window settings
    t.window.width = 1280
    t.window.height = 720
    t.window.resizable = true
    t.window.minwidth = 800
    t.window.minheight = 600
    t.window.highdpi = true
    
    -- Web-specific settings
    t.modules.joystick = false  -- Disable joystick for web
    t.modules.physics = false   -- Disable physics if not used
    
    -- Enable modules we need
    t.modules.audio = true
    t.modules.event = true
    t.modules.graphics = true
    t.modules.image = true
    t.modules.keyboard = true
    t.modules.math = true
    t.modules.mouse = true
    t.modules.sound = true
    t.modules.system = true
    t.modules.timer = true
    t.modules.touch = false  -- Disable touch for desktop web
    t.modules.video = false
    t.modules.window = true
    t.modules.thread = false  -- Disable threads for web compatibility
end
