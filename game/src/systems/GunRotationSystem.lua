local System = require("src.core.System")

---@class GunRotationSystem : System
local GunRotationSystem = System:extend("GunRotationSystem", {"Position", "Animator"})

---Create a new GunRotationSystem
---@param gameState table The game state containing mouse position
---@return GunRotationSystem|System
function GunRotationSystem.new(gameState)
    local self = System.new()
    setmetatable(self, GunRotationSystem)
    self.requiredComponents = {"Position", "Animator"}

    -- Create update function with closure over gameState
    function self:update(dt)
        for _, entity in ipairs(self.entities) do
            -- Only process player entities
            if entity:hasTag("Player") then
                local position = entity:getComponent("Position")
                local animator = entity:getComponent("Animator")

                if position and animator then
                    local spriteRenderer = entity:getComponent("SpriteRenderer")

                    -- Calculate direction from player position to mouse cursor
                    local mouseX = gameState.input.mouseX
                    local mouseY = gameState.input.mouseY

                    local dx = mouseX - position.x
                    local dy = mouseY - position.y

                    -- Calculate angle from player to mouse (in radians)
                    local angle = math.atan2(dy, dx)

                    -- Handle different cases based on player facing direction and mouse position
                    if spriteRenderer then
                        local isFacingLeft = spriteRenderer.scaleX < 0

                        if isFacingLeft then
                            -- When player is facing left, we need to flip the Y component
                            -- to account for the horizontal flip of the sprite
                            animator:setLayerScale("gun", 1, -1)
                            animator:setLayerOffset("gun", 19, 16)  -- Attach to shoulder
                            animator:setLayerPivot("gun", 10, 16)   -- Rotate around shoulder
                        else
                            -- When facing right, use normal scale and default pivot
                            animator:setLayerScale("gun", 1, 1)
                            animator:setLayerOffset("gun", 11, 16)   -- Attach to shoulder
                            animator:setLayerPivot("gun", 10, 16)   -- Rotate around shoulder
                        end
                    end

                    -- Set the gun layer rotation to point at the mouse
                    animator:setLayerRotation("gun", angle)
                end
            end
        end
    end

    return self
end

return GunRotationSystem
