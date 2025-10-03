---@class Collision
---@field collider table|nil The physics collider object
---@field width number Width of the collision box
---@field height number Height of the collision box
---@field offsetX number Horizontal offset from entity top-left
---@field offsetY number Vertical offset from entity top-left
---@field type string Type of collider ("dynamic", "static", "kinematic")
---@field restitution number Bounce factor (0-1)
---@field friction number Friction factor (0-1)
---@field linearDamping number Linear damping factor
---@field enabled boolean Whether collision is enabled
---@field physicsWorld table|nil The physics world this collider belongs to
local Collision = {}
Collision.__index = Collision

---Create a new Collision component
---@param width number Width of the collision box
---@param height number Height of the collision box
---@param type string|nil Type of collider, defaults to "dynamic"
---@param offsetX number|nil Horizontal offset from entity top-left
---@param offsetY number|nil Vertical offset from entity top-left
---@return Component|Collision
function Collision.new(width, height, type, offsetX, offsetY)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Collision"), Collision)

    self.collider = nil
    self.width = width or 16
    self.height = height or 24
    self.type = type or "dynamic"
    self.restitution = 0.1
    self.friction = 0.3
    self.linearDamping = 0
    self.enabled = true
    self.physicsWorld = nil
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0

    return self
end

---Set the physics world for this collision component
---@param physicsWorld table The physics world to create collider in
---@param x number X position
---@param y number Y position
function Collision:createCollider(physicsWorld, x, y)
    if not physicsWorld or self.collider then
        return
    end

    self.physicsWorld = physicsWorld
    self.collider = physicsWorld:newCollider("Rectangle", {
        x + self.offsetX + self.width/2,
        y + self.offsetY + self.height/2,
        self.width, self.height
    })

    self.collider:setType(self.type)
    self.collider:setRestitution(self.restitution)
    self.collider:setFriction(self.friction)
    self.collider:setLinearDamping(self.linearDamping)
    self.collider:setFixedRotation(true) -- Prevent the collider from rotating
end


---Update the collider position
---@param x number X position
---@param y number Y position
function Collision:setPosition(x, y)
    if self.collider then
        self.collider:setPosition(x + self.offsetX + self.width/2, y + self.offsetY + self.height/2)
    end
end

---Get the collider position
---@return number, number X and Y position
function Collision:getPosition()
    if self.collider then
        return self.collider:getX() - self.width/2 - self.offsetX, self.collider:getY() - self.height/2 - self.offsetY
    end
    return 0, 0
end


---Destroy the collider
function Collision:destroy()
    if self.collider then
        self.collider:destroy()
        self.collider = nil
    end
end

---Check if the collider exists
---@return boolean True if collider exists
function Collision:hasCollider()
    return self.collider ~= nil
end


return Collision
