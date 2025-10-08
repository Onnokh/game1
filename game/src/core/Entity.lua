---@class Entity
---@field id number Unique identifier for this entity
---@field components table Table of components attached to this entity
---@field active boolean Whether this entity is active
---@field isDead boolean Whether this entity is dead
---@field tags table<string, boolean> Set of tags applied to this entity
local Entity = {}
Entity.__index = Entity

-- Entity ID counter
local nextEntityId = 1

---Create a new entity
---@return Entity
function Entity.new()
    local self = setmetatable({}, Entity)
    self.id = nextEntityId
    nextEntityId = nextEntityId + 1
    self.components = {}
    self.active = true
    self.isDead = false
    self.tags = {}
    return self
end

---Add a component to this entity
---@param componentType string The type of component
---@param component table The component data
function Entity:addComponent(componentType, component)
    self.components[componentType] = component

    -- Notify the world that this entity has changed (if world is available)
    -- This allows systems to re-scan the entity for new components
    if self._world then
        self._world:notifySystemsOfEntityChange(self)
    end
end

---Set the world reference for this entity (called by World:addEntity)
---@param world World The world this entity belongs to
function Entity:setWorld(world)
    self._world = world
    if self.tags and self._world and self._world._registerTag then
        for tag, present in pairs(self.tags) do
            if present then
                self._world:_registerTag(self, tag)
            end
        end
    end
end

---Get a component from this entity
---@param componentType string The type of component
---@return table|nil The component or nil if not found
function Entity:getComponent(componentType)
    return self.components[componentType]
end

---Check if this entity has a specific component
---@param componentType string The type of component
---@return boolean True if the entity has the component
function Entity:hasComponent(componentType)
    return self.components[componentType] ~= nil
end

---Remove a component from this entity
---@param componentType string The type of component
function Entity:removeComponent(componentType)
    self.components[componentType] = nil
end

---Add a tag to this entity
---@param tag string
function Entity:addTag(tag)
    if not self.tags[tag] then
        self.tags[tag] = true
        if self._world and self._world._registerTag then
            self._world:_registerTag(self, tag)
        end
        if self._world then
            self._world:notifySystemsOfEntityChange(self)
        end
    end
end

---Remove a tag from this entity
---@param tag string
function Entity:removeTag(tag)
    if self.tags[tag] then
        self.tags[tag] = nil
        if self._world and self._world._unregisterTag then
            self._world:_unregisterTag(self, tag)
        end
        if self._world then
            self._world:notifySystemsOfEntityChange(self)
        end
    end
end

---Check if this entity has a specific tag
---@param tag string
---@return boolean
function Entity:hasTag(tag)
    return self.tags[tag] == true
end

---Get a human-readable name for this entity
---Returns the first tag if available, otherwise returns "Entity #[id]"
---@return string The entity's name
function Entity:getName()
    -- Try to return a meaningful tag name
    for tag, _ in pairs(self.tags) do
        return tag
    end
    -- Fall back to entity ID
    return "Entity #" .. tostring(self.id)
end

---Destroy this entity and clean up all components
function Entity:destroy()
    self.active = false

    -- Clean up components that have a destroy method (e.g., physics colliders)
    for _, component in pairs(self.components) do
        if component and type(component) == "table" and component.destroy then
            component:destroy()
        end
    end

    self.components = {}
end

return Entity
