local System = require("src.core.System")
local EventAnimations = require("src.utils.EventAnimations")

---@class EventSystem : System
---@field ecsWorld World
local EventSystem = System:extend("EventSystem", {})

function EventSystem.new(ecsWorld)
    ---@class EventSystem
    local self = System.new()
    setmetatable(self, EventSystem)
    self.ecsWorld = ecsWorld

    -- Listen for event destruction events
    local EventBus = require("src.utils.EventBus")
    EventBus.subscribe("destroyEvent", function(data)
        self:destroyEvent(data.event)
    end)

    -- Listen for upgrade selection (destroy event after upgrade is selected)
    EventBus.subscribe("upgradeSelected", function(data)
        self:destroyEvent(data.event)
    end)

    return self
end

function EventSystem:update(dt)
    -- Query entities with Event, Animator, and Position components
    for _, entity in ipairs(self.ecsWorld.entities) do
        if entity:hasComponent("Event") and entity:hasComponent("Animator") and entity:hasComponent("Position") then
            local eventComp = entity:getComponent("Event")
            local animator = entity:getComponent("Animator")

            -- Check if animation has finished and handle state transitions
            if not animator.playing then
                local currentState = eventComp:getState()

                if currentState == "spawning" then
                    -- Spawn animation finished, switch to idle
                    eventComp:setState("idle")
                    -- Switch to idle animation (frame 12)
                    animator:setAnimation(EventAnimations.get("idle"))

                elseif currentState == "activating" then
                    -- Activating animation finished, switch to active
                    eventComp:setState("active")
                    -- Switch to active animation (pulsing between frames 21-22)
                    animator:setAnimation(EventAnimations.get("active"))

                elseif currentState == "deactivating" then
                    -- Deactivating animation finished, switch to idle
                    eventComp:setState("idle")
                    -- Switch to idle animation (frame 12)
                    animator:setAnimation(EventAnimations.get("idle"))

                elseif currentState == "destroying" then
                    -- Destroy animation finished, mark as destroyed
                    eventComp:setState("destroyed")
                    -- Remove entity from world
                    self.ecsWorld:removeEntity(entity)
                end
            end
        end
    end
end

---Destroy an event entity
---@param eventEntity Entity The event entity to destroy
function EventSystem:destroyEvent(eventEntity)
    if not eventEntity or not eventEntity:hasComponent("Event") then
        return
    end

    local eventComp = eventEntity:getComponent("Event")
    local animator = eventEntity:getComponent("Animator")

    if not eventComp or not animator then
        return
    end

    if eventComp:getState() == "destroyed" then
        return -- Already destroyed
    end

    -- Change state to destroying
    eventComp:setState("destroying")

    -- Switch to destroy animation (frames 23-25)
    animator:setAnimation(EventAnimations.get("destroy"))
end

return EventSystem
