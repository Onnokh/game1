---@class EntityUtils
---Utility functions for working with entities
local EntityUtils = {}

---Find the player entity in the world
---@param world World The ECS world to search in
---@return Entity|nil The player entity if found
function EntityUtils.findPlayer(world)
    if world then
        for _, entity in ipairs(world.entities) do
            if entity.isPlayer then
                return entity
            end
        end
    end
    return nil
end

---Find the reactor entity in the world
---@param world World The ECS world to search in
---@return Entity|nil The reactor entity if found
function EntityUtils.findReactor(world)
    if world then
        for _, entity in ipairs(world.entities) do
            if entity.isReactor then
                return entity
            end
        end
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
