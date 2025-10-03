---@class State
---Base class for all states in the state machine
local State = {}
State.__index = State

---Create a new state
---@return State
function State.new()
    local self = setmetatable({}, State)
    return self
end

---Called when entering this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function State:onEnter(stateMachine, entity)
    -- Override in subclasses
end

---Called every frame while in this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
---@param dt number Delta time
function State:onUpdate(stateMachine, entity, dt)
    -- Override in subclasses
end

---Called when exiting this state
---@param stateMachine StateMachine The state machine
---@param entity Entity The entity this state belongs to
function State:onExit(stateMachine, entity)
    -- Override in subclasses
end

return State
