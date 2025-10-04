---@class Knockback
---@field x number X direction of knockback
---@field y number Y direction of knockback
---@field power number Power/magnitude of knockback
---@field duration number How long the knockback effect lasts
---@field timer number Current timer for the knockback effect
local Knockback = {}
Knockback.__index = Knockback

---Create a new Knockback component
---@param x number X direction of knockback
---@param y number Y direction of knockback
---@param power number Power/magnitude of knockback
---@param duration number How long the knockback effect lasts
---@return Component|Knockback
function Knockback.new(x, y, power, duration)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Knockback"), Knockback)

    self.x = x or 0
    self.y = y or 0
    self.power = power or 1
    self.duration = duration or 0.1
    self.timer = 0

    return self
end

return Knockback
