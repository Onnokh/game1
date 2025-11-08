local System = require("src.core.System")
local EventBus = require("src.utils.EventBus")
local fonts = require("src.utils.fonts")
local ui_text = require("src.utils.ui_text")
local gameState = require("src.core.GameState")

---@class LootPickupLabelSystem : System
---@field labels table
---@field ecsWorld World
local LootPickupLabelSystem = System:extend("LootPickupLabelSystem", {})

function LootPickupLabelSystem.new(ecsWorld)
    ---@class LootPickupLabelSystem
	local self = System.new()
    setmetatable(self, LootPickupLabelSystem)
    self.labels = {}
    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- draw in screen space (convert world to screen manually)

    EventBus.subscribe("coinPickedUp", function(payload)
        local amount = (payload and payload.amount) or 1
        local worldX = (payload and payload.worldX) or 0
        local worldY = (payload and payload.worldY) or 0

        -- Store world position and animate in world space, convert to screen during draw
        table.insert(self.labels, {
            text = string.format("+%d gold", amount),
            worldX = worldX,
            worldY = worldY, -- a bit above the coin
            ttl = 0.9,
            ttlMax = 0.9,
            vy = 0, -- float upward in world space
            color = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }, -- white
        })
    end)

    return self
end

function LootPickupLabelSystem:update(dt)
    for i = #self.labels, 1, -1 do
        local l = self.labels[i]
        l.ttl = l.ttl - dt
        l.worldY = l.worldY + l.vy * dt -- animate in world space
        if l.ttl <= 0 then
            table.remove(self.labels, i)
        end
    end
end

function LootPickupLabelSystem:draw()
    for _, l in ipairs(self.labels) do
        local r, g, b, a = love.graphics.getColor()

        -- Convert world position to screen coordinates each frame
        local CoordinateUtils = require("src.utils.coordinates")
        local screenX, screenY = CoordinateUtils.worldToScreen(l.worldX, l.worldY, gameState.camera)

        -- Choose a camera-scaled crisp font similar to damage numbers
        local cameraScale = (gameState and gameState.camera and gameState.camera.scale) or 1
        local basePx = 24
        local font = select(1, fonts.getCameraScaled(basePx, cameraScale, 8))
        local prevFont = love.graphics.getFont()

        love.graphics.push()
        love.graphics.origin()
        if font then love.graphics.setFont(font) end

        -- Fade out over time
        local alpha = math.max(0, math.min(1, (l.ttl / (l.ttlMax or 1))))
        local color = l.color
        love.graphics.setColor(color.r, color.g, color.b, alpha)

        local text = l.text
        local w = font and font:getWidth(text) or 0
        local h = font and font:getHeight() or 0
        local x = math.floor(screenX - w * 0.5 + 0.5)
        local y = math.floor(screenY - h + 0.5)

        -- Simple scale-in then out similar to damage numbers
        local progress = 1 - alpha
        local startScale, endScale = 1.2, 0.8
        local currentScale = startScale + (endScale - startScale) * progress

        love.graphics.push()
        love.graphics.translate(x + w * 0.5, y + h * 0.5)
        love.graphics.scale(currentScale, currentScale)

        -- Outline for readability over the world
        local outlinePx = 1 / currentScale
        ui_text.drawOutlinedText(text, -w * 0.5, -h * 0.5, {color.r, color.g, color.b, alpha}, {0,0,0,alpha}, outlinePx)

        love.graphics.pop()

        love.graphics.pop()
        if prevFont then love.graphics.setFont(prevFont) end
        love.graphics.setColor(r, g, b, a)
    end
end

return LootPickupLabelSystem


