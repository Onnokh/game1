---@class GenericChasing : State
---Generic chasing state for monsters - pursue the target using direct line of sight
local GenericChasing = {}
GenericChasing.__index = GenericChasing
setmetatable(GenericChasing, {__index = require("src.core.State")})

local GameConstants = require("src.constants")

---Create a new generic chasing state
---@param config table Monster configuration (must have WALKING_ANIMATION and ATTACK_RANGE_TILES)
---@return GenericChasing The created chasing state
function GenericChasing.new(config)
    local self = setmetatable({}, GenericChasing)
    self.config = config
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function GenericChasing:onEnter(stateMachine, entity)
    -- Set walk animation
    local animator = entity:getComponent("Animator")
    if animator and self.config.WALKING_ANIMATION then
        animator:setAnimation(self.config.WALKING_ANIMATION)
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function GenericChasing:onUpdate(stateMachine, entity, dt)
    local position = entity:getComponent("Position")
    local movement = entity:getComponent("Movement")
    local pathfinding = entity:getComponent("Pathfinding")
    local pathfindingCollision = entity:getComponent("PathfindingCollision")

    -- Use the entity's current target
    local target = entity.target

    if not target or target.isDead or not position or not movement or not pathfinding then
        return
    end

    -- Current world positions (use collider center if available)
    local sx, sy = position.x, position.y
    if pathfindingCollision and pathfindingCollision:hasCollider() then
        sx, sy = pathfindingCollision:getCenterPosition()
    end

    -- Get closest point on target's collider
    local EntityUtils = require("src.utils.entities")
    local tx, ty = EntityUtils.getClosestPointOnTarget(sx, sy, target)

    -- Decide steering: direct follow if line-of-sight; otherwise end chase
    -- Exception: reactor doesn't need line of sight (static structure)
    local directLOS = false
    if target:hasTag("Reactor") then
        directLOS = true -- Always chase reactor
    elseif pathfindingCollision and pathfindingCollision:hasCollider() then
        directLOS = pathfindingCollision:hasLineOfSightTo(tx, ty, nil)
    else
        directLOS = true
    end

    if directLOS then
        -- Direct chase: set velocity straight towards target
        local dx = tx - sx
        local dy = ty - sy
        local dist = math.sqrt(dx*dx + dy*dy)

        -- Determine stop range and preferred range based on behavior config
        local tileSize = (GameConstants.TILE_SIZE or 16)
        local stopRange = (self.config.ATTACK_RANGE_TILES or 0.8) * tileSize

        -- Support for ranged behavior: maintain distance from target
        local preferredRange = self.config.PREFERRED_CHASE_RANGE_TILES
        if preferredRange then
            preferredRange = preferredRange * tileSize

            if dist <= stopRange then
                -- Too close, move away
                movement.velocityX = 0
                movement.velocityY = 0
            elseif dist < preferredRange then
                -- Too close to preferred range, move away from target
                if dist > 0 then
                    local desiredSpeed = movement.maxSpeed * 0.6
                    movement.velocityX = -(dx / dist) * desiredSpeed
                    movement.velocityY = -(dy / dist) * desiredSpeed
                end
            elseif dist > preferredRange + tileSize then
                -- Too far from preferred range, move toward target
                if dist > 0 then
                    local desiredSpeed = movement.maxSpeed * 0.9
                    movement.velocityX = (dx / dist) * desiredSpeed
                    movement.velocityY = (dy / dist) * desiredSpeed
                end
            else
                -- Within acceptable range, stop moving
                movement.velocityX = 0
                movement.velocityY = 0
            end
        else
            -- Default melee behavior: chase until in attack range
            if dist <= stopRange then
                movement.velocityX = 0
                movement.velocityY = 0
            else
                if dist > 0 then
                    local desiredSpeed = movement.maxSpeed * 0.9
                    movement.velocityX = (dx / dist) * desiredSpeed
                    movement.velocityY = (dy / dist) * desiredSpeed
                end
            end
        end
        -- Clear any existing path to avoid PathfindingSystem steering
        pathfinding.currentPath = nil
        pathfinding.pathIndex = 1
        -- Set target for debug overlay
        pathfinding.targetX = tx
        pathfinding.targetY = ty
    else
        -- No LOS: stop chasing immediately
        pathfinding.currentPath = nil
        pathfinding.pathIndex = 1
        movement.velocityX = 0
        movement.velocityY = 0
    end

    -- Speed tweak: move faster than wandering
    if movement then
        movement.maxSpeed = GameConstants.PLAYER_SPEED -- match player speed
    end

    -- Flip sprite based on movement set by PathfindingSystem
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer and movement then
        if movement.velocityX < -0.1 then
            spriteRenderer.scaleX = -1
        elseif movement.velocityX > 0.1 then
            spriteRenderer.scaleX = 1
        end
    end
end

return GenericChasing

