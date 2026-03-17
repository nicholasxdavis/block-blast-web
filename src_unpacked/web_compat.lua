-- Web Compatibility Module
-- This module provides web-specific patches for LÖVE functions that don't work the same in browsers

local web_compat = {}

-- Check if we're running in a web environment
-- love.js sets a global flag or we can detect it
local isWeb = false
if love.system then
    -- Try to detect web environment
    local success, result = pcall(function()
        return love.system.getOS()
    end)
    if success and result == "Web" then
        isWeb = true
    end
end

-- Patch love.system.openURL for web
-- In love.js, this should work, but we can add a fallback
function web_compat.openURL(url)
    if isWeb then
        -- love.js should handle this, but we can add JavaScript interop if needed
        -- For now, just use the standard function
        if love.system and love.system.openURL then
            love.system.openURL(url)
        else
            -- Fallback: log the URL (in web, this might need JS interop)
            print("Would open URL: " .. url)
        end
    else
        -- Desktop version
        love.system.openURL(url)
    end
end

-- Patch for fullscreen handling on web
-- Web fullscreen works differently than desktop
function web_compat.setFullscreen(fullscreen)
    if isWeb then
        -- On web, we can request fullscreen via the canvas
        -- love.js should handle this, but we ensure it works
        if love.window then
            love.window.setFullscreen(fullscreen)
        end
    else
        love.window.setFullscreen(fullscreen)
    end
end

return web_compat
