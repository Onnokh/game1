---@class Idle : State
---Idle state for warhog
local Idle = {}
Idle.__index = Idle
setmetatable(Idle, {__index = require("src.core.State")})

local WarhogConfig = require("src.entities.Monsters.Warhog.WarhogConfig")

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

    -- Set idle animation when entering state
    local animator = entity:getComponent("Animator")
    if animator then
        animator:setAnimation(WarhogConfig.IDLE_ANIMATION)
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Idle:onUpdate(stateMachine, entity, dt)
    -- Update idle timer
    local idleTime = stateMachine:getStateData("idleTime") or 0
    stateMachine:setStateData("idleTime", idleTime + dt)

    -- Stop movement
    local movement = entity:getComponent("Movement")
    if movement then
        movement.velocityX = 0
        movement.velocityY = 0
    end
end

return Idle
