-- BridgeManager.lua
-- Manages bridge detection, adjacency mapping, and bridge rendering between islands

local BridgeManager = {}

-- Dependencies
local GameConstants = require("src.constants")

-- Internal state
BridgeManager.bridges = {} -- Cached bridge connections: {fromTile = {x, y}, toTile = {x, y}}
BridgeManager.adjacencyMap = {} -- Maps island index to list of adjacent island indices
BridgeManager.initialized = false

---=============================================================================
--- HELPER FUNCTIONS
---=============================================================================

---Check if a tile is walkable (empty/navigable)
---@param tileX number Tile X coordinate
---@param tileY number Tile Y coordinate
---@param grid table Pathfinding grid
---@param gridWidth number Grid width
---@param gridHeight number Grid height
---@return boolean
local function isTileWalkable(tileX, tileY, grid, gridWidth, gridHeight)
    if tileX < 1 or tileX > gridWidth or tileY < 1 or tileY > gridHeight then
        return false
    end

    local tile = grid[tileX] and grid[tileX][tileY]
    return tile and tile.walkable == true
end

---Find walkable tiles on an island (returns tile coordinates only)
---@param island table Island data
---@param grid table Pathfinding grid
---@param tileSize number Tile size in pixels
---@return table Array of {tileX, tileY} positions
local function findWalkableTiles(island, grid, tileSize)
    local walkableTiles = {}

    -- Scan the entire island for walkable tiles
    -- The grid was built with localX/Y from 1 to width/height
    -- So grid indices are: floor(island.x / tileSize) + localX
    -- Which means: floor(island.x / tileSize) + 1  to  floor(island.x / tileSize) + width
    local baseTileX = math.floor(island.x / tileSize)
    local baseTileY = math.floor(island.y / tileSize)
    local startTileX = baseTileX + 1
    local startTileY = baseTileY + 1
    -- endTile should be base + islandWidth (in tiles)
    local islandWidthTiles = island.map.width
    local islandHeightTiles = island.map.height
    local endTileX = baseTileX + islandWidthTiles
    local endTileY = baseTileY + islandHeightTiles

    for tileX = startTileX, endTileX do
        for tileY = startTileY, endTileY do
            local tile = grid[tileX] and grid[tileX][tileY]
            if tile and tile.walkable then
                table.insert(walkableTiles, {tileX = tileX, tileY = tileY})
            end
        end
    end

    return walkableTiles
end

---Determine the primary direction from island1 to island2
---@param island1 table First island
---@param island2 table Second island
---@return string Direction ("north", "south", "east", "west")
local function getDirectionBetweenIslands(island1, island2)
    local center1X = island1.x + island1.width / 2
    local center1Y = island1.y + island1.height / 2
    local center2X = island2.x + island2.width / 2
    local center2Y = island2.y + island2.height / 2

    local dx = center2X - center1X
    local dy = center2Y - center1Y

    -- Determine primary direction
    if math.abs(dx) > math.abs(dy) then
        return dx > 0 and "east" or "west"
    else
        return dy > 0 and "south" or "north"
    end
end

---=============================================================================
--- PUBLIC API
---=============================================================================

