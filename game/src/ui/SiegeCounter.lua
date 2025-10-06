---@class SiegeCounter: UIElement
local UIElement = require("src.ui.UIElement")
local fonts = require("src.utils.fonts")

local SiegeCounter = setmetatable({}, { __index = UIElement })
SiegeCounter.__index = SiegeCounter

function SiegeCounter.new()
    local self = setmetatable(UIElement.new(), SiegeCounter)
    return self
end

function SiegeCounter:update(dt)
    -- no-op
end

function SiegeCounter:draw()
    if not self.visible then return end

    local GameScene = require("src.scenes.game")
    local ecsWorld = GameScene and GameScene.ecsWorld
    if not ecsWorld then return end

    -- Count alive siege attackers
    local attackers = ecsWorld:getEntitiesWithTag("SiegeAttacker")
    local alive = 0
    for _, e in ipairs(attackers) do
        if not e.isDead then
            alive = alive + 1
        end
    end

    -- Only show during Siege phase
    local GameState = require("src.core.GameState")
    if not GameState or GameState.phase ~= "Siege" then return end

    local sw, _ = love.graphics.getDimensions()
    local prevFont = love.graphics.getFont()
    local r, g, b, a = love.graphics.getColor()

    love.graphics.push()
    love.graphics.origin()

    local text = string.format("Attackers: %d", alive)
    local font = fonts.getUIFont(22)
    if font then love.graphics.setFont(font) end
    local tw = (font and font:getWidth(text)) or 0
    local tx = sw - tw - 24
    local ty = 24

    love.graphics.setColor(0, 0, 0, 0.8)
    love.graphics.print(text, tx + 1, ty + 1)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(text, tx, ty)

    if prevFont then love.graphics.setFont(prevFont) end
    love.graphics.setColor(r, g, b, a)
    love.graphics.pop()
end

return SiegeCounter



