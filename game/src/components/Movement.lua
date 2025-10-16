local Component = require("src.core.Component")

---@class Movement : Component
---@field velocityX number X velocity
---@field velocityY number Y velocity
---@field maxSpeed number Maximum movement speed
---@field baseMaxSpeed number Base maximum speed before modifiers
---@field acceleration number Acceleration rate
---@field friction number Friction rate (0-1)
---@field direction string Current movement direction
---@field enabled boolean Whether movement is enabled
---@field activeModifiers table Active modifiers keyed by source identifier
local Movement = {}
Movement.__index = Movement

---Create a new Movement component
---@param maxSpeed number Maximum movement speed
---@param acceleration number|nil Acceleration rate, defaults to maxSpeed * 10
---@param friction number|nil Friction rate (0-1), defaults to 0.8
---@return Component|Movement
function Movement.new(maxSpeed, acceleration, friction)
    local self = setmetatable(Component.new("Movement"), Movement)

    self.velocityX = 0
    self.velocityY = 0
    self.maxSpeed = maxSpeed or 300
    self.baseMaxSpeed = maxSpeed or 300
    self.acceleration = acceleration or (maxSpeed * 10)
    self.friction = friction or 0.8
    self.direction = "down"
    self.enabled = true
    self.activeModifiers = {}

    return self
end

---Set the velocity directly
---@param velocityX number X velocity
---@param velocityY number Y velocity
function Movement:setVelocity(velocityX, velocityY)
    self.velocityX = velocityX
    self.velocityY = velocityY
end

---Add velocity to current velocity
---@param deltaX number X velocity to add
---@param deltaY number Y velocity to add
function Movement:addVelocity(deltaX, deltaY)
    self.velocityX = self.velocityX + deltaX
    self.velocityY = self.velocityY + deltaY
end

---Apply friction to velocity
---@param dt number Delta time
function Movement:applyFriction(dt)
    if not self.enabled then return end

    self.velocityX = self.velocityX * (1 - self.friction * dt)
    self.velocityY = self.velocityY * (1 - self.friction * dt)

    -- Stop very small velocities
    if math.abs(self.velocityX) < 1 then
        self.velocityX = 0
    end
    if math.abs(self.velocityY) < 1 then
        self.velocityY = 0
    end
end

---Clamp velocity to max speed
function Movement:clampVelocity()
    local speed = math.sqrt(self.velocityX * self.velocityX + self.velocityY * self.velocityY)
    if speed > self.maxSpeed then
        local factor = self.maxSpeed / speed
        self.velocityX = self.velocityX * factor
        self.velocityY = self.velocityY * factor
    end
end

---Get the current speed
---@return number Current speed magnitude
function Movement:getSpeed()
    return math.sqrt(self.velocityX * self.velocityX + self.velocityY * self.velocityY)
end

---Check if the entity is moving
---@return boolean True if the entity is moving
function Movement:isMoving()
    return self.velocityX ~= 0 or self.velocityY ~= 0
end

---Update movement stats based on active modifiers
---Recalculates maxSpeed from baseMaxSpeed and all active modifiers
function Movement:updateStats()
    -- Start with base speed
    local finalSpeed = self.baseMaxSpeed

    -- Apply all active modifiers
    for source, modifier in pairs(self.activeModifiers) do
        if modifier.stat == "speed" then
            if modifier.mode == "multiply" then
                finalSpeed = finalSpeed * modifier.value
            elseif modifier.mode == "add" then
                finalSpeed = finalSpeed + modifier.value
            end
        end
    end

    -- Update maxSpeed
    self.maxSpeed = finalSpeed
end

---Add a modifier to this movement component
---@param source string Unique identifier for the modifier source
---@param stat string Stat to modify (e.g., "speed")
---@param mode string Mode of modification ("multiply" or "add")
---@param value number Value to apply
function Movement:addModifier(source, stat, mode, value)
    self.activeModifiers[source] = {
        stat = stat,
        mode = mode,
        value = value
    }
    self:updateStats()
end

---Remove a modifier from this movement component
---@param source string Unique identifier for the modifier source
function Movement:removeModifier(source)
    self.activeModifiers[source] = nil
    self:updateStats()
end

---Check if a modifier is active
---@param source string Unique identifier for the modifier source
---@return boolean True if the modifier is active
function Movement:hasModifier(source)
    return self.activeModifiers[source] ~= nil
end

---Serialize the Movement component for saving
---@return table Serialized movement data
function Movement:serialize()
    return {
        velocityX = self.velocityX,
        velocityY = self.velocityY,
        maxSpeed = self.maxSpeed,
        baseMaxSpeed = self.baseMaxSpeed,
        acceleration = self.acceleration,
        friction = self.friction,
        direction = self.direction,
        enabled = self.enabled,
        activeModifiers = self.activeModifiers
    }
end

---Deserialize Movement component from saved data
---@param data table Serialized movement data
---@return Component|Movement Recreated Movement component
function Movement.deserialize(data)
    local movement = Movement.new(data.baseMaxSpeed or data.maxSpeed, data.acceleration, data.friction)
    movement.velocityX = data.velocityX or 0
    movement.velocityY = data.velocityY or 0
    movement.direction = data.direction or "down"
    movement.enabled = data.enabled ~= false
    movement.activeModifiers = data.activeModifiers or {}
    movement:updateStats()
    return movement
end

return Movement
