---@class Event
---@field eventType string The type of event (e.g., "Upgrade")
---@field state string Current state: "spawning", "idle", "activating", "active", "deactivating", "destroying", "destroyed"
---@field world World|nil Reference to ECS world for accessing player
local Event = {}
Event.__index = Event

---Create a new Event component
---@param eventType string The type of event (e.g., "Upgrade")
---@param world World|nil Optional reference to ECS world for finding player
---@return Component|Event
function Event.new(eventType, world)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("Event"), Event)

    self.eventType = eventType or "Upgrade"
    self.state = "spawning"
    self.world = world

    return self
end

---Get the event type
---@return string The event type
function Event:getType()
    return self.eventType
end

---Get the current state
---@return string The current state
function Event:getState()
    return self.state
end

---Set the current state
---@param state string The new state
function Event:setState(state)
    self.state = state
end

---Check if the event is destroyed
---@return boolean True if destroyed
function Event:isDestroyed()
    return self.state == "destroyed"
end

---Serialize the Event component for saving
---@return table Serialized event data
function Event:serialize()
    return {
        eventType = self.eventType,
        state = self.state
    }
end

---Deserialize Event component from saved data
---@param data table Serialized event data
---@return Component|Event Recreated Event component
function Event.deserialize(data)
    local event = Event.new(data.eventType, nil)
    event.state = data.state or "spawning"
    return event
end

return Event
