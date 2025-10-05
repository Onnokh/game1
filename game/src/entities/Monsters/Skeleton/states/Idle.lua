---@class Idle : State
---Idle state for skeleton
local Idle = {}
Idle.__index = Idle
setmetatable(Idle, {__index = require("src.core.State")})

local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")

---@return Idle The created idle state
function Idle.new()
    local self = setmetatable({}, Idle)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function Idle:onEnter(stateMachine, entity)
    stateMachine:setStateData("idleTime", 0)
    stateMachine:setStateData("targetIdleTime", math.random(1, 5)) -- Random idle time between 1-3 seconds

    -- Create and set idle animation when entering state
    if entity then
        local Animator = require("src.components.Animator")
        local animator = entity:getComponent("Animator")

        if not animator then
            -- Create animator if it doesn't exist
            animator = Animator.new("skeleton", SkeletonConfig.IDLE_ANIMATION.frames, SkeletonConfig.IDLE_ANIMATION.fps, SkeletonConfig.IDLE_ANIMATION.loop)
            entity:addComponent("Animator", animator)
        else
            animator:setAnimation(SkeletonConfig.IDLE_ANIMATION.frames, SkeletonConfig.IDLE_ANIMATION.fps, SkeletonConfig.IDLE_ANIMATION.loop)
        end
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Idle:onUpdate(stateMachine, entity, dt)
    local idleTime = stateMachine:getStateData("idleTime") or 0
    local targetIdleTime = stateMachine:getStateData("targetIdleTime") or 2
    stateMachine:setStateData("idleTime", idleTime + dt)

    -- Check for player in chase range with line-of-sight
    local entityPos = entity:getComponent("Position")
    local pfc = entity:getComponent("PathfindingCollision")
    local sx, sy = entityPos and entityPos.x or 0, entityPos and entityPos.y or 0
    if pfc and pfc:hasCollider() then
        sx, sy = pfc:getCenterPosition()
    end
    local world = entity._world
    if world then
        local player
        for _, e in ipairs(world.entities) do
            if e.isPlayer then player = e break end
        end
        if player then
            local playerPos = player:getComponent("Position")
            if playerPos then
                local GameConstants = require("src.constants")
                local SkeletonConfig = require("src.entities.Monsters.Skeleton.SkeletonConfig")
                local chaseRange = (SkeletonConfig.CHASE_RANGE or 8) * (GameConstants.TILE_SIZE or 16)
                local dx = playerPos.x - sx
                local dy = playerPos.y - sy
                local dist = math.sqrt(dx*dx+dy*dy)
                if dist <= chaseRange then
                    if not pfc or pfc:hasLineOfSightTo(playerPos.x, playerPos.y, nil) then
                        stateMachine:changeState("chasing", entity)
                        return
                    end
                end
            end
        end
    end

    -- After random amount of time idling, start wandering
    if idleTime > targetIdleTime then
        stateMachine:changeState("wandering", entity)
    end
end

return Idle
