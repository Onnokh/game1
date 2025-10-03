-- Import System base class
local System = require("src.core.System")

---@class MouseFacingSystem : System
local MouseFacingSystem = setmetatable({}, {__index = System})
MouseFacingSystem.__index = MouseFacingSystem

---Create a new MouseFacingSystem
---@param gameState table The game state containing mouse position
---@return MouseFacingSystem|System
function MouseFacingSystem.new(gameState)
    local self = System.new({"Position", "SpriteRenderer"})
    setmetatable(self, MouseFacingSystem)

    -- Create update function with closure over gameState
    function self:update(dt)
        for _, entity in ipairs(self.entities) do
            local position = entity:getComponent("Position")
            local spriteRenderer = entity:getComponent("SpriteRenderer")

            if position and spriteRenderer and spriteRenderer.facingMouse then
                -- Calculate direction from sprite center to mouse
                local mouseX = gameState.input.mouseX
                local mouseY = gameState.input.mouseY

                -- Get sprite center position (entity position + half sprite size)
                local spriteCenterX = position.x + (spriteRenderer.width / 2)
                local spriteCenterY = position.y + (spriteRenderer.height / 2)

                local dx = mouseX - spriteCenterX
                local dy = mouseY - spriteCenterY

                -- Determine if mouse is to the left or right of the sprite center
                local shouldFlip = dx < 0

                -- Update scaleX to flip the sprite horizontally
                if shouldFlip then
                    spriteRenderer.scaleX = -1
                else
                    spriteRenderer.scaleX = 1
                end
            end
        end
    end

    return self
end

return MouseFacingSystem
