local IslandGenerator = {}

-- Set random seed for reproducible results
local function setRandomSeed()
    if os and os.time then
        math.randomseed(os.time())
    end
end

local function randomInRange(min, max)
    return min + math.random() * (max - min)
end

local function weightedRandom(pool)
    if not pool or #pool == 0 then return nil end

    local totalWeight = 0
    for _, item in ipairs(pool) do
        totalWeight = totalWeight + (item.weight or 1)
    end

    local randomValue = math.random() * totalWeight
    local currentWeight = 0

    for _, item in ipairs(pool) do
        currentWeight = currentWeight + (item.weight or 1)
        if randomValue <= currentWeight then
            return item
        end
    end

    return pool[1]  -- Fallback
end

--Checks if two islands overlap (basic AABB collision)
---@param island1 table First island
---@param island2 table Second island
---@param tolerance number Tolerance for overlap detection
---@return boolean True if islands overlap
local function islandsOverlap(island1, island2, tolerance)
    tolerance = tolerance or 0
    return island1.x < island2.x + island2.width - tolerance and
           island1.x + island1.width > island2.x + tolerance and
           island1.y < island2.y + island2.height - tolerance and
           island1.y + island1.height > island2.y + tolerance
end

--Calculates distance between two points
---@param x1 number First point x
---@param y1 number First point y
---@param x2 number Second point x
---@param y2 number Second point y
---@return number Distance between points
local function calculateDistance(x1, y1, x2, y2)
    local dx = x2 - x1
    local dy = y2 - y1
    return math.sqrt(dx * dx + dy * dy)
end

--Gets all possible edge positions for an island along a target island's edge
---@param island table Island to position
---@param targetIsland table Target island to align with
---@param edge string Edge to align with ("north", "south", "east", "west")
---@return table Array of possible positions
local function getEdgePositions(island, targetIsland, edge)
    local positions = {}

    if edge == "north" then
        -- Position above target island
        for x = targetIsland.x - island.width, targetIsland.x + targetIsland.width do
            table.insert(positions, {x = x, y = targetIsland.y - island.height})
        end
    elseif edge == "south" then
        -- Position below target island
        for x = targetIsland.x - island.width, targetIsland.x + targetIsland.width do
            table.insert(positions, {x = x, y = targetIsland.y + targetIsland.height})
        end
    elseif edge == "east" then
        -- Position to the right of target island
        for y = targetIsland.y - island.height, targetIsland.y + targetIsland.height do
            table.insert(positions, {x = targetIsland.x + targetIsland.width, y = y})
        end
    elseif edge == "west" then
        -- Position to the left of target island
        for y = targetIsland.y - island.height, targetIsland.y + targetIsland.height do
            table.insert(positions, {x = targetIsland.x - island.width, y = y})
        end
    end

    return positions
end

