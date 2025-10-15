---@class Footprint
---Ephemeral footprint instance, rendered by FootprintsSystem and auto-faded
---@field x number
---@field y number
---@field angle number Radians; orientation aligned with movement
---@field lifetime number Seconds total lifetime
---@field age number Seconds since spawn
---@field width number Ellipse width
---@field height number Ellipse height
---@field baseAlpha number Initial alpha at spawn
local Footprint = {}
Footprint.__index = Footprint

local Component = require("src.core.Component")

---Create a new Footprint instance component
---@param x number
---@param y number
---@param angle number radians
---@param lifetime number seconds
---@param width number
---@param height number
---@param baseAlpha number 0..1
---@return Component|Footprint
function Footprint.new(x, y, angle, lifetime, width, height, baseAlpha)
    local self = setmetatable(Component.new("Footprint"), Footprint)
    self.x = x or 0
    self.y = y or 0
    self.angle = angle or 0
    self.lifetime = lifetime or 2.5
    self.age = 0
    self.width = width or 10
    self.height = height or 5
    self.baseAlpha = baseAlpha or 0.45
    return self
end

return Footprint


