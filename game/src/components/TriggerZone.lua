local Component = require("src.core.Component")

---@class TriggerZone : Component
---@field collider table|nil The physics collider object
---@field width number Width of the trigger zone (or radius for circular)
---@field height number Height of the trigger zone (or radius for circular)
---@field offsetX number Horizontal offset from entity top-left
---@field offsetY number Vertical offset from entity top-left
---@field onEnter function|nil Callback when entity enters trigger
---@field onExit function|nil Callback when entity exits trigger
---@field data table|nil Custom data for the trigger
---@field physicsWorld table|nil The physics world this collider belongs to
---@field entitiesInside table Set of entities currently inside the trigger
---@field shapeType string Shape type: "rectangle" or "circle"
local TriggerZone = {}
TriggerZone.__index = TriggerZone

local function isBodyValid(body)
    if not body then return false end
    local ok, _ = pcall(body.getType, body)
    return ok
end

---Create a new TriggerZone component
---@param width number Width of the trigger zone (or radius for circular)
---@param height number Height of the trigger zone (or radius for circular)
---@param offsetX number|nil Horizontal offset from entity top-left
---@param offsetY number|nil Vertical offset from entity top-left
---@param onEnter function|nil Callback when entity enters trigger
---@param onExit function|nil Callback when entity exits trigger
---@param data table|nil Custom data for the trigger
---@param shapeType string|nil Shape type: "rectangle" or "circle" (default: "rectangle")
---@return Component|TriggerZone
function TriggerZone.new(width, height, offsetX, offsetY, onEnter, onExit, data, shapeType)
    local self = setmetatable(Component.new("TriggerZone"), TriggerZone)

    self.collider = nil
    self.width = width or 16
    self.height = height or 16
    self.offsetX = offsetX or 0
    self.offsetY = offsetY or 0
    self.onEnter = onEnter
    self.onExit = onExit
    self.data = data or {}
    self.physicsWorld = nil
    self.entitiesInside = {}
    self.shapeType = shapeType or "rectangle"

    return self
end

---Set the physics world for this trigger zone
---@param physicsWorld table The physics world to create collider in
---@param x number X position
---@param y number Y position
function TriggerZone:createCollider(physicsWorld, x, y)
    if not physicsWorld or self.collider then
        return
    end

    self.physicsWorld = physicsWorld

    -- Create Love2D physics body for trigger zone
    local body = love.physics.newBody(physicsWorld,
        x + self.offsetX + self.width/2,
        y + self.offsetY + self.height/2,
        "static")

    -- Create shape based on type
    local shape
    if self.shapeType == "circle" then
        -- For circular trigger zones, use radius (width/height should be the same)
        local radius = self.width / 2
        shape = love.physics.newCircleShape(radius)
    else
        -- Default to rectangle shape
        shape = love.physics.newRectangleShape(self.width, self.height)
    end

    -- Create fixture and set as sensor (non-blocking)
    local fixture = love.physics.newFixture(body, shape)
    fixture:setSensor(true) -- This makes it a sensor - detects collisions but doesn't block movement
    fixture:setDensity(0) -- No density for sensors

    -- Store the body and fixture as our collider
    self.collider = {
        body = body,
        fixture = fixture,
        shape = shape
    }

    -- Set user data for collision detection
    fixture:setUserData({
        kind = "trigger",
        component = self,
        entity = nil -- Will be set by the entity that owns this component
    })
end

---Set the entity that owns this trigger zone
---@param entity Entity The entity that owns this trigger zone
function TriggerZone:setEntity(entity)
    if self.collider and self.collider.fixture then
        local userData = self.collider.fixture:getUserData()
        if userData then
            userData.entity = entity
        end
    end
end

---Update the collider position
---@param x number X position
---@param y number Y position
function TriggerZone:setPosition(x, y)
    if self.collider and isBodyValid(self.collider.body) then
        self.collider.body:setPosition(x + self.offsetX + self.width/2, y + self.offsetY + self.height/2)
    end
end

---Get the collider position (top-left corner)
---@return number, number X and Y position
function TriggerZone:getPosition()
    if self.collider and isBodyValid(self.collider.body) then
        local bodyX, bodyY = self.collider.body:getPosition()
        return bodyX - self.width/2 - self.offsetX, bodyY - self.height/2 - self.offsetY
    end
    return 0, 0
end

---Get the collider center position
---@return number, number X and Y center position
function TriggerZone:getCenterPosition()
    if self.collider and isBodyValid(self.collider.body) then
        local bodyX, bodyY = self.collider.body:getPosition()
        return bodyX, bodyY
    end
    return 0, 0
end

---Check if an entity is inside this trigger
---@param entity Entity The entity to check
---@return boolean True if entity is inside
function TriggerZone:isEntityInside(entity)
    return self.entitiesInside[entity.id] ~= nil
end

---Add an entity to the inside list
---@param entity Entity The entity that entered
function TriggerZone:addEntityInside(entity)
    if not self.entitiesInside[entity.id] then
        self.entitiesInside[entity.id] = entity
        if self.onEnter then
            self.onEnter(entity, self)
        end
    end
end

---Remove an entity from the inside list
---@param entity Entity The entity that exited
function TriggerZone:removeEntityInside(entity)
    if self.entitiesInside[entity.id] then
        self.entitiesInside[entity.id] = nil
        if self.onExit then
            self.onExit(entity, self)
        end
    end
end

---Destroy the collider
function TriggerZone:destroy()
    if self.collider then
        if isBodyValid(self.collider.body) then
            self.collider.body:destroy()
        end
        self.collider = nil
    end
end

---Check if the collider exists
---@return boolean True if collider exists
function TriggerZone:hasCollider()
    return self.collider ~= nil
end

---Serialize the TriggerZone component for saving
---@return table Serialized trigger zone data
function TriggerZone:serialize()
    return {
        width = self.width,
        height = self.height,
        offsetX = self.offsetX,
        offsetY = self.offsetY,
        data = self.data,
        shapeType = self.shapeType
        -- Note: onEnter and onExit callbacks are not serialized
    }
end

---Deserialize TriggerZone component from saved data
---@param data table Serialized trigger zone data
---@return Component|TriggerZone Recreated TriggerZone component
function TriggerZone.deserialize(data)
    local triggerZone = TriggerZone.new(
        data.width,
        data.height,
        data.offsetX,
        data.offsetY,
        nil, -- onEnter callback not restored
        nil, -- onExit callback not restored
        data.data,
        data.shapeType
    )
    -- Collider will be created by entity creation logic
    return triggerZone
end

return TriggerZone
