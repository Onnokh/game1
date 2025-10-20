---@class SlimeChasing : State
---@field jumpController SlimeJumpController Shared jump controller
---Chasing state for slime - pursue the player using pathfinding with jumping behavior
local Chasing = {}
Chasing.__index = Chasing
setmetatable(Chasing, {__index = require("src.core.State")})

local SlimeConfig = require("src.entities.Monsters.Slime.SlimeConfig")
local GameConstants = require("src.constants")

---@param jumpController SlimeJumpController Shared jump controller
---@return SlimeChasing The created chasing state
function Chasing.new(jumpController)
    local self = setmetatable({}, Chasing)
    self.jumpController = jumpController
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Chasing:onEnter(stateMachine, entity)
    local jc = self.jumpController
    local timerBefore = jc.jumpTimer
    local animator = entity:getComponent("Animator")

    if jc:isCurrentlyJumping() then
        -- Preserve ongoing jump - ensure walking animation is active
        if animator then
            animator:setAnimation(SlimeConfig.WALKING_ANIMATION)
        end
    else
        -- Start with idle animation
        if animator then
            animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
        end
        -- Set ready to jump immediately when needed (only if out of combat)
        jc:resetToReady()
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Chasing:onUpdate(stateMachine, entity, dt)
    local position = entity:getComponent("Position")
    local movement = entity:getComponent("Movement")
    local pathfinding = entity:getComponent("Pathfinding")
    local pathfindingCollision = entity:getComponent("PathfindingCollision")
    local animator = entity:getComponent("Animator")

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
    local directLOS = false
    if pathfindingCollision and pathfindingCollision:hasCollider() then
        directLOS = pathfindingCollision:hasLineOfSightTo(tx, ty, nil)
    else
        directLOS = true
    end

    -- Clear any existing path to avoid PathfindingSystem steering
    pathfinding.currentPath = nil
    pathfinding.pathIndex = 1
    pathfinding.targetX = tx
    pathfinding.targetY = ty

    -- Calculate distances and tile size at the function level
    local dx = tx - sx
    local dy = ty - sy
    local dist = math.sqrt(dx*dx + dy*dy)
    local tileSize = GameConstants.TILE_SIZE

    local jc = self.jumpController

    -- Update jump timer every frame (for cooldown tracking)
    jc:update(dt)

    -- Apply sprite Y offset for jump arc visual effect
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        spriteRenderer.offsetY = jc:getSpriteYOffset()
    end

    -- Apply shadow scale for jump effect
    local groundShadow = entity:getComponent("GroundShadow")
    if groundShadow then
        local scale = jc:getShadowScale()
        groundShadow.widthFactor = 0.9 * scale
        groundShadow.heightFactor = 0.2 * scale
    end

    if directLOS then

        local preferredRange = SlimeConfig.PREFERRED_CHASE_RANGE_TILES * tileSize
        local tolerance = tileSize * 0.3

        -- Determine desired direction based on distance
        local shouldMove = false
        local moveAwayFromTarget = false
        local attackRange = SlimeConfig.ATTACK_RANGE_TILES * tileSize

        if dist < preferredRange - tolerance then
            -- Too close - jump away
            shouldMove = true
            moveAwayFromTarget = true
        elseif dist > preferredRange + tolerance then
            -- Too far - jump toward
            shouldMove = true
            moveAwayFromTarget = false
        elseif dist > attackRange then
            -- Outside attack range but within tolerance - still try to get closer
            shouldMove = true
            moveAwayFromTarget = false
        else
            -- Within acceptable range - stay idle
            shouldMove = false
        end

        -- Jumping behavior
        if jc:isJumpFinished() then
            -- Jump finished - enter cooldown
            jc:finishJump()
            movement.velocityX = 0
            movement.velocityY = 0

            -- Switch to idle animation
            if animator then
                animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
            end
        elseif jc:isCurrentlyJumping() then
            -- Apply jump velocity
            local vx, vy = jc:getJumpVelocity()
            movement.velocityX = vx
            movement.velocityY = vy
        elseif shouldMove and jc:canJump() then
            -- Start new jump
            jc:startJump(dx, dy, dist, tileSize, moveAwayFromTarget)

            -- Switch to jump animation (using walking animation)
            if animator then
                animator:setAnimation(SlimeConfig.WALKING_ANIMATION)
            end
        else
            -- Waiting between jumps
            movement.velocityX = 0
            movement.velocityY = 0
        end

        -- Flip sprite based on direction
        if spriteRenderer and jc.jumpDirectionX then
            if jc.jumpDirectionX < -0.1 then
                spriteRenderer.scaleX = -1
            elseif jc.jumpDirectionX > 0.1 then
                spriteRenderer.scaleX = 1
            end
        end
    else
        -- No LOS: stop and reset jump state
        movement.velocityX = 0
        movement.velocityY = 0
        if jc:isCurrentlyJumping() then
            jc:finishJump()
        end

        if animator then
            animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
        end
    end
end

return Chasing


