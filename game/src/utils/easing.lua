---@class Easing
---Easing functions for smooth animations
---All functions take a progress value from 0 to 1 and return an eased value from 0 to 1
local Easing = {}

-- Linear (no easing)
function Easing.linear(t)
    return t
end

-- Quadratic easing
function Easing.inQuad(t)
    return t * t
end

function Easing.outQuad(t)
    return t * (2 - t)
end

function Easing.inOutQuad(t)
    if t < 0.5 then
        return 2 * t * t
    else
        return -1 + (4 - 2 * t) * t
    end
end

-- Cubic easing
function Easing.inCubic(t)
    return t * t * t
end

function Easing.outCubic(t)
    local f = t - 1
    return f * f * f + 1
end

function Easing.inOutCubic(t)
    if t < 0.5 then
        return 4 * t * t * t
    else
        local f = 2 * t - 2
        return 0.5 * f * f * f + 1
    end
end

-- Quartic easing
function Easing.inQuart(t)
    return t * t * t * t
end

function Easing.outQuart(t)
    local f = t - 1
    return 1 - f * f * f * f
end

function Easing.inOutQuart(t)
    if t < 0.5 then
        return 8 * t * t * t * t
    else
        local f = t - 1
        return 1 - 8 * f * f * f * f
    end
end

-- Quintic easing
function Easing.inQuint(t)
    return t * t * t * t * t
end

function Easing.outQuint(t)
    local f = t - 1
    return f * f * f * f * f + 1
end

function Easing.inOutQuint(t)
    if t < 0.5 then
        return 16 * t * t * t * t * t
    else
        local f = 2 * t - 2
        return 0.5 * f * f * f * f * f + 1
    end
end

-- Sine easing
function Easing.inSine(t)
    return 1 - math.cos(t * math.pi / 2)
end

function Easing.outSine(t)
    return math.sin(t * math.pi / 2)
end

function Easing.inOutSine(t)
    return 0.5 * (1 - math.cos(t * math.pi))
end

-- Exponential easing
function Easing.inExpo(t)
    if t == 0 then
        return 0
    else
        return math.pow(2, 10 * (t - 1))
    end
end

function Easing.outExpo(t)
    if t == 1 then
        return 1
    else
        return 1 - math.pow(2, -10 * t)
    end
end

function Easing.inOutExpo(t)
    if t == 0 or t == 1 then
        return t
    end

    if t < 0.5 then
        return 0.5 * math.pow(2, 20 * t - 10)
    else
        return 1 - 0.5 * math.pow(2, -20 * t + 10)
    end
end

-- Circular easing
function Easing.inCirc(t)
    return 1 - math.sqrt(1 - t * t)
end

function Easing.outCirc(t)
    return math.sqrt(1 - (t - 1) * (t - 1))
end

function Easing.inOutCirc(t)
    if t < 0.5 then
        return 0.5 * (1 - math.sqrt(1 - 4 * t * t))
    else
        return 0.5 * (math.sqrt(1 - (-2 * t + 2) * (-2 * t + 2)) + 1)
    end
end

-- Back easing (overshoots)
function Easing.inBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return c3 * t * t * t - c1 * t * t
end

function Easing.outBack(t)
    local c1 = 1.70158
    local c3 = c1 + 1
    return 1 + c3 * math.pow(t - 1, 3) + c1 * math.pow(t - 1, 2)
end

function Easing.inOutBack(t)
    local c1 = 1.70158
    local c2 = c1 * 1.525

    if t < 0.5 then
        return (math.pow(2 * t, 2) * ((c2 + 1) * 2 * t - c2)) / 2
    else
        return (math.pow(2 * t - 2, 2) * ((c2 + 1) * (t * 2 - 2) + c2) + 2) / 2
    end
end

-- Elastic easing (bounces)
function Easing.inElastic(t)
    if t == 0 or t == 1 then
        return t
    end

    local c4 = (2 * math.pi) / 3
    return -math.pow(2, 10 * t - 10) * math.sin((t * 10 - 10.75) * c4)
end

function Easing.outElastic(t)
    if t == 0 or t == 1 then
        return t
    end

    local c4 = (2 * math.pi) / 3
    return math.pow(2, -10 * t) * math.sin((t * 10 - 0.75) * c4) + 1
end

function Easing.inOutElastic(t)
    if t == 0 or t == 1 then
        return t
    end

    local c5 = (2 * math.pi) / 4.5

    if t < 0.5 then
        return -(math.pow(2, 20 * t - 10) * math.sin((20 * t - 11.125) * c5)) / 2
    else
        return (math.pow(2, -20 * t + 10) * math.sin((20 * t - 11.125) * c5)) / 2 + 1
    end
end

-- Bounce easing
function Easing.outBounce(t)
    local n1 = 7.5625
    local d1 = 2.75

    if t < 1 / d1 then
        return n1 * t * t
    elseif t < 2 / d1 then
        t = t - 1.5 / d1
        return n1 * t * t + 0.75
    elseif t < 2.5 / d1 then
        t = t - 2.25 / d1
        return n1 * t * t + 0.9375
    else
        t = t - 2.625 / d1
        return n1 * t * t + 0.984375
    end
end

function Easing.inBounce(t)
    return 1 - Easing.outBounce(1 - t)
end

function Easing.inOutBounce(t)
    if t < 0.5 then
        return (1 - Easing.outBounce(1 - 2 * t)) / 2
    else
        return (1 + Easing.outBounce(2 * t - 1)) / 2
    end
end

return Easing

