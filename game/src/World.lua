---@class World
---@field entities table Array of all entities in the world
---@field systems table Array of all systems in the world
---@field nextEntityId number Next available entity ID
local World = {}
World.__index = World

---Create a new ECS world
---@return World
function World.new()
    local self = setmetatable({}, World)
    self.entities = {}
    self.systems = {}
    return self
end

---Create a new entity and add it to the world
---@return Entity
function World:createEntity()
    local Entity = require("src.Entity")
    local entity = Entity.new()
    table.insert(self.entities, entity)
    return entity
end

---Add an entity to the world
---@param entity Entity The entity to add
function World:addEntity(entity)
    table.insert(self.entities, entity)
    -- Notify all systems about the new entity
    for _, system in ipairs(self.systems) do
        system:addEntity(entity)
    end
end

---Remove an entity from the world
---@param entity Entity The entity to remove
function World:removeEntity(entity)
    entity:destroy()
    -- Remove from all systems
    for _, system in ipairs(self.systems) do
        system:removeEntity(entity)
    end
    -- Remove from entities list
    for i = #self.entities, 1, -1 do
        if self.entities[i].id == entity.id then
            table.remove(self.entities, i)
            break
        end
    end
end

---Add a system to the world
---@param system System The system to add
function World:addSystem(system)
    table.insert(self.systems, system)
    -- Add all existing entities to the system
    for _, entity in ipairs(self.entities) do
        system:addEntity(entity)
    end
end

---Update all systems in the world
---@param dt number Delta time
function World:update(dt)
    for _, system in ipairs(self.systems) do
        system:update(dt)
    end
end

---Draw all systems in the world
function World:draw()
    for _, system in ipairs(self.systems) do
        system:draw()
    end
end

---Get all entities with specific components
---@param componentTypes table Array of component types
---@return table Array of entities that have all the specified components
function World:getEntitiesWith(componentTypes)
    local result = {}
    for _, entity in ipairs(self.entities) do
        if entity.active then
            local hasAll = true
            for _, componentType in ipairs(componentTypes) do
                if not entity:hasComponent(componentType) then
                    hasAll = false
                    break
                end
            end
            if hasAll then
                table.insert(result, entity)
            end
        end
    end
    return result
end

---Get the first entity with specific components
---@param componentTypes table Array of component types
---@return Entity|nil The first entity that has all the specified components
function World:getEntityWith(componentTypes)
    local entities = self:getEntitiesWith(componentTypes)
    return entities[1]
end

return World
