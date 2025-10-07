local Component = require("src.core.Component")

---@class Position : Component
---@field x number X position
---@field y number Y position
---@field z number|nil Z position (for layering)
local Position = {}
Position.__index = Position

---Create a new Position component
---@param x number X position
---@param y number Y position
---@param z number|nil Z position, defaults to 0
---@return Component|Position
function Position.new(x, y, z)
    local self = setmetatable(Component.new("Position"), Position)

    self.x = x or 0
    self.y = y or 0
    self.z = z or 0

    return self
end

---Set the position
---@param x number X position
---@param y number Y position
---@param z number|nil Z position
function Position:setPosition(x, y, z)
    self.x = x
    self.y = y
    if z then
        self.z = z
    end
end

---Move the position by a delta
---@param deltaX number X delta
---@param deltaY number Y delta
---@param deltaZ number|nil Z delta
function Position:move(deltaX, deltaY, deltaZ)
    self.x = self.x + deltaX
    self.y = self.y + deltaY
    if deltaZ then
        self.z = self.z + deltaZ
    end
end

---Get the distance to another position
---@param other Position Another position component
---@return number Distance to the other position
function Position:distanceTo(other)
    local dx = self.x - other.x
    local dy = self.y - other.y
    return math.sqrt(dx * dx + dy * dy)
end

---Get the depth value for sorting (Y + Z)
---@return number Combined depth value for rendering order
function Position:getDepth()
    return self.y + (self.z or 0)
end

---Set the Z-index for layering
---@param z number Z-index value (higher values render on top)
function Position:setZ(z)
    self.z = z or 0
end

---Get the Z-index
---@return number Current Z-index value
function Position:getZ()
    return self.z or 0
end

return Position
