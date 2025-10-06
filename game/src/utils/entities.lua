---@class EntityUtils
---Utility functions for working with entities
local EntityUtils = {}

---Check whether an entity is the Player
---@param entity Entity|nil
---@return boolean
function EntityUtils.isPlayer(entity)
    return not not (entity and entity.hasTag and entity:hasTag("Player"))
end

---Find the player entity in the world
---@param world World The ECS world to search in
---@return Entity|nil The player entity if found
function EntityUtils.findPlayer(world)
    if world and world.getPlayer then
        return world:getPlayer()
    end
    return nil
end

---Find the reactor entity in the world
---@param world World The ECS world to search in
---@return Entity|nil The reactor entity if found
function EntityUtils.findReactor(world)
    if world then
      return world:getEntitiesWithTag("Reactor")[1]
    end
    return nil
end

---Find entities by type in the world
---@param world World The ECS world to search in
---@param entityType string The type identifier (e.g., "isPlayer", "isSkeleton")
---@return table Array of entities matching the type
function EntityUtils.findEntitiesByType(world, entityType)
    local result = {}
    if world then
        for _, entity in ipairs(world.entities) do
            if entity[entityType] then
                table.insert(result, entity)
            end
        end
    end
    return result
end

---Get the first entity of a specific type
---@param world World The ECS world to search in
---@param entityType string The type identifier (e.g., "isPlayer", "isSkeleton")
---@return Entity|nil The first entity of the specified type, or nil if not found
function EntityUtils.findFirstEntityByType(world, entityType)
    if world then
        for _, entity in ipairs(world.entities) do
            if entity[entityType] then
                return entity
            end
        end
    end
    return nil
end

---Get the visual center of an entity (accounting for sprite size)
---@param entity Entity The entity to get the center of
---@param position Position The position component
---@return number, number Center X and Y coordinates
function EntityUtils.getEntityVisualCenter(entity, position)
    -- Prefer physics/pathfinding collider center when available
    local pfc = entity:getComponent("PathfindingCollision")
    if pfc and pfc.hasCollider and pfc:hasCollider() and pfc.getCenterPosition then
        local cx, cy = pfc:getCenterPosition()
        if cx and cy then return cx, cy end
    end
    local phys = entity:getComponent("PhysicsCollision")
    if phys and phys.hasCollider and phys:hasCollider() and phys.collider and phys.collider.body then
        local cx, cy = phys.collider.body:getPosition()
        if cx and cy then return cx, cy end
    end

    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        local centerX = position.x + (spriteRenderer.width or 24) / 2
        local centerY = position.y + (spriteRenderer.height or 24) / 2
        return centerX, centerY
    end
    return position.x, position.y
end

---Get the closest point on a target's collider from a given position
---@param fromX number Source X position
---@param fromY number Source Y position
---@param target Entity The target entity
---@return number, number The closest point (x, y) on the target's collider
function EntityUtils.getClosestPointOnTarget(fromX, fromY, target)
    local targetPos = target:getComponent("Position")
    if not targetPos then
        return fromX, fromY -- Fallback to source position
    end

    local targetPfc = target:getComponent("PathfindingCollision")
    if targetPfc and targetPfc:hasCollider() then
        -- Use collider center position and dimensions to find closest point
        local centerX, centerY = targetPfc:getCenterPosition()
        local colliderWidth = targetPfc.width
        local colliderHeight = targetPfc.height

        -- Calculate collider bounds from center
        local colliderLeft = centerX - colliderWidth / 2
        local colliderTop = centerY - colliderHeight / 2
        local colliderRight = centerX + colliderWidth / 2
        local colliderBottom = centerY + colliderHeight / 2

        -- Find closest point on rectangle
        local closestX = math.max(colliderLeft, math.min(fromX, colliderRight))
        local closestY = math.max(colliderTop, math.min(fromY, colliderBottom))
        return closestX, closestY
    end

    -- Fallback to sprite bounds if available
    local targetSprite = target:getComponent("SpriteRenderer")
    if targetSprite and targetSprite.width and targetSprite.height then
        local spriteX = targetPos.x
        local spriteY = targetPos.y
        local spriteWidth = targetSprite.width
        local spriteHeight = targetSprite.height

        -- Find closest point on sprite rectangle
        local closestX = math.max(spriteX, math.min(fromX, spriteX + spriteWidth))
        local closestY = math.max(spriteY, math.min(fromY, spriteY + spriteHeight))
        return closestX, closestY
    end

    -- Final fallback to position center
    return targetPos.x, targetPos.y
end

return EntityUtils
