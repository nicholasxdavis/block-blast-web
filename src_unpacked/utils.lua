-- Utility Functions

local utils = {}

function utils.spring(val, vel, target, tension, damp, dt)
    local accel = tension * (target - val) - damp * vel
    vel = vel + accel * dt
    return val + vel * dt, vel
end

function utils.lerp(a, b, t) 
    return a + (b - a) * t 
end

return utils
