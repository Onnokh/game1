---@class SlimeWandering : State
---@field jumpController SlimeJumpController Shared jump controller
---Wandering state for slime - wander around randomly
local Wandering = {}
Wandering.__index = Wandering
setmetatable(Wandering, {__index = require("src.core.State")})

local SlimeConfig = require("src.entities.Monsters.Slime.SlimeConfig")

---@param jumpController SlimeJumpController Shared jump controller
---@return SlimeWandering The created wandering state
function Wandering.new(jumpController)
    local self = setmetatable({}, Wandering)
    self.jumpController = jumpController
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Wandering:onEnter(stateMachine, entity)
    local jc = self.jumpController

    if jc:isCurrentlyJumping() then
        -- Mid-jump transition - preserve the jump
        print(string.format("[SLIME %d] Entered WANDERING state MID-JUMP", entity.id))
    else
        -- Normal wandering - pick a new wander target
        local pathfinding = entity:getComponent("Pathfinding")
        local position = entity:getComponent("Position")
        if pathfinding and position then
            local currentX, currentY = position.x, position.y

            -- Use pathfinding collision center if available
            local pathfindingCollision = entity:getComponent("PathfindingCollision")
            if pathfindingCollision and pathfindingCollision:hasCollider() then
                currentX, currentY = pathfindingCollision:getCenterPosition()
            end

            pathfinding:startWander(currentX, currentY)

            print(string.format("[SLIME %d] Entered WANDERING state, target=(%.1f, %.1f), current=(%.1f, %.1f)",
                entity.id, pathfinding.targetX or -1, pathfinding.targetY or -1, currentX, currentY))
        end

        -- Reset to ready so slime can jump immediately when wandering starts
        jc:resetToReady()

        -- Set idle animation (will change to walking when jump starts)
        local animator = entity:getComponent("Animator")
        if animator then
            animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Wandering:onUpdate(stateMachine, entity, dt)
    local jc = self.jumpController
    local movement = entity:getComponent("Movement")
    local pathfinding = entity:getComponent("Pathfinding")
    local position = entity:getComponent("Position")
    local animator = entity:getComponent("Animator")

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

    if not position or not movement or not pathfinding then
        return
    end

    -- Update jump timer every frame (for cooldown tracking)
    jc:update(dt)

    -- Clear pathfinding path to prevent PathfindingSystem from applying velocity
    -- We handle movement manually via jumping
    local wanderTarget = {x = pathfinding.targetX, y = pathfinding.targetY}
    pathfinding.currentPath = nil
    pathfinding.pathIndex = 1

    -- Get current position
    local sx, sy = position.x, position.y
    local pathfindingCollision = entity:getComponent("PathfindingCollision")
    if pathfindingCollision and pathfindingCollision:hasCollider() then
        sx, sy = pathfindingCollision:getCenterPosition()
    end

    -- Jumping behavior for wandering
    if jc:isJumpFinished() then
        -- Jump finished
        print(string.format("[SLIME %d] Wander-Jump FINISHED", entity.id))
        jc:finishJump()
        movement.velocityX = 0
        movement.velocityY = 0

        if animator then
            animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
        end
    elseif jc:isCurrentlyJumping() then
        -- Continue jump
        local vx, vy = jc:getJumpVelocity()
        movement.velocityX = vx
        movement.velocityY = vy
        print(string.format("[SLIME %d] Wander-Jumping: timer=%.2fs/%.2fs, vel=(%.1f, %.1f)",
            entity.id, jc.jumpTimer, jc.jumpDuration, vx, vy))
    else
        -- Not jumping - check if we should jump toward wander target
        if wanderTarget.x and wanderTarget.y then
            local dx = wanderTarget.x - sx
            local dy = wanderTarget.y - sy
            local dist = math.sqrt(dx*dx + dy*dy)
            local tileSize = require("src.constants").TILE_SIZE
            local minJumpDistance = tileSize * SlimeConfig.MIN_JUMP_DISTANCE

            -- If close enough to target (within min jump distance), we're done wandering
            if dist < minJumpDistance then
                print(string.format("[SLIME %d] Wander COMPLETE, dist=%.2f tiles < min", entity.id, dist / tileSize))
                movement.velocityX = 0
                movement.velocityY = 0
                -- Mark wander as complete by clearing target
                pathfinding.targetX = nil
                pathfinding.targetY = nil

                if animator then
                    animator:setAnimation(SlimeConfig.IDLE_ANIMATION)
                end
            elseif jc:canJump() then
                -- Jump toward wander target
                jc:startJump(dx, dy, dist, tileSize, false)

                print(string.format("[SLIME %d] Wander-Jump START, dist=%.2f tiles, canJump=%s",
                    entity.id, dist / tileSize, tostring(jc:canJump())))

                if animator then
                    animator:setAnimation(SlimeConfig.WALKING_ANIMATION)
                end
            else
                -- Waiting for cooldown
                print(string.format("[SLIME %d] Wander WAITING for cooldown (%.2fs / %.2fs)",
                    entity.id, jc.jumpTimer, jc.jumpCooldown))
                movement.velocityX = 0
                movement.velocityY = 0
            end
        else
            -- No wander target
            print(string.format("[SLIME %d] Wander NO TARGET (tx=%s, ty=%s)",
                entity.id, tostring(pathfinding.targetX), tostring(pathfinding.targetY)))
            movement.velocityX = 0
            movement.velocityY = 0
        end
    end

    -- Handle sprite flipping based on jump direction
    if spriteRenderer and jc.jumpDirectionX then
        if jc.jumpDirectionX < -0.1 then
            spriteRenderer.scaleX = -1
        elseif jc.jumpDirectionX > 0.1 then
            spriteRenderer.scaleX = 1
        end
    end
end

return Wandering

