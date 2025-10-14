-- TileLightSpawner.lua
-- Utility for spawning light entities for specific tile GIDs

local TileLightSpawner = {}

local GameConstants = require("src.constants")
local Entity = require("src.core.Entity")
local Position = require("src.components.Position")
local Light = require("src.components.Light")

---Spawn light entities for all tiles in an island that have lights configured
---@param island table Island data with map, position, etc.
---@param ecsWorld World ECS world to add light entities to
---@return number Count of light entities spawned
function TileLightSpawner.spawnLightsForIsland(island, ecsWorld)
    if not island or not island.map or not ecsWorld then
        return 0
    end

    local islandMap = island.map
    local islandX = island.x
    local islandY = island.y
    local tileSize = islandMap.tilewidth or GameConstants.TILE_SIZE

    local lightsSpawned = 0

    -- Iterate through all tile layers
    for _, layer in ipairs(islandMap.layers or {}) do
        if layer.type == "tilelayer" and layer.data then
            -- Iterate through all tiles in the layer
            for tileIndex = 1, #layer.data do
                local gid = layer.data[tileIndex]

                -- Check if this GID has a light configuration
                local lightConfig = GameConstants.TILE_LIGHTS[gid]
                if lightConfig and gid > 0 then
                    -- Calculate tile position
                    local tileX = ((tileIndex - 1) % islandMap.width)
                    local tileY = math.floor((tileIndex - 1) / islandMap.width)

                    -- Convert to world coordinates
                    local worldX = islandX + (tileX * tileSize)
                    local worldY = islandY + (tileY * tileSize)

                    -- Calculate light position (default to center of tile if no offset specified)
                    local lightX = worldX + (lightConfig.offsetX or (tileSize / 2))
                    local lightY = worldY + (lightConfig.offsetY or (tileSize / 2))

                    -- Create light entity
                    local lightEntity = Entity.new()
                    lightEntity:addTag("TileLight")
                    lightEntity:addTag(string.format("TileLight_GID_%d", gid))

                    -- Add position component
                    lightEntity:addComponent("Position", Position.new(lightX, lightY))

                    -- Build light component options
                    local lightOpts = {
                        radius = lightConfig.radius or 200,
                        r = lightConfig.r or 255,
                        g = lightConfig.g or 255,
                        b = lightConfig.b or 255,
                        a = lightConfig.a or 255,
                        offsetX = 0, -- Already applied to position
                        offsetY = 0, -- Already applied to position
                        enabled = lightConfig.enabled ~= false,
                        flicker = lightConfig.flicker or false,
                    }

                    -- Add flicker properties if enabled
                    if lightConfig.flicker then
                        lightOpts.flickerSpeed = lightConfig.flickerSpeed or 8
                        lightOpts.flickerRadiusAmplitude = lightConfig.flickerRadiusAmplitude or 10
                        lightOpts.flickerAlphaAmplitude = lightConfig.flickerAlphaAmplitude or 20
                    end

                    lightEntity:addComponent("Light", Light.new(lightOpts))

                    -- Add to world
                    ecsWorld:addEntity(lightEntity)
                    lightsSpawned = lightsSpawned + 1
                end
            end
        end
    end

    return lightsSpawned
end

---Spawn light entities for all loaded islands
---@param islands table Array of island data
---@param ecsWorld World ECS world to add light entities to
---@return number Total count of light entities spawned
function TileLightSpawner.spawnLightsForAllIslands(islands, ecsWorld)
    local totalLights = 0

    for _, island in ipairs(islands or {}) do
        local count = TileLightSpawner.spawnLightsForIsland(island, ecsWorld)
        if count > 0 then
            print(string.format("[TileLightSpawner] Island '%s': spawned %d tile lights",
                island.definition.name or island.id, count))
        end
        totalLights = totalLights + count
    end

    if totalLights > 0 then
        print(string.format("[TileLightSpawner] Total tile lights spawned: %d", totalLights))
    end

    return totalLights
end

return TileLightSpawner

