local System = require("src.core.System")
local GameConstants = require("src.constants")
local EntityUtils = require("src.utils.entities")

---@class OxygenSystem : System
local OxygenSystem = System:extend("OxygenSystem", {"Position", "Oxygen"})

---Update all entities with Position and Oxygen components
---@param dt number Delta time
function OxygenSystem:update(dt)
    -- Get current phase from GameState
    local GameState = require("src.core.GameState")
    local currentPhase = GameState and GameState.phase

    for _, entity in ipairs(self.entities) do
        local position = entity:getComponent("Position")
        local oxygen = entity:getComponent("Oxygen")

        if position and oxygen then
            -- Check if entity is in the reactor's safe zone (using entity center)
            local centerX, centerY = EntityUtils.getEntityVisualCenter(entity, position)
            local isInSafeZone = self:isInReactorSafeZone(centerX, centerY)

            if currentPhase == "Siege" then
                -- During Siege: restore oxygen when in safe zone, decay when outside
                if isInSafeZone then
                    oxygen:restore(GameConstants.OXYGEN_RESTORE_RATE * dt)
                else
                    oxygen:reduce(GameConstants.OXYGEN_DECAY_RATE * dt)
                end
            else
                -- During Discovery: only decay oxygen if outside the safe zone
                if not isInSafeZone then
                    oxygen:reduce(GameConstants.OXYGEN_DECAY_RATE * dt)
                end
            end
        end
    end
end

---Check if a position is within the reactor's safe oxygen zone
---@param x number X coordinate
---@param y number Y coordinate
---@return boolean True if position is in safe zone
function OxygenSystem:isInReactorSafeZone(x, y)
    -- Find the reactor entity in the world
    local reactor = EntityUtils.findReactor(self.world)

    if not reactor then
        -- If no reactor found, assume we're always in danger
        return false
    end

    local reactorPosition = reactor:getComponent("Position")
    if not reactorPosition then
        return false
    end

    -- Calculate distance to reactor's sprite center (not collider center)
    -- The reactor is a 96x96 sprite, so we want the true visual center
    local spriteRenderer = reactor:getComponent("SpriteRenderer")
    local reactorCenterX = reactorPosition.x + (spriteRenderer and spriteRenderer.width or 96) / 2
    local reactorCenterY = reactorPosition.y + (spriteRenderer and spriteRenderer.height or 96) / 2

    local dx = x - reactorCenterX
    local dy = y - reactorCenterY
    local distance = math.sqrt(dx * dx + dy * dy)

    return distance <= GameConstants.REACTOR_SAFE_RADIUS
end

return OxygenSystem