---Initialize BridgeManager with island data and pathfinding grid
---@param islands table Array of island data
---@param tileSize number Tile size in pixels
---@param pathfindingGrid table Grid data with grid, width, height
function BridgeManager.initialize(islands, tileSize, pathfindingGrid)
    print("[BridgeManager] Initializing...")

    -- Build adjacency map (islands within configured distance of each other)
    local adjacencyTolerance = tileSize * GameConstants.ISLAND_ADJACENCY_DISTANCE_TILES
    BridgeManager.adjacencyMap = BridgeManager.buildAdjacencyMap(islands, adjacencyTolerance)

    -- Detect bridges (only between adjacent islands)
    BridgeManager.bridges = BridgeManager.detectBridges(
        islands,
        tileSize,
        pathfindingGrid.grid,
        pathfindingGrid.width,
        pathfindingGrid.height
    )

    BridgeManager.initialized = true
    print(string.format("[BridgeManager] Initialized with %d bridges", #BridgeManager.bridges))
end

---Build adjacency map for islands
---@param islands table Array of island data
---@param tolerance number Maximum gap distance to consider islands adjacent
---@return table Adjacency map: island index -> array of adjacent island indices
function BridgeManager.buildAdjacencyMap(islands, tolerance)
    tolerance = tolerance or 10 -- pixels

    local adjacencyMap = {}

    -- Initialize adjacency lists
    for i = 1, #islands do
        adjacencyMap[i] = {}
    end

    -- Check each pair of islands
    for i = 1, #islands do
        local island1 = islands[i]

        for j = i + 1, #islands do
            local island2 = islands[j]

            -- Calculate the gap/overlap between islands
            local horizontalGap = math.max(
                island1.x - (island2.x + island2.width),
                island2.x - (island1.x + island1.width)
            )

            local verticalGap = math.max(
                island1.y - (island2.y + island2.height),
                island2.y - (island1.y + island1.height)
            )

            -- Islands are adjacent if they're close in one dimension and aligned in the other
            local isAdjacent = false

            -- Check if horizontally adjacent (east/west neighbors)
            if horizontalGap >= 0 and horizontalGap <= tolerance then
                -- Check if they overlap vertically (share Y range)
                local verticalOverlap = not (
                    island1.y + island1.height < island2.y or
                    island2.y + island2.height < island1.y
                )
                if verticalOverlap then
                    isAdjacent = true
                end
            end

            -- Check if vertically adjacent (north/south neighbors)
            if verticalGap >= 0 and verticalGap <= tolerance then
                -- Check if they overlap horizontally (share X range)
                local horizontalOverlap = not (
                    island1.x + island1.width < island2.x or
                    island2.x + island2.width < island1.x
                )
                if horizontalOverlap then
                    isAdjacent = true
                end
            end

            if isAdjacent then
                table.insert(adjacencyMap[i], j)
                table.insert(adjacencyMap[j], i)
                print(string.format("[BridgeManager] Islands '%s' (#%d) and '%s' (#%d) are adjacent",
                    island1.id, i, island2.id, j))
            end
        end
    end

    return adjacencyMap
end

---Detect bridges between islands based on proximity
---@param islands table Array of island data
---@param tileSize number Tile size in pixels
---@param grid table Pathfinding grid
---@param gridWidth number Grid width
---@param gridHeight number Grid height
---@return table Array of bridge connections {fromTile = {x, y}, toTile = {x, y}}
function BridgeManager.detectBridges(islands, tileSize, grid, gridWidth, gridHeight)
    print("[BridgeManager] ===== DETECTING BRIDGES =====")
    print(string.format("[BridgeManager] Grid size: %dx%d, Tile size: %d", gridWidth, gridHeight, tileSize))

    local bridges = {}

    -- Find all walkable tiles on each island
    local islandWalkableTiles = {}
    for i, island in ipairs(islands) do
        local tiles = findWalkableTiles(island, grid, tileSize)
        islandWalkableTiles[i] = tiles
    end

    -- For each island, check only its adjacent neighbors
    for i = 1, #islands do
        local adjacentIndices = BridgeManager.adjacencyMap[i] or {}

        for _, j in ipairs(adjacentIndices) do
            -- Only process each pair once (i < j)
            if i < j then
                local island1 = islands[i]
                local island2 = islands[j]
                local tiles1 = islandWalkableTiles[i]
                local tiles2 = islandWalkableTiles[j]

                -- Skip if either island has no walkable tiles
                if #tiles1 == 0 or #tiles2 == 0 then
                    goto continue
                end

                -- Find aligned tile pairs that can form a bridge (work in tile coordinates)
                local bestTile1 = nil
                local bestTile2 = nil
                local bestDist = math.huge
                local maxBridgeDistanceTiles = GameConstants.MAX_BRIDGE_DISTANCE_TILES

                -- Determine primary direction between island centers
                local direction = getDirectionBetweenIslands(island1, island2)

                -- Filter tiles to only those at the edge facing the other island
                local edgeTiles1 = {}
                local edgeTiles2 = {}

                if direction == "east" or direction == "west" then
                    -- Horizontal connection - find tiles at horizontal edges
                    local maxX1 = -math.huge
                    local minX1 = math.huge
                    for _, tile in ipairs(tiles1) do
                        maxX1 = math.max(maxX1, tile.tileX)
                        minX1 = math.min(minX1, tile.tileX)
                    end

                    local maxX2 = -math.huge
                    local minX2 = math.huge
                    for _, tile in ipairs(tiles2) do
                        maxX2 = math.max(maxX2, tile.tileX)
                        minX2 = math.min(minX2, tile.tileX)
                    end

                    -- Get edge tiles: rightmost of island1 if island2 is east, leftmost if west
                    local targetX1 = direction == "east" and maxX1 or minX1
                    local targetX2 = direction == "east" and minX2 or maxX2

                    for _, tile in ipairs(tiles1) do
                        if tile.tileX == targetX1 then
                            table.insert(edgeTiles1, tile)
                        end
                    end

                    for _, tile in ipairs(tiles2) do
                        if tile.tileX == targetX2 then
                            table.insert(edgeTiles2, tile)
                        end
                    end
                else
                    -- Vertical connection - find tiles at vertical edges
                    local maxY1 = -math.huge
                    local minY1 = math.huge
                    for _, tile in ipairs(tiles1) do
                        maxY1 = math.max(maxY1, tile.tileY)
                        minY1 = math.min(minY1, tile.tileY)
                    end

                    local maxY2 = -math.huge
                    local minY2 = math.huge
                    for _, tile in ipairs(tiles2) do
                        maxY2 = math.max(maxY2, tile.tileY)
                        minY2 = math.min(minY2, tile.tileY)
                    end

                    -- Get edge tiles: bottommost of island1 if island2 is south, topmost if north
                    local targetY1 = direction == "south" and maxY1 or minY1
                    local targetY2 = direction == "south" and minY2 or maxY2

                    for _, tile in ipairs(tiles1) do
                        if tile.tileY == targetY1 then
                            table.insert(edgeTiles1, tile)
                        end
                    end

                    for _, tile in ipairs(tiles2) do
                        if tile.tileY == targetY2 then
                            table.insert(edgeTiles2, tile)
                        end
                    end
                end

                -- Now find closest aligned pair from edge tiles (in tile coordinates)
                for _, tile1 in ipairs(edgeTiles1) do
                    for _, tile2 in ipairs(edgeTiles2) do
                        local dx = math.abs(tile1.tileX - tile2.tileX)
                        local dy = math.abs(tile1.tileY - tile2.tileY)
                        local dist = math.sqrt(dx * dx + dy * dy)

                        -- Check if tiles are aligned horizontally or vertically
                        local isHorizontal = dy == 0  -- Perfectly aligned horizontally
                        local isVertical = dx == 0    -- Perfectly aligned vertically

                        if (isHorizontal or isVertical) and dist < bestDist and dist <= maxBridgeDistanceTiles then
                            bestDist = dist
                            bestTile1 = tile1
                            bestTile2 = tile2
                        end
                    end
                end

                if bestTile1 and bestTile2 then
                    print(string.format("[BridgeManager] '%s' → '%s': Tiles (%d,%d) → (%d,%d)",
                        island1.id, island2.id, bestTile1.tileX, bestTile1.tileY, bestTile2.tileX, bestTile2.tileY))

                    table.insert(bridges, {
                        fromTile = {x = bestTile1.tileX, y = bestTile1.tileY},
                        toTile = {x = bestTile2.tileX, y = bestTile2.tileY}
                    })
                end

                ::continue::
            end
        end
    end

    print(string.format("[BridgeManager] ===== TOTAL BRIDGES DETECTED: %d =====", #bridges))
    return bridges
end

---Draw bridges between islands (uses cached bridges)
---@param map table Optional Tiled map instance to get tileset from (uses first available map if nil)
function BridgeManager.draw(map)
    if not BridgeManager.initialized then
        return
    end

    if not BridgeManager.bridges or #BridgeManager.bridges == 0 then
        return
    end

    -- If no map provided, we'll draw rectangles (fallback)
    if not map then
        BridgeManager.drawSimple()
        return
    end

    love.graphics.push("all")
    love.graphics.setColor(1, 1, 1, 1) -- White (to not tint the tile)

    local tileSize = GameConstants.TILE_SIZE
    local bridgeGID = 140 -- GID of the bridge tile

    -- Get the tileset and prepare tile drawing
    local tileset = map:getTileset(bridgeGID)
    if not tileset or not tileset.image then
        print("[BridgeManager] WARNING: Could not find tileset for GID " .. bridgeGID .. ", falling back to simple draw")
        love.graphics.pop()
        BridgeManager.drawSimple()
        return
    end

    -- Get the quad for this tile
    local quad = map:_getTileQuad(bridgeGID)
    if not quad then
        print("[BridgeManager] WARNING: Could not get quad for GID " .. bridgeGID .. ", falling back to simple draw")
        love.graphics.pop()
        BridgeManager.drawSimple()
        return
    end

    -- Get the image from the map's internal images table
    local image = map._images[tileset.image]
    if not image then
        print("[BridgeManager] WARNING: Could not get image for tileset, falling back to simple draw")
        love.graphics.pop()
        BridgeManager.drawSimple()
        return
    end

    for _, bridge in ipairs(BridgeManager.bridges) do
        local tileX1 = bridge.fromTile.x
        local tileY1 = bridge.fromTile.y
        local tileX2 = bridge.toTile.x
        local tileY2 = bridge.toTile.y

        -- Determine if bridge is horizontal or vertical
        local isHorizontal = tileY1 == tileY2
        local isVertical = tileX1 == tileX2

        if isHorizontal then
            -- Draw tiles horizontally from tileX1 to tileX2
            local startX = math.min(tileX1, tileX2)
            local endX = math.max(tileX1, tileX2)
            for tileX = startX, endX do
                local worldX = (tileX - 1) * tileSize
                local worldY = (tileY1 - 1) * tileSize
                love.graphics.draw(image, quad, worldX, worldY)
            end
        elseif isVertical then
            -- Draw tiles vertically from tileY1 to tileY2
            local startY = math.min(tileY1, tileY2)
            local endY = math.max(tileY1, tileY2)
            for tileY = startY, endY do
                local worldX = (tileX1 - 1) * tileSize
                local worldY = (tileY - 1) * tileSize
                love.graphics.draw(image, quad, worldX, worldY)
            end
        else
            -- Bridge is neither horizontal nor vertical - this shouldn't happen
            print(string.format("[BridgeManager] WARNING: Non-aligned bridge detected: (%d,%d) → (%d,%d)",
                tileX1, tileY1, tileX2, tileY2))
        end
    end

    love.graphics.pop()
end

---Draw bridges using simple yellow rectangles (fallback when no map available)
function BridgeManager.drawSimple()
    if not BridgeManager.initialized then
        return
    end

    if not BridgeManager.bridges or #BridgeManager.bridges == 0 then
        return
    end

    love.graphics.push("all")

    local tileSize = GameConstants.TILE_SIZE

    for _, bridge in ipairs(BridgeManager.bridges) do
        local tileX1 = bridge.fromTile.x
        local tileY1 = bridge.fromTile.y
        local tileX2 = bridge.toTile.x
        local tileY2 = bridge.toTile.y

        -- Determine if bridge is horizontal or vertical
        local isHorizontal = tileY1 == tileY2
        local isVertical = tileX1 == tileX2

        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow

        if isHorizontal then
            -- Draw tiles horizontally from tileX1 to tileX2
            local startX = math.min(tileX1, tileX2)
            local endX = math.max(tileX1, tileX2)
            for tileX = startX, endX do
                local worldX = (tileX - 1) * tileSize
                local worldY = (tileY1 - 1) * tileSize
                love.graphics.rectangle("fill", worldX, worldY, tileSize, tileSize)
            end
        elseif isVertical then
            -- Draw tiles vertically from tileY1 to tileY2
            local startY = math.min(tileY1, tileY2)
            local endY = math.max(tileY1, tileY2)
            for tileY = startY, endY do
                local worldX = (tileX1 - 1) * tileSize
                local worldY = (tileY - 1) * tileSize
                love.graphics.rectangle("fill", worldX, worldY, tileSize, tileSize)
            end
        else
            -- Bridge is neither horizontal nor vertical - this shouldn't happen
            print(string.format("[BridgeManager] WARNING: Non-aligned bridge detected: (%d,%d) → (%d,%d)",
                tileX1, tileY1, tileX2, tileY2))
        end
    end

    love.graphics.pop()
end

---Draw connection points (for debug overlay)
---@param islands table Array of island data
function BridgeManager.drawConnectionPoints(islands)
    if not BridgeManager.initialized then return end

    love.graphics.push("all")
    love.graphics.setColor(0, 1, 1, 0.6)
    love.graphics.setLineWidth(2)

    for _, island in ipairs(islands) do
        if island.map and island.map.layers then
            for _, layer in ipairs(island.map.layers) do
                if layer.name == "Bridges" and layer.objects then
                    for _, obj in ipairs(layer.objects) do
                        if obj.name == "ConnectionPoint" then
                            local worldX = island.x + obj.x
                            local worldY = island.y + obj.y
                            love.graphics.rectangle("line", worldX, worldY, obj.width or 32, obj.height or 32)

                            love.graphics.setColor(1, 1, 0, 0.8)
                            local centerX = worldX + (obj.width or 32) / 2
                            local centerY = worldY + (obj.height or 32) / 2
                            love.graphics.circle("fill", centerX, centerY, 3)
                            love.graphics.setColor(0, 1, 1, 0.6)
                        end
                    end
                end
            end
        end
    end

    love.graphics.pop()
end

---Get all detected bridges
---@return table Array of bridges
function BridgeManager.getBridges()
    return BridgeManager.bridges
end

---Get adjacency map
---@return table Adjacency map
function BridgeManager.getAdjacencyMap()
    return BridgeManager.adjacencyMap
end

---Mark all bridge tiles as walkable in the pathfinding grid
---@param grid table Pathfinding grid (2D array)
function BridgeManager.markBridgeTilesWalkable(grid)
    if not BridgeManager.initialized or not BridgeManager.bridges then
        return
    end

    local GameConstants = require("src.constants")
    local bridgeGID = 140 -- Match the GID used for rendering

    local tilesMarked = 0
    for _, bridge in ipairs(BridgeManager.bridges) do
        local tileX1 = bridge.fromTile.x
        local tileY1 = bridge.fromTile.y
        local tileX2 = bridge.toTile.x
        local tileY2 = bridge.toTile.y

        -- Determine if bridge is horizontal or vertical
        local isHorizontal = tileY1 == tileY2
        local isVertical = tileX1 == tileX2

        if isHorizontal then
            local startX = math.min(tileX1, tileX2)
            local endX = math.max(tileX1, tileX2)
            for tileX = startX, endX do
                if grid[tileX] and grid[tileX][tileY1] then
                    -- Create a NEW tile object (don't modify shared emptyTile reference!)
                    grid[tileX][tileY1] = {
                        walkable = true,
                        type = 1, -- Walkable ground type
                        gid = bridgeGID
                    }
                    tilesMarked = tilesMarked + 1
                end
            end
        elseif isVertical then
            local startY = math.min(tileY1, tileY2)
            local endY = math.max(tileY1, tileY2)
            for tileY = startY, endY do
                if grid[tileX1] and grid[tileX1][tileY] then
                    -- Create a NEW tile object (don't modify shared emptyTile reference!)
                    grid[tileX1][tileY] = {
                        walkable = true,
                        type = 1, -- Walkable ground type
                        gid = bridgeGID
                    }
                    tilesMarked = tilesMarked + 1
                end
            end
        end
    end

    print(string.format("[BridgeManager] Marked %d bridge tiles as walkable", tilesMarked))
end

---Get all bridge tile positions (for collision exclusion)
---@return table Array of {tileX, tileY} positions
function BridgeManager.getBridgeTilePositions()
    if not BridgeManager.initialized or not BridgeManager.bridges then
        return {}
    end

    local positions = {}
    for _, bridge in ipairs(BridgeManager.bridges) do
        local tileX1 = bridge.fromTile.x
        local tileY1 = bridge.fromTile.y
        local tileX2 = bridge.toTile.x
        local tileY2 = bridge.toTile.y

        -- Determine if bridge is horizontal or vertical
        local isHorizontal = tileY1 == tileY2
        local isVertical = tileX1 == tileX2

        if isHorizontal then
            local startX = math.min(tileX1, tileX2)
            local endX = math.max(tileX1, tileX2)
            for tileX = startX, endX do
                table.insert(positions, {tileX = tileX, tileY = tileY1})
            end
        elseif isVertical then
            local startY = math.min(tileY1, tileY2)
            local endY = math.max(tileY1, tileY2)
            for tileY = startY, endY do
                table.insert(positions, {tileX = tileX1, tileY = tileY})
            end
        end
    end

    return positions
end

---Unload and reset BridgeManager
function BridgeManager.unload()
    BridgeManager.bridges = {}
    BridgeManager.adjacencyMap = {}
    BridgeManager.initialized = false
    print("[BridgeManager] Unloaded")
end

return BridgeManager

