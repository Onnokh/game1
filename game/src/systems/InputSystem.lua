-- Import System base class
local System = require("src.core.System")

---@class InputSystem : System
---@field inputState table The input state from gameState
local InputSystem = setmetatable({}, {__index = System})
InputSystem.__index = InputSystem

---Create a new InputSystem
---@param inputState table The input state from gameState
---@return InputSystem|System
function InputSystem.new(inputState)
    local self = System.new({"Movement"})
    setmetatable(self, InputSystem)
    self.inputState = inputState
    return self
end

---Update all entities with Movement components based on input
---@param dt number Delta time
function InputSystem:update(dt)
    for _, entity in ipairs(self.entities) do
        local movement = entity:getComponent("Movement")

        if movement and movement.enabled then
            -- Handle movement input - immediate response
            local velocityX, velocityY = 0, 0

            if self.inputState.left then
                velocityX = -movement.maxSpeed
            end
            if self.inputState.right then
                velocityX = movement.maxSpeed
            end
            if self.inputState.up then
                velocityY = -movement.maxSpeed
            end
            if self.inputState.down then
                velocityY = movement.maxSpeed
            end

            -- Set velocity directly for immediate response
            movement:setVelocity(velocityX, velocityY)
        end
    end
end

return InputSystem
