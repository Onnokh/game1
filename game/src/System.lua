---@class System
---@field requiredComponents table Array of component types this system requires
---@field entities table Array of entities that match the required components
local System = {}
System.__index = System

---Create a new system
---@param requiredComponents table Array of component types this system requires
---@return System
function System.new(requiredComponents)
    local self = setmetatable({}, System)
    self.requiredComponents = requiredComponents or {}
    self.entities = {}
    return self
end

---Check if an entity matches this system's requirements
---@param entity Entity The entity to check
---@return boolean True if the entity matches
function System:entityMatches(entity)
    if not entity.active then
        return false
    end

    for _, componentType in ipairs(self.requiredComponents) do
        if not entity:hasComponent(componentType) then
            return false
        end
    end
    return true
end

---Add an entity to this system
---@param entity Entity The entity to add
function System:addEntity(entity)
    if self:entityMatches(entity) then
        table.insert(self.entities, entity)
    end
end

---Remove an entity from this system
---@param entity Entity The entity to remove
function System:removeEntity(entity)
    for i = #self.entities, 1, -1 do
        if self.entities[i].id == entity.id then
            table.remove(self.entities, i)
            break
        end
    end
end

---Update all entities in this system
---@param dt number Delta time
function System:update(dt)
    -- Override in subclasses
end

---Draw all entities in this system
function System:draw()
    -- Override in subclasses
end

return System
