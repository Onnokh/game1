---@class World
---@field entities table Array of all entities in the world
---@field systems table Array of all systems in the world
---@field nextEntityId number Next available entity ID
---@field tagIndex table<string, table<number, Entity>> Index of entities by tag
---@field physicsWorld love.World|nil The physics world (optional)
---@field lightWorld table|nil The light world (optional)
---@field camera table|nil The camera (optional, for frustum culling)
---@field useDrawOrder boolean Whether to sort systems by drawOrder when drawing (for UI worlds)
local World = {}
World.__index = World

---Create a new ECS world
---@param physicsWorld love.World|nil The physics world (optional)
---@param lightWorld table|nil The light world (optional)
---@param useDrawOrder boolean|nil Whether to use drawOrder sorting (default: false)
---@return World
function World.new(physicsWorld, lightWorld, useDrawOrder)
    local self = setmetatable({}, World)
    self.entities = {}
    self.systems = {}
    self.tagIndex = {}
    -- Cache for frequently accessed special entities
    self._cachedPlayer = nil
    -- Store world references for systems to access
    self.physicsWorld = physicsWorld
    self.lightWorld = lightWorld
    self.camera = nil
    self.useDrawOrder = useDrawOrder or false
    return self
end

---Set the camera for frustum culling
---@param camera table The camera object
function World:setCamera(camera)
    self.camera = camera
end

---Create a new entity and add it to the world
---@return Entity
function World:createEntity()
    local Entity = require("src.core.Entity")
    local entity = Entity.new()
    table.insert(self.entities, entity)
    return entity
end

---Add an entity to the world
---@param entity Entity The entity to add
function World:addEntity(entity)
    -- Check if entity is already in the world to prevent duplicates
    for _, existingEntity in ipairs(self.entities) do
        if existingEntity.id == entity.id then
            return -- Entity already exists in world
        end
    end

    table.insert(self.entities, entity)
    -- Set world reference on entity so it can notify systems when components are added
    entity:setWorld(self)
    -- Notify all systems about the new entity
    for _, system in ipairs(self.systems) do
        system:addEntity(entity)
    end
end

---Notify all systems to re-scan entities (useful when components are added dynamically)
function World:notifySystemsOfEntityChange(entity)
    for _, system in ipairs(self.systems) do
        system:addEntity(entity)
    end
end

---Internal: register a tag for an entity
---@param entity Entity
---@param tag string
function World:_registerTag(entity, tag)
    local bucket = self.tagIndex[tag]
    if not bucket then
        bucket = {}
        self.tagIndex[tag] = bucket
    end
    bucket[entity.id] = entity
    -- Maintain cached special references
    if tag == "Player" then
        self._cachedPlayer = entity
    end
end

---Internal: unregister a tag for an entity
---@param entity Entity
---@param tag string
function World:_unregisterTag(entity, tag)
    local bucket = self.tagIndex[tag]
    if bucket then
        bucket[entity.id] = nil
        -- optional cleanup left out for performance
    end
    -- Invalidate cache if needed
    if tag == "Player" and self._cachedPlayer and self._cachedPlayer.id == entity.id then
        self._cachedPlayer = nil
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
    -- If a cached special entity was removed, clear it
    if self._cachedPlayer and self._cachedPlayer.id == entity.id then
        self._cachedPlayer = nil
    end
end

---Add a system to the world
---@param system System The system to add
function World:addSystem(system)
    table.insert(self.systems, system)
    -- Set world references on the system if it supports them
    if system.setWorld then
        system:setWorld(self)
    end
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

    -- Note: Entities are responsible for calling world:removeEntity() when they need to be removed
    -- Bullets call it immediately on collision, Skeletons call it after death animation completes
end

---Draw all systems in the world (sorted by drawOrder if enabled)
function World:draw()
    if self.useDrawOrder then
        -- Create a sorted copy of systems based on drawOrder
        local systemsToDraw = {}
        for _, system in ipairs(self.systems) do
            table.insert(systemsToDraw, system)
        end

        -- Sort by drawOrder (lower values draw first, higher values draw on top)
        table.sort(systemsToDraw, function(a, b)
            local orderA = a.drawOrder or 0
            local orderB = b.drawOrder or 0
            return orderA < orderB
        end)

        -- Debug: print draw order (only once)
        if not self._debugPrinted then
            print("[World] Draw order (z-index):")
            for i, system in ipairs(systemsToDraw) do
                local name = system.name or tostring(system)
                local order = system.drawOrder or 0
                print(string.format("  %d. %s (drawOrder: %d)", i, name, order))
            end
            self._debugPrinted = true
        end

        -- Draw in sorted order
        for _, system in ipairs(systemsToDraw) do
            system:draw()
        end
    else
        -- Draw in registration order (original behavior)
        for _, system in ipairs(self.systems) do
            system:draw()
        end
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

---Get all active entities that have the given tag
---@param tag string
---@return table
function World:getEntitiesWithTag(tag)
    local bucket = self.tagIndex[tag]
    if not bucket then return {} end
    local result = {}
    for _, entity in pairs(bucket) do
        if entity.active then
            table.insert(result, entity)
        end
    end
    return result
end

---Get the player entity if present and active
---@return Entity|nil
function World:getPlayer()
    -- Fast path: cached and still active
    if self._cachedPlayer and self._cachedPlayer.active then
        return self._cachedPlayer
    end
    -- Re-resolve from tag index to recover from cache invalidation
    local list = self:getEntitiesWithTag("Player")
    local player = list and list[1] or nil
    self._cachedPlayer = player or nil
    return player
end

---Get all active entities that have all of the given tags
---@param tags table
---@return table
function World:getEntitiesWithAllTags(tags)
    if not tags or #tags == 0 then return {} end
    -- Build intersection over buckets
    local firstBucket = self.tagIndex[tags[1]] or {}
    local result = {}
    for id, entity in pairs(firstBucket) do
        local ok = true
        for i = 2, #tags do
            local b = self.tagIndex[tags[i]]
            if not (b and b[id]) then ok = false break end
        end
        if ok and entity.active then
            table.insert(result, entity)
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
