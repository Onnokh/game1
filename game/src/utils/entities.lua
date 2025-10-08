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

---Find a valid walkable spawn position in world coordinates
---@param minX number Min X in tiles
---@param maxX number Max X in tiles
---@param minY number Min Y in tiles
---@param maxY number Max Y in tiles
---@return number|nil worldX
---@return number|nil worldY
function EntityUtils.findValidSpawnPosition(minX, maxX, minY, maxY)
    local CoordinateUtils = require("src.utils.coordinates")
    local TiledMapLoader = require("src.utils.TiledMapLoader")
    local GameScene = require("src.scenes.game")

    local mapData = GameScene.getMapData()
    if not mapData or not mapData.collisionGrid then
        return nil, nil
    end

    local maxAttempts = 5

    for i = 1, maxAttempts do
        local tileX = math.random(minX, maxX)
        local tileY = math.random(minY, maxY)

        if mapData.collisionGrid[tileX] and TiledMapLoader.isWalkable(mapData.collisionGrid[tileX][tileY]) then
            return CoordinateUtils.gridToWorld(tileX, tileY)
        end
    end

    return nil, nil
end

return EntityUtils
