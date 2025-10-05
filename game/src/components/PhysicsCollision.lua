local Component = require("src.core.Component")
local GameConstants = require("src.constants")

---@class PhysicsCollision : Component
---Physics-only collision component (no pathfinding integration)
---@field collider table|nil The physics collider object
---@field width number Width of the collision box (or diameter for circle)
---@field height number Height of the collision box (or diameter for circle)
---@field offsetX number Horizontal offset from entity top-left
---@field offsetY number Vertical offset from entity top-left
---@field type string Type of collider ("dynamic", "static", "kinematic")
---@field shape string Shape of collider ("rectangle", "circle")
---@field restitution number Bounce factor (0-1)
---@field friction number Friction factor (0-1)
---@field linearDamping number Linear damping factor
---@field enabled boolean Whether collision is enabled
---@field physicsWorld table|nil The physics world this collider belongs to
local PhysicsCollision = {}
PhysicsCollision.__index = PhysicsCollision

---Create a new PhysicsCollision component
---@param width number Width of the collision box (or diameter for circle)
---@param height number Height of the collision box (or diameter for circle)
---@param type string|nil Type of collider, defaults to "dynamic"
---@param offsetX number|nil Horizontal offset from entity top-left
---@param offsetY number|nil Vertical offset from entity top-left
---@param shape string|nil Shape of collider ("rectangle" or "circle"), defaults to "rectangle"
---@return Component|PhysicsCollision
function PhysicsCollision.new(width, height, type, offsetX, offsetY, shape)
    local self = setmetatable(Component.new("PhysicsCollision"), PhysicsCollision)

    self.collider = nil
    self.width = width or 16
    self.height = height or 24
    self.type = type or "dynamic"
    self.shape = shape or "rectangle"
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
function PhysicsCollision:createCollider(physicsWorld, x, y)
    if not physicsWorld or self.collider then
        return
    end

    self.physicsWorld = physicsWorld

    -- Create Love2D physics body
    local body = love.physics.newBody(physicsWorld,
        x + self.offsetX + self.width/2,
        y + self.offsetY + self.height/2,
        self.type == "static" and "static" or "dynamic")

    -- Create shape based on type
    local shape
    if self.shape == "circle" then
        -- For circle, use the width as diameter
        local radius = self.width / 2
        shape = love.physics.newCircleShape(radius)
    else
        -- Default to rectangle shape
        shape = love.physics.newRectangleShape(self.width, self.height)
    end

    -- Create fixture as a sensor (detects collisions but doesn't physically block)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setSensor(true) -- This makes it a sensor - detects collisions but doesn't block movement
    fixture:setRestitution(self.restitution)
    fixture:setFriction(self.friction)
    fixture:setDensity(1.0)

    -- No collision filtering - let PhysicsCollision collide with everything (but it's a sensor so won't block)
    -- fixture:setCategory(GameConstants.COLLISION_CATEGORIES.PHYSICS)
    -- fixture:setMask(GameConstants.COLLISION_MASKS.PHYSICS)

    -- Set body properties
    body:setLinearDamping(self.linearDamping)
    body:setFixedRotation(true) -- Prevent the collider from rotating

    -- Store the body and fixture as our collider
    self.collider = {
        body = body,
        fixture = fixture,
        shape = shape
    }
end

---Update the collider position
---@param x number X position
---@param y number Y position
function PhysicsCollision:setPosition(x, y)
    if self.collider and self.collider.body then
        self.collider.body:setPosition(x + self.offsetX + self.width/2, y + self.offsetY + self.height/2)
    end
end

---Get the collider position
---@return number, number X and Y position
function PhysicsCollision:getPosition()
    if self.collider and self.collider.body then
        local bodyX, bodyY = self.collider.body:getPosition()
        return bodyX - self.width/2 - self.offsetX, bodyY - self.height/2 - self.offsetY
    end
    return 0, 0
end

---Get the collider velocity
---@return number, number X and Y velocity
function PhysicsCollision:getLinearVelocity()
    if self.collider and self.collider.body then
        return self.collider.body:getLinearVelocity()
    end
    return 0, 0
end

---Set the collider velocity
---@param vx number X velocity
---@param vy number Y velocity
function PhysicsCollision:setLinearVelocity(vx, vy)
    if self.collider and self.collider.body then
        self.collider.body:setLinearVelocity(vx, vy)
    end
end

---Apply a linear impulse to the collider (better for knockback)
---@param ix number X impulse
---@param iy number Y impulse
function PhysicsCollision:applyLinearImpulse(ix, iy)
    if self.collider and self.collider.body then
        self.collider.body:applyLinearImpulse(ix, iy)
    end
end

---Apply a force to the collider (smoother for continuous effects)
---@param fx number X force
---@param fy number Y force
function PhysicsCollision:applyForce(fx, fy)
    if self.collider and self.collider.body then
        self.collider.body:applyForce(fx, fy)
    end
end

---Destroy the collider
function PhysicsCollision:destroy()
    if self.collider and self.collider.body then
        self.collider.body:destroy()
        self.collider = nil
    end
end

---Check if the collider exists
---@return boolean True if collider exists
function PhysicsCollision:hasCollider()
    return self.collider ~= nil and self.collider.body ~= nil
end

return PhysicsCollision
