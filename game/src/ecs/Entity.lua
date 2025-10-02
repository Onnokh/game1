---@class Entity
---@field id number Unique identifier for this entity
---@field components table Table of components attached to this entity
---@field active boolean Whether this entity is active
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
    return self
end

---Add a component to this entity
---@param componentType string The type of component
---@param component table The component data
function Entity:addComponent(componentType, component)
    self.components[componentType] = component
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

---Destroy this entity (mark as inactive)
function Entity:destroy()
    self.active = false
    self.components = {}
end

return Entity