--Gets random position based on distribution mode
---@param baseIsland table Base island
---@param island table Island to position
---@param mode string Distribution mode ("random", "adjacent", "clustered")
---@return number x coordinate
---@return number y coordinate
local function getRandomPosition(baseIsland, island, mode)
    local x, y

    if mode == "adjacent" then
        -- Place islands adjacent to base island edges
        local edges = {"north", "south", "east", "west"}
        local edge = edges[math.random(#edges)]
        local positions = getEdgePositions(island, baseIsland, edge)

        if #positions > 0 then
            local pos = positions[math.random(#positions)]
            x, y = pos.x, pos.y
        else
            x, y = randomInRange(-1000, 1000), randomInRange(-1000, 1000)
        end
    else
        -- Random placement
        x, y = randomInRange(-1000, 1000), randomInRange(-1000, 1000)
    end

    return x, y
end

--Main generation function - places islands like tiles adjacent to existing ones
---@param levelConfig table Level configuration
---@return table Array of generated islands
---@return table Array of bridges
function IslandGenerator.generate(levelConfig)
    setRandomSeed()

    local baseIslandDef = levelConfig.baseIsland
    local islandPool = levelConfig.generation.islandPool
    local generation = levelConfig.generation

    -- Calculate island count from range
    local islandCount = math.random(generation.islandCount.min, generation.islandCount.max)
    local placementMode = generation.placement.distributionMode or "tile-based"

    print(string.format("[IslandGenerator] Generating %d islands (%s placement)",
        islandCount, placementMode))

    -- Load base island
    local TiledMapLoader = require("src.maps.TiledMapLoader")
    local baseMap = TiledMapLoader.load(baseIslandDef.mapPath)
    if not baseMap then
        print("[IslandGenerator] ERROR: Failed to load base island map")
        return {}, {}
    end

    local baseIsland = {
        id = baseIslandDef.id,
        definition = baseIslandDef,
        map = baseMap,
        x = baseIslandDef.x or 0,
        y = baseIslandDef.y or 0,
        width = baseMap.width * baseMap.tilewidth,
        height = baseMap.height * baseMap.tileheight
    }

    local generated = {}
    local allIslands = {baseIsland}

    -- Generate islands
    for i = 1, islandCount do
        local islandDef = weightedRandom(islandPool)
        if not islandDef then
            print("[IslandGenerator] WARNING: No island definition available")
            break
        end

        -- Load island map
        local islandMap = TiledMapLoader.load(islandDef.mapPath)
        if not islandMap then
            print(string.format("[IslandGenerator] ERROR: Failed to load island map: %s", islandDef.mapPath))
            break
        end

        local island = {
            id = islandDef.id,
            definition = islandDef,
            map = islandMap,
            x = 0,
            y = 0,
            width = islandMap.width * islandMap.tilewidth,
            height = islandMap.height * islandMap.tileheight
        }

        -- Place island adjacent to base island or existing islands
        local placed = false
        local maxAttempts = 100

        for attempt = 1, maxAttempts do
            if placementMode == "tile-based" or placementMode == "scattered" then
                -- Tile-based placement: place islands like tiles next to existing ones
                local targetIsland = allIslands[math.random(#allIslands)]
                local edges = {"north", "south", "east", "west"}
                local edge = edges[math.random(#edges)]

                if edge == "north" then
                    island.x = targetIsland.x
                    island.y = targetIsland.y - island.height
                elseif edge == "south" then
                    island.x = targetIsland.x
                    island.y = targetIsland.y + targetIsland.height
                elseif edge == "east" then
                    island.x = targetIsland.x + targetIsland.width
                    island.y = targetIsland.y
                elseif edge == "west" then
                    island.x = targetIsland.x - island.width
                    island.y = targetIsland.y
                end

                -- Check for overlaps with existing islands
                local hasOverlap = false
                for _, existingIsland in ipairs(allIslands) do
                    if islandsOverlap(island, existingIsland, 0) then
                        hasOverlap = true
                        break
                    end
                end

                if not hasOverlap then
                    print(string.format("[IslandGenerator] Placed %s at (%d, %d) [%s edge]",
                        islandDef.name, island.x, island.y, edge))
                    placed = true
                    break
                end
            else
                -- Random placement with collision avoidance
                island.x, island.y = getRandomPosition(baseIsland, island, placementMode)

                -- Check for overlaps with existing islands
                local hasOverlap = false
                for _, existingIsland in ipairs(allIslands) do
                    if islandsOverlap(island, existingIsland, 10) then
                        hasOverlap = true
                        break
                    end
                end

                if not hasOverlap then
                    placed = true
                    break
                end
            end
        end

        if placed then
            table.insert(generated, island)
            table.insert(allIslands, island)
        else
            print(string.format("[IslandGenerator] WARNING: Failed to place island %s after %d attempts",
                islandDef.name, maxAttempts))
        end
    end

    print(string.format("[IslandGenerator] Loaded %d islands total", #allIslands))

    -- Generate bridges between islands
    print(string.format("[IslandGenerator] Generating bridges with tileSize=%d", generation.tileSize))
    local bridges = IslandGenerator.generateBridges(generated, baseIsland, generation.tileSize)
    print(string.format("[IslandGenerator] Created %d bridges total", #bridges))

    return generated, bridges
end

-- Generate bridges between adjacent islands
---@param islands table Array of generated islands
---@param baseIsland table Base island
---@param tileSize number Tile size in pixels
---@return table Array of bridge definitions
function IslandGenerator.generateBridges(islands, baseIsland, tileSize)
    local bridges = {}
    local allIslands = {baseIsland}

    -- Combine base island with generated islands
    for _, island in ipairs(islands) do
        table.insert(allIslands, island)
    end

    -- Track which island pairs we've already processed to avoid duplicates
    local processedPairs = {}

    -- For each island, find its direct neighbors (adjacent islands only)
    for i = 1, #allIslands do
        local island1 = allIslands[i]
        local adjacentIslands = {}

        -- Find islands that are directly adjacent to this island
        for j = i + 1, #allIslands do  -- Start from i+1 to avoid duplicates
            local island2 = allIslands[j]

            -- Check if islands are directly adjacent (touching edges)
            if IslandGenerator.areIslandsAdjacent(island1, island2, tileSize) then
                table.insert(adjacentIslands, island2)
            end
        end

        -- Create bridges only to adjacent islands (max 4 per island)
        for _, adjacentIsland in ipairs(adjacentIslands) do
            local result = IslandGenerator.createBridgeIfAdjacent(island1, adjacentIsland, tileSize)
            if result then
                -- result can be a single bridge or an array of bridges
                if result.x then
                    -- Single bridge
                    table.insert(bridges, result)
                    print(string.format("[Bridge] Connected '%s' to '%s' (%s, %d tiles, gap=%d)",
                        island1.definition and island1.definition.name or "Base",
                        adjacentIsland.definition and adjacentIsland.definition.name or "Base",
                        result.direction, result.length, result.gapTiles or 0))
                else
                    -- Array of bridges
                    for _, bridge in ipairs(result) do
                        table.insert(bridges, bridge)
                        print(string.format("[Bridge] Connected '%s' to '%s' (%s, %d tiles, gap=%d)",
                            island1.definition and island1.definition.name or "Base",
                            adjacentIsland.definition and adjacentIsland.definition.name or "Base",
                            bridge.direction, bridge.length, bridge.gapTiles or 0))
                    end
                end
            end
        end

        print(string.format("[Bridge Debug] Island '%s' has %d adjacent islands",
            island1.definition and island1.definition.name or "Base", #adjacentIslands))
    end

    return bridges
end

-- Check if two islands are directly adjacent (touching edges)
---@param island1 table First island
---@param island2 table Second island
---@param tileSize number Tile size in pixels
---@return boolean True if islands are adjacent
function IslandGenerator.areIslandsAdjacent(island1, island2, tileSize)
    local i1x, i1y = island1.x, island1.y
    local i1w, i1h = island1.width, island1.height
    local i2x, i2y = island2.x, island2.y
    local i2w, i2h = island2.width, island2.height

    -- Allow small tolerance for floating point precision
    local tolerance = tileSize * 0.5

    -- Check if islands are horizontally adjacent (left/right touching)
    local verticalOverlap = not (i1y + i1h < i2y + tolerance or i2y + i2h < i1y + tolerance)
    if verticalOverlap then
        -- Island1 is directly left of Island2
        if math.abs((i1x + i1w) - i2x) <= tolerance then
            return true
        end
        -- Island2 is directly left of Island1
        if math.abs((i2x + i2w) - i1x) <= tolerance then
            return true
        end
    end

    -- Check if islands are vertically adjacent (top/bottom touching)
    local horizontalOverlap = not (i1x + i1w < i2x + tolerance or i2x + i2w < i1x + tolerance)
    if horizontalOverlap then
        -- Island1 is directly above Island2
        if math.abs((i1y + i1h) - i2y) <= tolerance then
            return true
        end
        -- Island2 is directly above Island1
        if math.abs((i2y + i2h) - i1y) <= tolerance then
            return true
        end
    end

    return false
end

-- Extract connection points from a map
---@param map table Tiled map data
---@return table Array of connection point objects
function IslandGenerator.getConnectionPoints(map)
    local connections = {}

    if not map or not map.layers then
        print("[Bridge Debug] No map or layers found")
        return connections
    end

    print(string.format("[Bridge Debug] Map has %d layers", #map.layers))

    -- Find the Bridges layer
    for i, layer in ipairs(map.layers) do
        print(string.format("[Bridge Debug] Layer %d: name='%s', type='%s', objects=%s",
            i, layer.name or "nil", layer.type or "nil", layer.objects and "yes" or "no"))

        if layer.name == "Bridges" and layer.objects then
            print(string.format("[Bridge Debug] Found Bridges layer with %d objects", #layer.objects))
            for j, obj in ipairs(layer.objects) do
                print(string.format("[Bridge Debug] Object %d: name='%s', type='%s'",
                    j, obj.name or "nil", obj.type or "nil"))
                if obj.name == "ConnectionPoint" then
                    table.insert(connections, {
                        x = obj.x,
                        y = obj.y,
                        width = obj.width,
                        height = obj.height
                    })
                    print(string.format("[Bridge Debug] Added connection point at (%d,%d)", obj.x, obj.y))
                end
            end
            break
        end
    end

    print(string.format("[Bridge Debug] Found %d connection points total", #connections))
    return connections
end

-- Check if two islands are adjacent and create a bridge if they are
---@param island1 table First island
---@param island2 table Second island
---@param tileSize number Tile size in pixels
---@return table|nil Bridge definition or nil if not adjacent
function IslandGenerator.createBridgeIfAdjacent(island1, island2, tileSize)
    local i1x, i1y = island1.x, island1.y
    local i1w, i1h = island1.width, island1.height
    local i2x, i2y = island2.x, island2.y
    local i2w, i2h = island2.width, island2.height

    local maxGap = tileSize * 15 -- Allow up to 15 tiles gap between connection points

    -- Get connection points from both islands
    local i1Connections = IslandGenerator.getConnectionPoints(island1.map)
    local i2Connections = IslandGenerator.getConnectionPoints(island2.map)

    -- Debug connection points
    print(string.format("[Bridge Debug] Island1 has %d connection points, Island2 has %d connection points",
        #i1Connections, #i2Connections))

    -- Find the best connection point pair (closest distance)
    local bestBridge = nil
    local bestDistance = math.huge

    for _, cp1 in ipairs(i1Connections) do
        for _, cp2 in ipairs(i2Connections) do
            -- Convert connection points to world coordinates
            local cp1WorldX = i1x + cp1.x
            local cp1WorldY = i1y + cp1.y
            local cp2WorldX = i2x + cp2.x
            local cp2WorldY = i2y + cp2.y

            -- Check if connection points are close enough for a bridge
            local distance = math.sqrt((cp2WorldX - cp1WorldX)^2 + (cp2WorldY - cp1WorldY)^2)

            if distance <= maxGap and distance < bestDistance then
                -- This is the best connection point pair so far
                bestDistance = distance

                -- Determine bridge direction and create bridge that connects exactly from point to point
                local bridgeX, bridgeY, bridgeWidth, bridgeHeight, direction

                if math.abs(cp2WorldY - cp1WorldY) < math.abs(cp2WorldX - cp1WorldX) then
                    -- Horizontal bridge: connect horizontally from one point to the other
                    direction = "horizontal"
                    bridgeX = math.min(cp1WorldX, cp2WorldX)
                    bridgeY = cp1WorldY - 16 -- Center the 32-pixel tall bridge on the connection point
                    bridgeWidth = math.abs(cp2WorldX - cp1WorldX)
                    bridgeHeight = 32 -- 32 pixels tall
                else
                    -- Vertical bridge: connect vertically from one point to the other
                    direction = "vertical"
                    bridgeX = cp1WorldX - 16 -- Center the 32-pixel wide bridge on the connection point
                    bridgeY = math.min(cp1WorldY, cp2WorldY)
                    bridgeWidth = 32 -- 32 pixels wide
                    bridgeHeight = math.abs(cp2WorldY - cp1WorldY)
                end

                bestBridge = {
                    x = bridgeX,
                    y = bridgeY,
                    width = bridgeWidth,
                    height = bridgeHeight,
                    direction = direction,
                    length = direction == "horizontal" and math.floor(bridgeWidth / tileSize) or math.floor(bridgeHeight / tileSize),
                    gapTiles = math.floor(distance / tileSize),
                    island1 = island1.id or "base",
                    island2 = island2.id or "base"
                }

                -- Debug bridge creation
                print(string.format("[Bridge Debug] Best bridge: %s from (%d,%d) to (%d,%d) at (%d,%d) size %dx%d, distance=%.1f",
                    direction, cp1WorldX, cp1WorldY, cp2WorldX, cp2WorldY, bridgeX, bridgeY, bridgeWidth, bridgeHeight, distance))
            end
        end
    end

    return bestBridge
end

return IslandGenerator
