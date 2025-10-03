---@class StateMachine
---@field currentState string
---@field states table
---@field stateData table
---@field enabled boolean
---@field initialized boolean
---@field stateSelector function|nil
---@field autoTransitions boolean
---Simple reusable state machine component
local StateMachine = {}
StateMachine.__index = StateMachine

---Create a new StateMachine component
---@param initialState string|nil Initial state name
---@param config table|nil Configuration table with states and stateSelector function
---@return Component|StateMachine
function StateMachine.new(initialState, config)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("StateMachine"), StateMachine)

    self.currentState = initialState or "idle"
    self.states = {}
    self.stateData = {}
    self.enabled = true
    self.initialized = false -- Track if we've called onEnter for initial state
    self.locked = false -- Prevent transitions when locked

    -- Dynamic state configuration
    self.config = config or {}
    self.stateSelector = self.config.stateSelector -- Function that determines desired state
    self.autoTransitions = self.config.autoTransitions ~= false and self.stateSelector ~= nil -- Enable automatic transitions by default if stateSelector is provided

    return self
end

---Add a state to the state machine
---@param stateName string Name of the state
---@param stateInstance State The state instance
function StateMachine:addState(stateName, stateInstance)
    self.states[stateName] = {
        instance = stateInstance,
        transitions = {}
    }

    -- Initialize state data
    if not self.stateData[stateName] then
        self.stateData[stateName] = {}
    end

    -- If auto transitions are enabled and we have a state selector, add transitions
    if self.autoTransitions and self.stateSelector then
        self:addTransitionsForNewState(stateName)
    end
end

---Set the state selector function and enable auto transitions
---@param selector function Function that determines the desired state
function StateMachine:setStateSelector(selector)
    self.stateSelector = selector
    self.autoTransitions = true
end

---Add a transition between states
---@param fromState string Source state name
---@param toState string Target state name
---@param condition function Function that returns true when transition should occur
function StateMachine:addTransition(fromState, toState, condition)
    if not self.states[fromState] then
        error("State '" .. fromState .. "' does not exist")
    end

    if not self.states[toState] then
        error("State '" .. toState .. "' does not exist")
    end

    table.insert(self.states[fromState].transitions, {
        toState = toState,
        condition = condition
    })
end

---Add transitions for a new state to all existing states
---@param newStateName string Name of the new state
function StateMachine:addTransitionsForNewState(newStateName)
    -- Add transitions from all existing states to the new state
    for existingStateName, _ in pairs(self.states) do
        if existingStateName ~= newStateName then
            self:addTransition(existingStateName, newStateName, function(self, entity, dt)
                local desiredState = self.stateSelector(entity, dt)
                return desiredState == newStateName and desiredState ~= self.currentState
            end)

            -- Add transition from new state to existing state
            self:addTransition(newStateName, existingStateName, function(self, entity, dt)
                local desiredState = self.stateSelector(entity, dt)
                return desiredState == existingStateName and desiredState ~= self.currentState
            end)
        end
    end
end

---Set up automatic transitions based on state selector function
---@param stateNames table|nil Array of state names to create transitions between (optional - uses all added states if not provided)
function StateMachine:setupAutoTransitions(stateNames)
    if not self.stateSelector then
        error("StateMachine: stateSelector function must be provided for auto transitions")
    end

    self.autoTransitions = true

    -- Use provided state names or get all added states
    local states = stateNames or {}
    if not stateNames then
        for stateName, _ in pairs(self.states) do
            table.insert(states, stateName)
        end
    end

    -- Create transitions between all states
    for _, fromState in ipairs(states) do
        for _, toState in ipairs(states) do
            if fromState ~= toState then
                self:addTransition(fromState, toState, function(self, entity, dt)
                    local desiredState = self.stateSelector(entity, dt)
                    return desiredState == toState and desiredState ~= self.currentState
                end)
            end
        end
    end
end

---Change to a new state
---@param newState string Name of the new state
---@param entity Entity The entity (for onEnter callback)
function StateMachine:changeState(newState, entity)
    if not self.states[newState] then
        error("State '" .. newState .. "' does not exist")
    end

    if self.currentState == newState then
        return -- Already in this state
    end

    -- Log state change with entity information
    local entityInfo = entity and entity.id and ("Entity ID: " .. entity.id) or "Unknown Entity"
    print("StateMachine: " .. self.currentState .. " -> " .. newState .. " (" .. entityInfo .. ")")

    -- Call onExit for current state
    local currentStateConfig = self.states[self.currentState]
    if currentStateConfig and currentStateConfig.instance and currentStateConfig.instance.onExit then
        currentStateConfig.instance:onExit(self, entity)
    end

    -- Change state
    local previousState = self.currentState
    self.currentState = newState

    -- Call onEnter for new state
    local newStateConfig = self.states[newState]
    if newStateConfig and newStateConfig.instance and newStateConfig.instance.onEnter then
        newStateConfig.instance:onEnter(self, entity)
    end
end

---Update the current state
---@param dt number Delta time
---@param entity Entity The entity this state machine belongs to
function StateMachine:update(dt, entity)
    if not self.enabled then return end

    local currentStateConfig = self.states[self.currentState]
    if not currentStateConfig then return end

    -- Call onEnter for initial state if not yet initialized
    if not self.initialized then
        if currentStateConfig.instance and currentStateConfig.instance.onEnter then
            currentStateConfig.instance:onEnter(self, entity)
        end
        self.initialized = true
    end

    -- Update global cooldowns
    if self.globalData then
        for key, value in pairs(self.globalData) do
            if type(value) == "number" and value > 0 and key:match("Cooldown$") then
                self.globalData[key] = value - dt
                if self.globalData[key] < 0 then
                    self.globalData[key] = 0
                end
            end
        end
    end

    -- Check for state transitions (only if not locked)
    if not self.locked then
        for _, transition in ipairs(currentStateConfig.transitions) do
            if transition.condition(self, entity, dt) then
                self:changeState(transition.toState, entity)
                break -- Only transition once per update
            end
        end
    end

    -- Update current state
    if currentStateConfig.instance and currentStateConfig.instance.onUpdate then
        currentStateConfig.instance:onUpdate(self, entity, dt)
    end
end

---Get current state data
---@param key string|nil Specific key to get, or nil for all data
---@return table|any State data
function StateMachine:getStateData(key)
    if key then
        return self.stateData[self.currentState] and self.stateData[self.currentState][key]
    else
        return self.stateData[self.currentState] or {}
    end
end

---Set current state data
---@param key string Data key
---@param value any Data value
function StateMachine:setStateData(key, value)
    if not self.stateData[self.currentState] then
        self.stateData[self.currentState] = {}
    end
    self.stateData[self.currentState][key] = value
end

---Set global data (accessible from all states)
---@param key string Data key
---@param value any Data value
function StateMachine:setGlobalData(key, value)
    if not self.globalData then
        self.globalData = {}
    end
    self.globalData[key] = value
end

---Get global data (accessible from all states)
---@param key string|nil Data key, or nil for all global data
---@return any Global data
function StateMachine:getGlobalData(key)
    if not self.globalData then
        return nil
    end
    if key then
        return self.globalData[key]
    else
        return self.globalData
    end
end

---Get the current state name
---@return string Current state name
function StateMachine:getCurrentState()
    return self.currentState
end

---Lock the state machine to prevent transitions
function StateMachine:lock()
    self.locked = true
end

---Unlock the state machine to allow transitions
function StateMachine:unlock()
    self.locked = false
end

---Check if the state machine is locked
---@return boolean True if locked
function StateMachine:isLocked()
    return self.locked
end

return StateMachine
