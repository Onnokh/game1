---@class GenericWandering : State
---Generic wandering state for monsters
local GenericWandering = {}
GenericWandering.__index = GenericWandering
setmetatable(GenericWandering, {__index = require("src.core.State")})

---Create a new generic wandering state
---@param config table Monster configuration (must have WALKING_ANIMATION)
---@return GenericWandering The created wandering state
function GenericWandering.new(config)
    local self = setmetatable({}, GenericWandering)
    self.config = config
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function GenericWandering:onEnter(stateMachine, entity)
    -- Set walking animation when entering state
    local animator = entity:getComponent("Animator")
    if animator and self.config.WALKING_ANIMATION then
        animator:setAnimation(self.config.WALKING_ANIMATION)
    end

    -- Get wander path
    local pathfinding = entity:getComponent("Pathfinding")
    local position = entity:getComponent("Position")
    if pathfinding and position then
        -- Use current position for pathfinding
        local currentX, currentY = position.x, position.y

        -- Check if we have pathfinding collision component for more accurate position
        local pathfindingCollision = entity:getComponent("PathfindingCollision")
        if pathfindingCollision and pathfindingCollision:hasCollider() then
            currentX, currentY = pathfindingCollision:getCenterPosition()
        end

        -- Start a new wander from current position
        pathfinding:startWander(currentX, currentY)
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function GenericWandering:onUpdate(stateMachine, entity, dt)
    local pathfinding = entity:getComponent("Pathfinding")
    local movement = entity:getComponent("Movement")
    local spriteRenderer = entity:getComponent("SpriteRenderer")

    -- Handle sprite flipping based on movement direction
    if movement and spriteRenderer then
        if movement.velocityX < -0.1 then
            -- Moving left, flip sprite horizontally
            spriteRenderer.scaleX = -1
        elseif movement.velocityX > 0.1 then
            -- Moving right, normal orientation
            spriteRenderer.scaleX = 1
        end
        -- If velocityX is very small, keep current orientation
    end

    -- Check if we've reached the wander target
    if pathfinding and pathfinding:isPathComplete() and movement then
        -- Clear the current path to allow new wandering
        pathfinding.currentPath = nil
        pathfinding.currentPathIndex = 1
        -- Start a new wander from current position
        local position = entity:getComponent("Position")
        if position then
            local currentX, currentY = position.x, position.y
            local pathfindingCollision = entity:getComponent("PathfindingCollision")
            if pathfindingCollision and pathfindingCollision:hasCollider() then
                currentX, currentY = pathfindingCollision:getCenterPosition()
            end
            pathfinding:startWander(currentX, currentY)
        end
    end
end

return GenericWandering

