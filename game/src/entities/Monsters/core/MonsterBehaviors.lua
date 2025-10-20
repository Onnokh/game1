---@class MonsterBehaviors
---Shared behaviors for monster entities
local MonsterBehaviors = {}

local GameConstants = require("src.constants")

---Update the monster's current target
---@param entity Entity The monster entity
function MonsterBehaviors.updateTarget(entity)
    local EntityUtils = require("src.utils.entities")
    local player = EntityUtils.findPlayer(entity._world)

    -- Simply target the player if they exist and are alive
    local chosenTarget = nil
    if player and not player.isDead then
        chosenTarget = player
    end

    entity.target = chosenTarget
end

---Select the appropriate state based on current conditions
---@param entity Entity The monster entity
---@param dt number Delta time
---@param config table The monster's configuration (must have ATTACK_RANGE_TILES)
---@return string The desired state name
function MonsterBehaviors.selectState(entity, dt, config)
    local EntityUtils = require("src.utils.entities")
    local stateMachine = entity:getComponent("StateMachine")
    local health = entity:getComponent("Health")
    local currentState = stateMachine:getCurrentState()

    -- Priority 1: Check if dead
    if health and health.current <= 0 then
        return "dying"
    end

    -- Priority 2: Update target and check for detection
    MonsterBehaviors.updateTarget(entity)
    local target = entity.target
    if target then

        -- Use the same distance calculation as updateTarget for consistency
        local position = entity:getComponent("Position")
        local pathfindingCollision = entity:getComponent("PathfindingCollision")

        local sx, sy = position.x, position.y
        if pathfindingCollision and pathfindingCollision:hasCollider() then
            sx, sy = pathfindingCollision:getCenterPosition()
        end

        local tx, ty = EntityUtils.getClosestPointOnTarget(sx, sy, target)
        local dx = tx - sx
        local dy = ty - sy
        local dist = math.sqrt(dx*dx + dy*dy)

        local attackRange = config.ATTACK_RANGE_TILES * GameConstants.TILE_SIZE

        -- Priority: attacking > chasing
        if dist <= attackRange then
            return "attacking"
        else
            return "chasing"
        end
    end

    -- Priority 3: Default behavior (idle only) when no target
    -- If currently attacking or chasing but no target, transition to idle
    if currentState == "attacking" or currentState == "chasing" then
        return "idle"
    end

    -- Default: stay in current state if no higher priority state is needed
    return currentState
end

return MonsterBehaviors

