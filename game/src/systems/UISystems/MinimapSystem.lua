local System = require("src.core.System")
local Minimap = require("src.ui.Minimap")

---@class MinimapSystem : System
---@field ecsWorld World The ECS world to query entities from
---@field isWorldSpace boolean Whether system draws in world space
local MinimapSystem = setmetatable({}, { __index = System })
MinimapSystem.__index = MinimapSystem

---Create a new MinimapSystem
---@param ecsWorld World The ECS world to query entities from
---@return MinimapSystem
function MinimapSystem.new(ecsWorld)
    ---@class MinimapSystem
    local self = setmetatable(System.new(), MinimapSystem)
    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- This UI system draws in screen space

    -- Don't use requiredComponents since we're querying ecsWorld directly
    -- (this system is in uiWorld but queries entities from ecsWorld)

    -- Initialize minimap canvas
    Minimap.init()

    return self
end

---Draw the minimap
function MinimapSystem:draw()
    if not self.ecsWorld then return end

    -- Get player entity
    local playerEntity = self.ecsWorld._cachedPlayer
    if not playerEntity then return end

    local playerPos = playerEntity:getComponent("Position")
    if not playerPos then return end

    -- Get map data
    local GameState = require("src.core.GameState")
    if not GameState.mapData or not GameState.mapData.collisionGrid then
        return
    end

    -- Draw minimap (includes terrain and background)
    local minimapX, minimapY = Minimap.draw(playerPos.x, playerPos.y)

    -- Query entities from ecsWorld (not from self.entities which is uiWorld)
    local minimapEntities = {}
    for _, entity in ipairs(self.ecsWorld.entities) do
        if entity:hasComponent("Position") and entity:hasComponent("MinimapIcon") then
            table.insert(minimapEntities, entity)
        end
    end

    -- Debug: Print entity count
    if love.keyboard.isDown("m") then
        print(string.format("[Minimap] Found %d entities with MinimapIcon in ecsWorld", #minimapEntities))
    end

    -- Draw entities with MinimapIcon component
    for _, entity in ipairs(minimapEntities) do
        local position = entity:getComponent("Position")
        local minimapIcon = entity:getComponent("MinimapIcon")

        if position and minimapIcon then
            -- Check if entity is within visible range
            if Minimap.isInVisibleRange(position.x, position.y, playerPos.x, playerPos.y) then
                -- Convert to minimap coordinates
                local iconX, iconY = Minimap.worldToMinimap(
                    position.x,
                    position.y,
                    playerPos.x,
                    playerPos.y
                )

                -- Draw icon
                if iconX and iconY then
                    local screenX = minimapX + iconX
                    local screenY = minimapY + iconY
                    self:drawIcon(screenX, screenY, minimapIcon)
                end
            end
        end
    end
end

---Draw an icon on the minimap
---@param x number Screen X coordinate
---@param y number Screen Y coordinate
---@param minimapIcon MinimapIcon The minimap icon component
function MinimapSystem:drawIcon(x, y, minimapIcon)
    local color = minimapIcon.color
    local size = minimapIcon.iconSize or 5
    local iconType = minimapIcon.iconType

    -- Normalize color values (0-255 to 0-1 range)
    local r = color.r / 255
    local g = color.g / 255
    local b = color.b / 255

    -- Draw icon image if available, otherwise draw shape based on type
    if minimapIcon.icon then
        -- Draw the icon image without color tinting
        local iconSize = size * 4 -- Scale up the icon size
        love.graphics.setColor(1, 1, 1, 1) -- White (no tint)
        love.graphics.draw(
            minimapIcon.icon,
            x, y,
            0, -- rotation
            iconSize / minimapIcon.icon:getWidth(), -- scale X
            iconSize / minimapIcon.icon:getHeight(), -- scale Y
            minimapIcon.icon:getWidth() / 2, -- origin X (center)
            minimapIcon.icon:getHeight() / 2 -- origin Y (center)
        )
    else
        -- Default: simple circle
        love.graphics.setColor(0, 0, 0, 1)
        love.graphics.circle("fill", x, y, size + 1)
        love.graphics.setColor(r, g, b, 1)
        love.graphics.circle("fill", x, y, size)
    end
end

---Cleanup minimap resources
function MinimapSystem:cleanup()
    Minimap.cleanup()
end

return MinimapSystem

