local Component = require("src.core.Component")

---@class PathfindingCollision : Component
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
local PathfindingCollision = {}
PathfindingCollision.__index = PathfindingCollision

local function isBodyValid(body)
    if not body then return false end
    local ok, _ = pcall(body.getType, body)
    return ok
end

---Create a new PathfindingCollision component
---@param width number Width of the collision box (or diameter for circle)
---@param height number Height of the collision box (or diameter for circle)
---@param type string|nil Type of collider, defaults to "dynamic"
---@param offsetX number|nil Horizontal offset from entity top-left
---@param offsetY number|nil Vertical offset from entity top-left
---@param shape string|nil Shape of collider ("rectangle" or "circle"), defaults to "rectangle"
---@return Component|PathfindingCollision
function PathfindingCollision.new(width, height, type, offsetX, offsetY, shape)
    local self = setmetatable(Component.new("PathfindingCollision"), PathfindingCollision)

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
function PathfindingCollision:createCollider(physicsWorld, x, y)
    if not physicsWorld or self.collider then
        return
    end

    self.physicsWorld = physicsWorld

    -- Create Love2D physics body for all entities (both static and dynamic)
    -- This allows PathfindingCollision to actually block movement for pathfinding
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

    -- Create fixture
    local fixture = love.physics.newFixture(body, shape)
    fixture:setRestitution(self.restitution)
    fixture:setFriction(self.friction)
    fixture:setDensity(1.0)

    -- Set body properties
    body:setLinearDamping(self.linearDamping)
    body:setFixedRotation(true) -- Prevent the collider from rotating

    -- For dynamic bodies, set properties to allow proper collision behavior
    if self.type ~= "static" then
        body:setGravityScale(0) -- No gravity for top-down game
        body:setBullet(false) -- Don't use continuous collision detection (better performance)
    end

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
function PathfindingCollision:setPosition(x, y)
    if self.collider and isBodyValid(self.collider.body) then
        self.collider.body:setPosition(x + self.offsetX + self.width/2, y + self.offsetY + self.height/2)
    end
end

---Get the collider position (top-left corner)
---@return number, number X and Y position
function PathfindingCollision:getPosition()
    if self.collider and isBodyValid(self.collider.body) then
        local bodyX, bodyY = self.collider.body:getPosition()
        return bodyX - self.width/2 - self.offsetX, bodyY - self.height/2 - self.offsetY
    end
    return 0, 0
end

---Get the collider center position
---@return number, number X and Y center position
function PathfindingCollision:getCenterPosition()
    if self.collider and isBodyValid(self.collider.body) then
        local bodyX, bodyY = self.collider.body:getPosition()
        return bodyX, bodyY
    end
    return 0, 0
end

---Get the collider velocity
---@return number, number X and Y velocity
function PathfindingCollision:getLinearVelocity()
    if self.collider and isBodyValid(self.collider.body) then
        return self.collider.body:getLinearVelocity()
    end
    return 0, 0
end

---Set the collider velocity
---@param vx number X velocity
---@param vy number Y velocity
function PathfindingCollision:setLinearVelocity(vx, vy)
    if self.collider and isBodyValid(self.collider.body) then
        self.collider.body:setLinearVelocity(vx, vy)
    end
end

---Apply a linear impulse to the collider (better for knockback)
---@param ix number X impulse
---@param iy number Y impulse
function PathfindingCollision:applyLinearImpulse(ix, iy)
    if self.collider and isBodyValid(self.collider.body) then
        self.collider.body:applyLinearImpulse(ix, iy)
    end
end

---Apply a force to the collider (smoother for continuous effects)
---@param fx number X force
---@param fy number Y force
function PathfindingCollision:applyForce(fx, fy)
    if self.collider and isBodyValid(self.collider.body) then
        self.collider.body:applyForce(fx, fy)
    end
end


---Destroy the collider
function PathfindingCollision:destroy()
    if self.collider then
        if isBodyValid(self.collider.body) then
            self.collider.body:destroy()
        end
        self.collider = nil
    end
end

---Check if the collider exists
---@return boolean True if collider exists
function PathfindingCollision:hasCollider()
    return self.collider ~= nil
end


---Check line of sight to a world point using physics raycast
---@param targetX number
---@param targetY number
---@param ignoreFixture table|nil Fixture to ignore (e.g., player's fixture)
---@return boolean
function PathfindingCollision:hasLineOfSightTo(targetX, targetY, ignoreFixture)
    if not (self.physicsWorld and self.collider and isBodyValid(self.collider.body)) then
        return true -- fallback: assume visible
    end

    local startX, startY = self:getCenterPosition()
    local blocked = false

    self.physicsWorld:rayCast(startX, startY, targetX, targetY, function(fixture, x, y, xn, yn, fraction)
        if ignoreFixture and fixture == ignoreFixture then
            return -1 -- ignore and continue
        end
        -- Ignore our own fixture
        if self.collider and fixture == self.collider.fixture then
            return -1
        end
        -- Block on any static fixture (walls/borders)
        local body = fixture:getBody()
        if body and body:getType() == "static" then
            blocked = true
            return 0 -- terminate ray
        end
        return 1 -- continue
    end)

    return not blocked
end

---Serialize the PathfindingCollision component for saving
---Note: Box2D collider is not serialized, it will be recreated
---@return table Serialized collision data
function PathfindingCollision:serialize()
    return {
        width = self.width,
        height = self.height,
        offsetX = self.offsetX,
        offsetY = self.offsetY,
        type = self.type,
        shape = self.shape,
        restitution = self.restitution,
        friction = self.friction,
        linearDamping = self.linearDamping,
        enabled = self.enabled
    }
end

---Deserialize PathfindingCollision component from saved data
---@param data table Serialized collision data
---@return PathfindingCollision Recreated PathfindingCollision component
function PathfindingCollision.deserialize(data)
    local collision = PathfindingCollision.new(
        data.width,
        data.height,
        data.type,
        data.offsetX,
        data.offsetY,
        data.shape
    )
    collision.restitution = data.restitution or 0.1
    collision.friction = data.friction or 0.3
    collision.linearDamping = data.linearDamping or 0
    collision.enabled = data.enabled ~= false
    -- Collider will be created by entity creation logic
    return collision
end

return PathfindingCollision
