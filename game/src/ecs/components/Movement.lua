---@class Movement
---@field velocityX number X velocity
---@field velocityY number Y velocity
---@field maxSpeed number Maximum movement speed
---@field acceleration number Acceleration rate
---@field friction number Friction rate (0-1)
---@field direction string Current movement direction
---@field enabled boolean Whether movement is enabled
local Movement = {}
Movement.__index = Movement

---Create a new Movement component
---@param maxSpeed number Maximum movement speed
---@param acceleration number|nil Acceleration rate, defaults to maxSpeed * 10
---@param friction number|nil Friction rate (0-1), defaults to 0.8
---@return Component|Movement
function Movement.new(maxSpeed, acceleration, friction)
    local Component = require("src.ecs.Component")
    local self = setmetatable(Component.new("Movement"), Movement)

    self.velocityX = 0
    self.velocityY = 0
    self.maxSpeed = maxSpeed or 300
    self.acceleration = acceleration or (maxSpeed * 10)
    self.friction = friction or 0.8
    self.direction = "down"
    self.enabled = true

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

---Apply acceleration in a direction
---@param directionX number X direction (-1, 0, or 1)
---@param directionY number Y direction (-1, 0, or 1)
---@param dt number Delta time
function Movement:accelerate(directionX, directionY, dt)
    if not self.enabled then return end

    -- Normalize diagonal movement to prevent faster diagonal movement
    local magnitude = math.sqrt(directionX * directionX + directionY * directionY)
    if magnitude > 0 then
        directionX = directionX / magnitude
        directionY = directionY / magnitude
    end

    local accelX = directionX * self.acceleration * dt
    local accelY = directionY * self.acceleration * dt

    self.velocityX = self.velocityX + accelX
    self.velocityY = self.velocityY + accelY

    -- Update direction based on movement
    if directionX ~= 0 or directionY ~= 0 then
        if directionY < 0 then
            self.direction = "up"
        elseif directionY > 0 then
            self.direction = "down"
        elseif directionX < 0 then
            self.direction = "left"
        elseif directionX > 0 then
            self.direction = "right"
        end
    end
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

return Movement
