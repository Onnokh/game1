---@class GenericIdle : State
---Generic idle state for monsters
local GenericIdle = {}
GenericIdle.__index = GenericIdle
setmetatable(GenericIdle, {__index = require("src.core.State")})

---Create a new generic idle state
---@param config table Monster configuration (must have IDLE_ANIMATION)
---@return GenericIdle The created idle state
function GenericIdle.new(config)
    local self = setmetatable({}, GenericIdle)
    self.config = config
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function GenericIdle:onEnter(stateMachine, entity)
    stateMachine:setStateData("idleTime", 0)
    stateMachine:setStateData("targetIdleTime", math.random(1, 5)) -- Random idle time between 1-5 seconds

    -- Set idle animation when entering state
    local animator = entity:getComponent("Animator")
    if animator and self.config.IDLE_ANIMATION then
        animator:setAnimation(self.config.IDLE_ANIMATION)
    end
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function GenericIdle:onUpdate(stateMachine, entity, dt)
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

return GenericIdle

