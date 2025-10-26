---@class GenericAttacking : State
---Generic attacking state for monsters - perform melee when in range
---@field config table Monster configuration
local GenericAttacking = {}
GenericAttacking.__index = GenericAttacking
setmetatable(GenericAttacking, {__index = require("src.core.State")})

local GameConstants = require("src.constants")

---Create a new generic attacking state
---@param config table Monster configuration (must have ATTACK_RANGE_TILES, and optionally ATTACK_ANIMATION)
---@return GenericAttacking The created attacking state
function GenericAttacking.new(config)
    local self = setmetatable({}, GenericAttacking)
    self.config = config
    return self
end

function GenericAttacking:onEnter(stateMachine, entity)
    -- Stop movement when starting attack
    local movement = entity:getComponent("Movement")
    if movement then
        movement.velocityX = 0
        movement.velocityY = 0
    end

    -- For frame-based attacks, set animation here
    -- For immediate attacks, animation will be set when attack is triggered
    local animator = entity:getComponent("Animator")
    if animator and self.config.ATTACK_ANIMATION then
        if self.config.ATTACK_ANIMATION.hitFrame then
            -- Frame-based attack: set animation immediately
            animator:setAnimation(self.config.ATTACK_ANIMATION)
        end
        -- For immediate attacks, animation will be set when attack is actually triggered
    end

    -- Reset attack trigger flag for frame-based attacks
    stateMachine:setStateData("hasTriggeredAttack", false)

    -- For frame-based attacks, capture the initial attack position and create collider
    if self.config.ATTACK_ANIMATION and self.config.ATTACK_ANIMATION.hitFrame then
        local position = entity:getComponent("Position")
        local pfc = entity:getComponent("PathfindingCollision")
        local ex, ey = (position and position.x) or 0, (position and position.y) or 0
        if pfc and pfc:hasCollider() then
            ex, ey = pfc:getCenterPosition()
        end

        -- Store the attack start position for consistent collider placement
        stateMachine:setStateData("attackStartX", ex)
        stateMachine:setStateData("attackStartY", ey)

        -- Calculate attack direction and hit area at attack start
        local target = entity.target or nil
        if target then
            local EntityUtils = require("src.utils.entities")
            local tx, ty = EntityUtils.getClosestPointOnTarget(ex, ey, target)
            local dx, dy = tx - ex, ty - ey

            local attack = entity:getComponent("Attack")
            if attack then
                attack:setDirection(dx, dy)

                -- Set hit area dimensions from config before calculating
                if self.config.ATTACK_HIT_WIDTH then
                    attack.hitAreaWidth = self.config.ATTACK_HIT_WIDTH
                end
                if self.config.ATTACK_HIT_HEIGHT then
                    attack.hitAreaHeight = self.config.ATTACK_HIT_HEIGHT
                end

                attack:calculateHitArea(ex, ey)

                -- Store hit area data for later use at hit frame
                stateMachine:setStateData("hitAreaX", attack.hitAreaX)
                stateMachine:setStateData("hitAreaY", attack.hitAreaY)
                stateMachine:setStateData("hitAreaWidth", attack.hitAreaWidth)
                stateMachine:setStateData("hitAreaHeight", attack.hitAreaHeight)
                stateMachine:setStateData("attackAngleRad", attack.attackAngleRad)
            end
        end
    end
end

