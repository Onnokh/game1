---@class MonsterBehaviors
---Shared behaviors for monster entities
local MonsterBehaviors = {}

local GameConstants = require("src.constants")

---Update the monster's current target
---@param entity Entity The monster entity
---@param config table The monster's configuration (must have CHASE_RANGE)
function MonsterBehaviors.updateTarget(entity, config)
    local EntityUtils = require("src.utils.entities")
    local player = EntityUtils.findPlayer(entity._world)
    local reactor = EntityUtils.findReactor(entity._world)

    local monsterPos = entity:getComponent("Position")
    if not monsterPos then
        entity.target = nil
        return
    end

    local chaseRange = config.CHASE_RANGE * GameConstants.TILE_SIZE
    local pathfindingCollision = entity:getComponent("PathfindingCollision")

    -- Calculate distances and check line of sight for both targets
    local playerDistance = math.huge
    local reactorDistance = math.huge
    local playerHasLOS = false
    local reactorHasLOS = false

    if player and not player.isDead then
        local px, py = EntityUtils.getClosestPointOnTarget(monsterPos.x, monsterPos.y, player)
        local dx = px - monsterPos.x
        local dy = py - monsterPos.y
        playerDistance = math.sqrt(dx*dx + dy*dy)
        playerHasLOS = not pathfindingCollision or pathfindingCollision:hasLineOfSightTo(px, py, nil)
    end

    if reactor and not reactor.isDead then
        local rx, ry = EntityUtils.getClosestPointOnTarget(monsterPos.x, monsterPos.y, reactor)
        local dx = rx - monsterPos.x
        local dy = ry - monsterPos.y
        reactorDistance = math.sqrt(dx*dx + dy*dy)
        -- Reactor doesn't need line of sight check (it's a static structure)
        reactorHasLOS = true
    end

    -- Choose target based on priority, then distance
    -- Priority 1: Player (always preferred)
    -- Priority 2: Reactor (only if player is not available)
    local chosenTarget = nil

    -- Check player first (HIGHEST PRIORITY - always prefer player over reactor)
    if player and playerDistance <= chaseRange and playerHasLOS then
        chosenTarget = player
    -- Only target reactor if player is not available
    elseif reactor and reactorDistance <= chaseRange and reactorHasLOS then
        chosenTarget = reactor
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
    MonsterBehaviors.updateTarget(entity, config)
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

    -- Priority 3: Default behavior (idle/wandering) when no target
    -- If currently attacking or chasing but no target, transition to idle
    if currentState == "attacking" or currentState == "chasing" then
        return "idle"
    end

    -- Handle idle/wandering transitions
    if currentState == "idle" then
        -- Check if idle time has expired
        local idleTime = stateMachine:getStateData("idleTime") or 0
        local targetIdleTime = stateMachine:getStateData("targetIdleTime") or 2
        if idleTime >= targetIdleTime then
            return "wandering"
        end
    elseif currentState == "wandering" then
        -- Check if wander path is complete
        local pathfinding = entity:getComponent("Pathfinding")
        if pathfinding and pathfinding:isPathComplete() then
            return "idle"
        end
    end

    -- Default: stay in current state if no higher priority state is needed
    return currentState
end

return MonsterBehaviors

