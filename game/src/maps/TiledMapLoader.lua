-- TiledMapLoader.lua
-- Handles loading and rendering of Tiled maps (.lua or .tmx format)
-- Provides abstraction layer for map rendering and collision detection
-- Uses Cartographer library for Tiled map support

local TiledMapLoader = {}

-- Cache loaded maps to avoid reloading
local mapCache = {}

local cartographer = require("lib.cartographer")

---@param mapPath string Path to the Tiled map file (.lua or .tmx)
---@return table Loaded map instance
function TiledMapLoader.load(mapPath)
    -- Check cache first
    if mapCache[mapPath] then
        -- Silently return cached map to reduce console spam
        return mapCache[mapPath]
    end

    -- Verify file exists first
    local fileInfo = love.filesystem.getInfo(mapPath)
    if not fileInfo then
        print("[TiledMapLoader] ERROR: File not found: " .. mapPath)
        print("[TiledMapLoader] Current directory: " .. love.filesystem.getIdentity())
        print("[TiledMapLoader] Looking for file at: " .. love.filesystem.getSaveDirectory())
        return nil
    end

    -- Read the map file as text and fix paths before loading
    local content = love.filesystem.read(mapPath)
    if not content then
        print("[TiledMapLoader] ERROR: Could not read map file: " .. mapPath)
        return nil
    end

    -- Fix relative image paths (../../../ -> resources/)
    -- The Tiled exports have paths like: ../../../reactor/file.png
    -- We need to replace the ../ sequence with resources/
    content = content:gsub('%.%.%/%.%.%/%.%.%/', 'resources/')

    -- Debug: print what we're seeing
    if content:match('%.%.%/') then
        print("[TiledMapLoader] WARNING: Still have ../ in paths after replacement")
        -- Show a sample
        local sample = content:match('image = "([^"]*%.%.%/[^"]*)"')
        if sample then
            print("[TiledMapLoader] Example path: " .. sample)
        end
    end

    -- Write to a temporary file
    local tempPath = "temp_map_fixed.lua"
    love.filesystem.write(tempPath, content)

    -- Load with Cartographer
    local success, map = pcall(function()
        return cartographer.load(tempPath)
    end)

    -- Clean up temp file
    love.filesystem.remove(tempPath)

    if not success then
        print("[TiledMapLoader] ERROR loading map: " .. mapPath)
        print("[TiledMapLoader] Error: " .. tostring(map))
        return nil
    end

    -- Set pixel-perfect filtering for all tileset images
    if map and map._images then
        for _, image in pairs(map._images) do
            image:setFilter("nearest", "nearest")
        end
    end

    -- Cache the loaded map
    mapCache[mapPath] = map

    print("[TiledMapLoader] Loaded map: " .. mapPath)
    return map
end

---@param map table The map instance to draw
---@param camera table|nil Optional camera for view culling
function TiledMapLoader.draw(map, camera)
    if not map then return end

    -- Cartographer handles rendering internally
    -- Just call its draw method
    if map.draw then
        map:draw()
    end
end

---@param map table The map instance
---@param layer table The specific layer to draw
---@param camera table|nil Optional camera for view culling
function TiledMapLoader.drawLayer(map, layer, camera)
    -- TODO: Draw individual layer with culling
end

---@param map table The map instance to update
---@param dt number Delta time
function TiledMapLoader.update(map, dt)
    if not map then return end

    -- Cartographer handles animation updates
    if map.update then
        map:update(dt)
    end
end

---@param map table The map instance
---@param x number World X coordinate
---@param y number World Y coordinate
---@return boolean True if the tile is solid/collidable
function TiledMapLoader.isSolid(map, x, y)
    -- TODO: Check collision layer or tile properties
    return false
end

---@param map table The map instance
---@return table List of collision shapes for physics
function TiledMapLoader.getCollisionShapes(map)
    local shapes = {}

    if not map or not map.layers then
        return shapes
    end

    -- Look for collision objects in object layers
    for _, layer in ipairs(map.layers) do
        if layer.type == "objectgroup" and layer.objects then
            for _, obj in ipairs(layer.objects) do
                if obj.shape == "rectangle" then
                    table.insert(shapes, {
                        type = "rectangle",
                        x = obj.x,
                        y = obj.y,
                        width = obj.width,
                        height = obj.height
                    })
                elseif obj.shape == "polygon" and obj.polygon then
                    table.insert(shapes, {
                        type = "polygon",
                        x = obj.x,
                        y = obj.y,
                        vertices = obj.polygon
                    })
                end
            end
        end
    end

    return shapes
end

---@param map table The map instance
---@param objectType string Type of object to find (e.g., "spawn", "enemy")
---@return table List of objects matching the type
function TiledMapLoader.getObjects(map, objectType)
    local results = {}

    if not map or not map.layers then
        return results
    end

    -- Search through object layers
    for _, layer in ipairs(map.layers) do
        if layer.type == "objectgroup" and layer.objects then
            for _, obj in ipairs(layer.objects) do
                if obj.type == objectType or obj.name == objectType then
                    table.insert(results, obj)
                end
            end
        end
    end

    return results
end

---Parse objects from map layers into categorized groups
---@param map table The Cartographer map instance
---@return table Categorized objects {spawn, enemies, reactors, other}
function TiledMapLoader.parseObjects(map)
    local objects = {
        spawn = nil,
        enemies = {},
        reactors = {},
        other = {}
    }

    if not map or not map.layers then
        return objects
    end

    for _, layer in ipairs(map.layers) do
        if layer.type == "objectgroup" and layer.objects then
            for _, obj in ipairs(layer.objects) do
                if obj.visible ~= false then
                    if obj.name == "Spawn" then
                        objects.spawn = { x = obj.x, y = obj.y }
                    elseif obj.name:match("^Enemy") or obj.type == "enemy" then
                        table.insert(objects.enemies, obj)
                    elseif obj.name:match("^Reactor") or obj.type == "reactor" then
                        table.insert(objects.reactors, obj)
                    else
                        table.insert(objects.other, obj)
                    end
                end
            end
        end
    end

    return objects
end

---@param mapPath string Path to clear from cache
function TiledMapLoader.clearCache(mapPath)
    if mapPath then
        mapCache[mapPath] = nil
    else
        mapCache = {}
    end
end

return TiledMapLoader