function GenericAttacking:onUpdate(stateMachine, entity, dt)
    local position = entity:getComponent("Position")
    local attack = entity:getComponent("Attack")
    local movement = entity:getComponent("Movement")
    if not position or not attack then
        return
    end

    -- Use the entity's current target
    local target = entity.target or nil

    if not target or target.isDead then
        return
    end

    -- Compute direction to closest point on target
    local ex, ey = position.x, position.y
    local pfc = entity:getComponent("PathfindingCollision")
    if pfc and pfc:hasCollider() then
        ex, ey = pfc:getCenterPosition()
    end

    local EntityUtils = require("src.utils.entities")
    local tx, ty = EntityUtils.getClosestPointOnTarget(ex, ey, target)
    local dx, dy = tx - ex, ty - ey
    local dist = math.sqrt(dx*dx + dy*dy)

    -- For frame-based attacks, always stop movement during attack animation
    if self.config.ATTACK_ANIMATION and self.config.ATTACK_ANIMATION.hitFrame then
        -- Frame-based attack: stop movement completely during attack
        if movement then
            movement.velocityX = 0
            movement.velocityY = 0
        end
    else
        -- Immediate attack: check if we need to move closer to target or can attack
        local attackRange = (self.config.ATTACK_RANGE_TILES or 1.2) * (GameConstants.TILE_SIZE or 16)

        if dist <= attackRange then
            -- Close enough to attack - stop movement
            if movement then
                movement.velocityX = 0
                movement.velocityY = 0
            end
        else
            -- Too far to attack - move toward target
            if movement and dist > 0 then
                local desiredSpeed = movement.maxSpeed * 0.8
                movement.velocityX = (dx / dist) * desiredSpeed
                movement.velocityY = (dy / dist) * desiredSpeed
            end
        end
    end

    -- Handle frame-based or immediate attack timing
    local now = love.timer.getTime()
    local animator = entity:getComponent("Animator")
    local stateMachine = entity:getComponent("StateMachine")
    local hasTriggeredAttack = stateMachine and stateMachine:getStateData("hasTriggeredAttack") or false

    -- Check if we should trigger attack based on timing method
    local shouldTriggerAttack = false

    if self.config.ATTACK_ANIMATION and self.config.ATTACK_ANIMATION.hitFrame and animator then
        -- Frame-based attack timing
        local currentFrame = animator:getCurrentFrame()
        local targetFrame = self.config.ATTACK_ANIMATION.frames[self.config.ATTACK_ANIMATION.hitFrame + 1] -- Convert 0-indexed to 1-indexed
        shouldTriggerAttack = (currentFrame == targetFrame) and attack:isReady(now) and not hasTriggeredAttack
    else
        -- Immediate attack timing (backwards compatible)
        local attackRange = (self.config.ATTACK_RANGE_TILES or 1.2) * (GameConstants.TILE_SIZE or 16)
        shouldTriggerAttack = dist <= attackRange and attack:isReady(now)
    end

    if shouldTriggerAttack then
        -- For frame-based attacks, create collider and trigger damage
        if self.config.ATTACK_ANIMATION and self.config.ATTACK_ANIMATION.hitFrame then
            -- Retrieve stored hit area data
            local hitAreaX = stateMachine and stateMachine:getStateData("hitAreaX") or 0
            local hitAreaY = stateMachine and stateMachine:getStateData("hitAreaY") or 0
            local hitAreaWidth = stateMachine and stateMachine:getStateData("hitAreaWidth") or 0
            local hitAreaHeight = stateMachine and stateMachine:getStateData("hitAreaHeight") or 0
            local attackAngleRad = stateMachine and stateMachine:getStateData("attackAngleRad") or nil

            -- Create collider at hit frame with stored position
            local AttackCollider = require("src.components.AttackCollider")
            local pfc = entity:getComponent("PathfindingCollision")
            local attackerPhys = entity:getComponent("PhysicsCollision")
            local physicsWorld = attackerPhys and attackerPhys.physicsWorld or (pfc and pfc.physicsWorld) or nil

            if physicsWorld then
                local ac = AttackCollider.new(entity, attack.damage, attack.knockback, 0.3)
                ac:createFixture(physicsWorld, hitAreaX, hitAreaY, hitAreaWidth, hitAreaHeight)
                if attackAngleRad and ac.setAngle then
                    ac:setAngle(attackAngleRad)
                end
                entity:addComponent("AttackCollider", ac)
            end

            attack:performAttack(now)
            if stateMachine then
                stateMachine:setStateData("hasTriggeredAttack", true)
            end
        else
            -- Immediate attack: create collider and trigger damage
            attack:setDirection(dx, dy)
            attack:calculateHitArea(ex, ey)

            local AttackCollider = require("src.components.AttackCollider")
            local attackerPhys = entity:getComponent("PhysicsCollision")
            local physicsWorld = attackerPhys and attackerPhys.physicsWorld or (pfc and pfc.physicsWorld) or nil
            if physicsWorld then
                local ac = AttackCollider.new(entity, attack.damage, attack.knockback, 0.5) -- 500ms for debugging
                ac:createFixture(physicsWorld, attack.hitAreaX, attack.hitAreaY, attack.hitAreaWidth, attack.hitAreaHeight)
                -- Rotate collider to face the player
                if attack.attackAngleRad and ac.setAngle then
                    ac:setAngle(attack.attackAngleRad)
                end
                entity:addComponent("AttackCollider", ac)
                attack:performAttack(now)

                -- Debug: Print when attack collider is created
                print("Immediate attack collider created at", ex, ey, "with size", attack.hitAreaWidth, "x", attack.hitAreaHeight)
            end
        end
    end

    -- For frame-based attacks, check if animation has completed and we should transition out
    if self.config.ATTACK_ANIMATION and self.config.ATTACK_ANIMATION.hitFrame and animator then
        -- If animation is not looping and has finished playing, allow state transition
        if not self.config.ATTACK_ANIMATION.loop and not animator.playing then
            -- Animation completed - the state machine will transition based on distance in MonsterBehaviors.selectState
            -- This allows the monster to return to chasing/idle after the attack animation finishes
        end
    end
end


return GenericAttacking

