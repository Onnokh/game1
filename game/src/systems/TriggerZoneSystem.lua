local System = require("src.core.System")

---@class TriggerZoneSystem : System
---@field physicsWorld love.World|nil
local TriggerZoneSystem = System:extend("TriggerZoneSystem", {"Position"})

---Initialize when world is set
function TriggerZoneSystem:setWorld(world)
    System.setWorld(self, world) -- Call parent setWorld
    -- Cache physics world reference for convenience
    self.physicsWorld = world and world.physicsWorld or nil
    -- Note: We don't set up our own callbacks here to avoid conflicts with CollisionSystem
    -- Instead, we'll be called by CollisionSystem when trigger contacts occur
end

---Handle trigger zone contact events
---@param fixtureA love.Fixture First fixture in contact
---@param fixtureB love.Fixture Second fixture in contact
---@param isBegin boolean True if contact is beginning, false if ending
function TriggerZoneSystem:handleTriggerContact(fixtureA, fixtureB, isBegin)
    local ua = fixtureA and fixtureA:getUserData() or nil
    local ub = fixtureB and fixtureB:getUserData() or nil

    -- Check if either fixture is a trigger zone
    local triggerFixture, otherFixture, triggerUserData, otherUserData
    if ua and type(ua) == "table" and ua.kind == "trigger" then
        triggerFixture = fixtureA
        otherFixture = fixtureB
        triggerUserData = ua
        otherUserData = ub
    elseif ub and type(ub) == "table" and ub.kind == "trigger" then
        triggerFixture = fixtureB
        otherFixture = fixtureA
        triggerUserData = ub
        otherUserData = ua
    else
        return -- Neither fixture is a trigger
    end

    -- Get the trigger zone component
    local triggerZone = triggerUserData.component
    if not triggerZone then
        return
    end

    -- Get the other entity (player, monster, etc.)
    local otherEntity = nil
    if otherUserData and type(otherUserData) == "table" and otherUserData.entity then
        otherEntity = otherUserData.entity
    end

    if not otherEntity then
        return
    end

    -- Handle enter/exit events
    if isBegin then
        triggerZone:addEntityInside(otherEntity)
    else
        triggerZone:removeEntityInside(otherEntity)
    end
end

---Update trigger zones (currently no per-frame logic needed)
---@param dt number Delta time
function TriggerZoneSystem:update(dt)
    -- Trigger zones are handled via collision callbacks
    -- No per-frame update needed
end

return TriggerZoneSystem
