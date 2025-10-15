---@class Idle : State
---Idle state for player
local Idle = {}
Idle.__index = Idle
setmetatable(Idle, {__index = require("src.core.State")})

local PlayerConfig = require("src.entities.Player.PlayerConfig")
local SoundManager = require("src.core.managers.SoundManager")

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

    -- Set idle animation when entering state
    local animator = entity:getComponent("Animator")
    if animator then
        animator:setAnimation(PlayerConfig.IDLE_ANIMATION)
    end

    -- Stop any movement sound when entering idle (single global reference)
    local movementSound = stateMachine:getGlobalData("movementSound")
    if movementSound then
        movementSound:stop()
        stateMachine:setGlobalData("movementSound", nil)
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function Idle:onUpdate(stateMachine, entity, dt)
    local idleTime = stateMachine:getStateData("idleTime") or 0
    stateMachine:setStateData("idleTime", idleTime + dt)
end

return Idle
