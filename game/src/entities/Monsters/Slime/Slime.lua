local SlimeConfig = require("src.entities.Monsters.Slime.SlimeConfig")
local MonsterFactory = require("src.entities.Monsters.core.MonsterFactory")
local SlimeIdle = require("src.entities.Monsters.Slime.states.Idle")
local SlimeChasing = require("src.entities.Monsters.Slime.states.Chasing")
local SlimeAttacking = require("src.entities.Monsters.Slime.states.Attacking")
local SlimeWandering = require("src.entities.Monsters.Slime.states.Wandering")
local SlimeJumpController = require("src.entities.Monsters.Slime.SlimeJumpController")
local MonsterBehaviors = require("src.entities.Monsters.core.MonsterBehaviors")
local GameConstants = require("src.constants")

---@class Slime
local Slime = {}

---Custom state selector with hysteresis to prevent rapid state switching
local function slimeStateSelector(entity, dt)
    local EntityUtils = require("src.utils.entities")
    local stateMachine = entity:getComponent("StateMachine")
    local health = entity:getComponent("Health")
    local currentState = stateMachine:getCurrentState()

    -- Priority 1: Check if dead
    if health and health.current <= 0 then
        return "dying"
    end

    -- Priority 2: Update target and check for detection
    MonsterBehaviors.updateTarget(entity, SlimeConfig)
    local target = entity.target

    if target then
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

        local attackRange = SlimeConfig.ATTACK_RANGE_TILES * GameConstants.TILE_SIZE
        local hysteresis = (SlimeConfig.ATTACK_RANGE_HYSTERESIS or 0.3) * GameConstants.TILE_SIZE

        -- Use hysteresis: different thresholds for entering vs leaving attacking state
        if currentState == "attacking" then
            -- Stay in attacking until significantly out of range
            if dist <= attackRange + hysteresis then
                return "attacking"
            else
                return "chasing"
            end
        elseif currentState == "chasing" then
            -- Enter attacking when clearly in range
            if dist <= attackRange - hysteresis then
                return "attacking"
            else
                return "chasing"
            end
        else
            -- From other states, use standard threshold
            if dist <= attackRange then
                return "attacking"
            else
                return "chasing"
            end
        end
    end

    -- Priority 3: Default behavior (idle/wandering) when no target
    if currentState == "attacking" or currentState == "chasing" then
        return "idle"
    end

    -- Handle idle/wandering transitions
    if currentState == "idle" then
        local idleTime = stateMachine:getStateData("idleTime") or 0
        local targetIdleTime = stateMachine:getStateData("targetIdleTime") or 2
        if idleTime >= targetIdleTime then
            return "wandering"
        end
    elseif currentState == "wandering" then
        local pathfinding = entity:getComponent("Pathfinding")
        -- Check if wander target is reached (path is complete)
        if pathfinding and pathfinding:isPathComplete() then
            return "idle"
        end
    end

    return currentState
end

---Create a new slime enemy entity
---@param x number X position
---@param y number Y position
---@param world World The ECS world to add the slime to
---@param physicsWorld table|nil The physics world for collision
---@return Entity The created slime entity
function Slime.create(x, y, world, physicsWorld)
    -- Create shared jump controller for this slime instance
    local jumpController = SlimeJumpController.new()

    local monster = MonsterFactory.create({
        x = x,
        y = y,
        world = world,
        physicsWorld = physicsWorld,
        config = SlimeConfig,
        tag = "Slime",
        pathfindingOffsetY = SlimeConfig.SPRITE_HEIGHT - SlimeConfig.COLLIDER_HEIGHT - 24,
        physicsOffsetX = SlimeConfig.SPRITE_WIDTH / 2 - SlimeConfig.DRAW_WIDTH / 2,
        physicsOffsetY = SlimeConfig.SPRITE_HEIGHT / 2 - SlimeConfig.DRAW_HEIGHT / 2,
        -- Use custom states for ranged behavior and jump controller
        customStates = {
            idle = SlimeIdle.new(jumpController),
            chasing = SlimeChasing.new(jumpController),
            attacking = SlimeAttacking.new(jumpController),
            wandering = SlimeWandering.new(jumpController)
        },
        -- Use custom state selector with hysteresis
        stateSelector = slimeStateSelector
    })

    -- Store jump controller on entity for shared access
    monster.jumpController = jumpController

    return monster
end

return Slime

