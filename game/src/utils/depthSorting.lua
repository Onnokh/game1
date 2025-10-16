---@class DepthSorting
---Utility functions for depth sorting in 2D games
local DepthSorting = {}

---Depth sorting constants
DepthSorting.LAYERS = {
    BACKGROUND = -1,    -- Background elements (tiles, decorations)
    GROUND = 0,         -- Ground level entities (monsters, items)
    PLAYER = 0.1,       -- Player layer (slightly above ground)
    FOREGROUND = 1,     -- Foreground elements (UI, effects)
    UI = 2             -- User interface elements
}

---Get the bottom-center Y position for depth sorting
---@param entity Entity Entity to get depth position for
---@return number Bottom-center Y position
local function getDepthY(entity)
    local position = entity:getComponent("Position")
    if not position then
        return 0
    end

    local bottomY = position.y

    -- Try to get height from SpriteRenderer first
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    if spriteRenderer then
        -- Use custom depth sort height if available, otherwise use full height
        local height = spriteRenderer.depthSortHeight or spriteRenderer.height
        bottomY = bottomY + height
    else
        -- Fall back to PathfindingCollision if no sprite renderer
        local pathfindingCollision = entity:getComponent("PathfindingCollision")
        if pathfindingCollision then
            bottomY = bottomY + pathfindingCollision.height + pathfindingCollision.offsetY
        else
            -- Fall back to PhysicsCollision if available
            local physicsCollision = entity:getComponent("PhysicsCollision")
            if physicsCollision then
                bottomY = bottomY + physicsCollision.height + physicsCollision.offsetY
            end
        end
    end

    return bottomY
end

---Sort entities by depth for proper 2D rendering
---@param entities table Array of entities with Position components
---@return table Sorted array of entities
function DepthSorting.sortEntities(entities)
    local sortedEntities = {}

    -- Copy entities to avoid modifying the original array
    for _, entity in ipairs(entities) do
        table.insert(sortedEntities, entity)
    end

    -- Sort by depth: Bottom-center Y-coordinate first, then Z-index
    table.sort(sortedEntities, function(a, b)
        local posA = a:getComponent("Position")
        local posB = b:getComponent("Position")

        if not posA or not posB then
            return false
        end

        -- Primary sort: Bottom-center Y-coordinate (lower Y renders first)
        local bottomYA = getDepthY(a)
        local bottomYB = getDepthY(b)

        if bottomYA ~= bottomYB then
            return bottomYA < bottomYB
        end

        -- Secondary sort: Z-index (lower Z renders first)
        local zA = posA.z or 0
        local zB = posB.z or 0
        return zA < zB
    end)

    return sortedEntities
end

---Get the appropriate Z-index for a given layer
---@param layer string Layer name from DepthSorting.LAYERS
---@return number Z-index value
function DepthSorting.getLayerZ(layer)
    return DepthSorting.LAYERS[layer] or 0
end

---Set entity to a specific depth layer
---@param entity Entity Entity with Position component
---@param layer string Layer name from DepthSorting.LAYERS
function DepthSorting.setEntityLayer(entity, layer)
    local position = entity:getComponent("Position")
    if position then
        position:setZ(DepthSorting.getLayerZ(layer))
    end
end

---Check if entity A should render before entity B
---@param entityA Entity First entity
---@param entityB Entity Second entity
---@return boolean True if A should render before B
function DepthSorting.shouldRenderBefore(entityA, entityB)
    local posA = entityA:getComponent("Position")
    local posB = entityB:getComponent("Position")

    if not posA or not posB then
        return false
    end

    -- Primary sort: Bottom-center Y-coordinate
    local bottomYA = getDepthY(entityA)
    local bottomYB = getDepthY(entityB)

    if bottomYA ~= bottomYB then
        return bottomYA < bottomYB
    end

    -- Secondary sort: Z-index
    local zA = posA.z or 0
    local zB = posB.z or 0
    return zA < zB
end

---Move entity to front (highest Z-index for its Y position)
---@param entity Entity Entity to move to front
function DepthSorting.moveToFront(entity)
    local position = entity:getComponent("Position")
    if position then
        position:setZ(position:getZ() + 0.1)
    end
end

---Move entity to back (lowest Z-index for its Y position)
---@param entity Entity Entity to move to back
function DepthSorting.moveToBack(entity)
    local position = entity:getComponent("Position")
    if position then
        position:setZ(position:getZ() - 0.1)
    end
end

---Get debug information about entity depth
---@param entity Entity Entity to get depth info for
---@return table Depth information table
function DepthSorting.getDepthInfo(entity)
    local position = entity:getComponent("Position")
    if not position then
        return {y = 0, bottomY = 0, z = 0, depth = 0, layer = "UNKNOWN"}
    end

    local y = position.y
    local bottomY = getDepthY(entity)
    local z = position.z or 0
    local depth = position:getDepth()

    -- Determine layer based on Z value
    local layer = "CUSTOM"
    for layerName, layerZ in pairs(DepthSorting.LAYERS) do
        if math.abs(z - layerZ) < 0.01 then
            layer = layerName
            break
        end
    end

    return {
        y = y,
        bottomY = bottomY,
        z = z,
        depth = depth,
        layer = layer
    }
end

return DepthSorting
