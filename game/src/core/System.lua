---@class System
---@field requiredComponents table Array of component types this system requires
---@field requiredTags table Array of tags this system requires (optional)
---@field entities table Array of entities that match the required components
local System = {}
System.__index = System

---Create a new system
---@param requiredComponents table Array of component types this system requires
---@param requiredTags table|nil Array of tags this system requires
---@return System
function System.new(requiredComponents, requiredTags)
    local self = setmetatable({}, System)
    self.requiredComponents = requiredComponents or {}
    self.requiredTags = requiredTags or {}
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
    for _, tag in ipairs(self.requiredTags) do
        if not entity.hasTag or not entity:hasTag(tag) then
            return false
        end
    end
    return true
end

---Add an entity to this system
---@param entity Entity The entity to add
function System:addEntity(entity)
    if self:entityMatches(entity) then
        -- Check if entity is already in the system to prevent duplicates
        for _, existingEntity in ipairs(self.entities) do
            if existingEntity.id == entity.id then
                return -- Entity already exists in system
            end
        end
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

---Create a new system class that extends this System
---@param className string The name of the new system class
---@param requiredComponents table Array of component types the new system requires
---@param requiredTags table|nil Array of tags the new system requires
---@return table The new system class
function System:extend(className, requiredComponents, requiredTags)
    local NewSystem = {}
    NewSystem.__index = NewSystem

    -- Set up inheritance chain
    setmetatable(NewSystem, {__index = self})

    ---Create a new instance of the extended system
    ---@return table The new system instance
    function NewSystem.new()
        local self = System.new(requiredComponents, requiredTags)
        setmetatable(self, NewSystem)
        return self
    end

    return NewSystem
end

return System
