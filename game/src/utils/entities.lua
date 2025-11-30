---@class EntityUtils
---Utility functions for working with entities
local EntityUtils = {}

-- Entity registry (single source of truth)
local EntityRegistry = require("src.core.managers.EntityRegistry")

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

---Find valid walkable tiles in a rectangle area
---@param minX number Min X in tiles
---@param maxX number Max X in tiles
---@param minY number Min Y in tiles
---@param maxY number Max Y in tiles
---@return table Array of valid tiles {x=gridX, y=gridY}
function EntityUtils.findValidTilesInRectangle(minX, maxX, minY, maxY)
    local GameScene = require("src.scenes.game")

    local mapData = GameScene.getMapData()
    if not mapData or not mapData.collisionGrid then
        return {}
    end

    local validTiles = {}

    for x = minX, maxX do
        for y = minY, maxY do
            if mapData.collisionGrid[x] and mapData.collisionGrid[x][y] then
                local tileData = mapData.collisionGrid[x][y]
                if tileData.walkable then
                    table.insert(validTiles, {x = x, y = y})
                end
            end
        end
    end

    return validTiles
end

---Find valid walkable tiles in a circular radius
---@param centerX number Center X in tiles
---@param centerY number Center Y in tiles
---@param radius number Radius in tiles
---@return table Array of valid tiles {x=gridX, y=gridY}
function EntityUtils.findValidTilesInRadius(centerX, centerY, radius)
    local GameScene = require("src.scenes.game")

    local mapData = GameScene.getMapData()
    if not mapData or not mapData.collisionGrid then
        print(string.format("[EntityUtils] WARNING: No map data for findValidTilesInRadius"))
        return {}
    end

    local validTiles = {}

    -- Calculate bounding box
    local minX = math.max(1, math.floor(centerX - radius))
    local maxX = math.min(mapData.width, math.ceil(centerX + radius))
    local minY = math.max(1, math.floor(centerY - radius))
    local maxY = math.min(mapData.height, math.ceil(centerY + radius))

    for x = minX, maxX do
        for y = minY, maxY do
            if mapData.collisionGrid[x] and mapData.collisionGrid[x][y] then
                local tileData = mapData.collisionGrid[x][y]

                -- Check if walkable
                if tileData.walkable then
                    -- Check if within circular radius
                    local dx = x - centerX
                    local dy = y - centerY
                    local dist = math.sqrt(dx * dx + dy * dy)

                    if dist <= radius then
                        table.insert(validTiles, {x = x, y = y})
                    end
                end
            end
        end
    end

    if #validTiles == 0 then
        print(string.format("[EntityUtils] WARNING: findValidTilesInRadius found 0 tiles at (%d,%d) radius %d (grid %dx%d)",
            centerX, centerY, radius, mapData.width, mapData.height))
    end

    return validTiles
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

    -- Find all valid tiles in rectangle
    local validTiles = EntityUtils.findValidTilesInRectangle(minX, maxX, minY, maxY)

    -- If no valid tiles found, return nil
    if #validTiles == 0 then
        return nil, nil
    end

    -- Pick a random valid tile
    local randomTile = validTiles[math.random(#validTiles)]

    -- Convert to world coordinates (center of tile)
    return CoordinateUtils.gridToWorld(randomTile.x, randomTile.y)
end

---Spawn a monster at the specified position
---@param x number PathfindingCollision center X position
---@param y number PathfindingCollision center Y position
---@param monsterType string Monster type (e.g., "skeleton", "slime")
---@param world World The ECS world
---@param physicsWorld table The physics world
---@param isElite boolean|nil Whether this monster should be an elite variant
---@return Entity|nil The created monster entity
function EntityUtils.spawnMonster(x, y, monsterType, world, physicsWorld, isElite)
    -- Get factory and config from registry
    local factory, config = EntityRegistry.getMonsterFactory(monsterType)
    if not factory then
        print("ERROR: Unknown monster type:", monsterType)
        return nil
    end

    if not config then
        print("ERROR: No config found for monster type:", monsterType)
        return nil
    end

    -- Calculate sprite position from collision center
    local spriteWidth = config.SPRITE_WIDTH
    local spriteHeight = config.SPRITE_HEIGHT
    local colliderWidth = config.COLLIDER_WIDTH
    local colliderHeight = config.COLLIDER_HEIGHT

    -- Get offsets from config (same as MonsterFactory)
    local pfOffsetX = (spriteWidth - colliderWidth) / 2
    local pfOffsetY = config.PATHFINDING_OFFSET_Y or (spriteHeight - colliderHeight - 8)

    -- Sprite position = collision center - offset - half collider size
    local spriteX = x - pfOffsetX - colliderWidth / 2
    local spriteY = y - pfOffsetY - colliderHeight / 2

    -- Create monster using factory
    return factory(spriteX, spriteY, world, physicsWorld, isElite or false)
end

return EntityUtils
