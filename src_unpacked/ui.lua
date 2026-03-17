-- UI System - Buttons, Hover States, Animations

local ui = {}
local config = require("config")
local utils = require("utils")

-- UI State
ui.buttons = {}
ui.hoverButton = nil
ui.mouseX = 0
ui.mouseY = 0
ui.transitionAlpha = 0
ui.transitionState = "NONE" -- NONE, FADE_IN, FADE_OUT

function ui.init()
    ui.buttons = {}
    ui.hoverButton = nil
    ui.transitionAlpha = 0
    ui.transitionState = "NONE"
end

function ui.update(dt, state)
    -- Update transition
    if ui.transitionState == "FADE_IN" then
        ui.transitionAlpha = math.min(1, ui.transitionAlpha + dt * 4)
        if ui.transitionAlpha >= 1 then
            ui.transitionState = "NONE"
        end
    elseif ui.transitionState == "FADE_OUT" then
        ui.transitionAlpha = math.max(0, ui.transitionAlpha - dt * 4)
        if ui.transitionAlpha <= 0 then
            ui.transitionState = "NONE"
        end
    end
    
    -- Update button hover states
    ui.hoverButton = nil
    for i, btn in ipairs(ui.buttons) do
        if btn.visible then
            local dist = math.sqrt((ui.mouseX - btn.x)^2 + (ui.mouseY - btn.y)^2)
            if dist < btn.radius or (ui.mouseX >= btn.x - btn.w/2 and ui.mouseX <= btn.x + btn.w/2 and
                ui.mouseY >= btn.y - btn.h/2 and ui.mouseY <= btn.y + btn.h/2) then
                ui.hoverButton = i
                btn.hoverScale = math.min(1.15, btn.hoverScale + dt * 8)
            else
                btn.hoverScale = math.max(1.0, btn.hoverScale - dt * 8)
            end
        end
    end
end

function ui.setMousePos(x, y)
    ui.mouseX = x
    ui.mouseY = y
end

function ui.createButton(id, x, y, w, h, label, action)
    table.insert(ui.buttons, {
        id = id,
        x = x,
        y = y,
        w = w,
        h = h,
        radius = math.max(w, h) / 2,
        label = label,
        action = action,
        hoverScale = 1.0,
        visible = true,
        pulse = 0
    })
end

function ui.startTransition(type)
    ui.transitionState = type
end

function ui.getButtonAt(x, y)
    for i, btn in ipairs(ui.buttons) do
        if btn.visible then
            if (x >= btn.x - btn.w/2 and x <= btn.x + btn.w/2 and
                y >= btn.y - btn.h/2 and y <= btn.y + btn.h/2) then
                return i, btn
            end
        end
    end
    return nil, nil
end

return ui
