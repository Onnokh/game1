-- Import System base class
local System = require("src.System")

---@class MovementSystem : System
local MovementSystem = setmetatable({}, {__index = System})
MovementSystem.__index = MovementSystem

---Create a new MovementSystem
---@return MovementSystem|System
function MovementSystem.new()
    local self = System.new({"Position", "Movement"})
    setmetatable(self, MovementSystem)
    return self
end

---Update all entities with Position and Movement components
---@param dt number Delta time
function MovementSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local movement = entity:getComponent("Movement")
        local collision = entity:getComponent("Collision")

        if position and movement and movement.enabled then
            -- Apply velocity to physics collider and let Breezefield handle collision
            if collision and collision:hasCollider() then
                collision.collider:setLinearVelocity(movement.velocityX, movement.velocityY)
                -- Sync ECS position from physics collider
                local x, y = collision:getPosition()
                position:setPosition(x, y)
            else
                -- Fallback to direct position movement if no collider
                position:move(movement.velocityX * dt, movement.velocityY * dt)
            end
        end
    end
end

return MovementSystem
