local System = require("src.core.System")
local GameTimeManager = require("src.core.managers.GameTimeManager")
local fonts = require("src.utils.fonts")
local Panel = require("src.ui.utils.panel")

---@class WaveTimerSystem : System
---@field ecsWorld World
---@field isWorldSpace boolean
local WaveTimerSystem = System:extend("WaveTimerSystem", {})

---Initialize the wave timer system
---@param ecsWorld World ECS world
---@return WaveTimerSystem
function WaveTimerSystem.new(ecsWorld)
    local self = System.new()
    setmetatable(self, WaveTimerSystem)

    self.ecsWorld = ecsWorld
    self.isWorldSpace = false -- This UI system draws in screen space

    return self
end

---Draw the wave timer
function WaveTimerSystem:draw()
    if not GameTimeManager then return end

    local currentTime = GameTimeManager.getTime()
    local timeString = GameTimeManager.formatTime(currentTime)

    -- Get current wave number from GameTimeManager
    local waveNumber = GameTimeManager.getCurrentWave()
    if waveNumber == 0 then
        waveNumber = 1 -- Default to wave 1 if no wave is active
    end

    -- Set large font for prominent display using centralized font management
    local font = fonts.getUIFont(64)
    love.graphics.setFont(font)

    -- Get screen dimensions
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    -- Calculate position (center-top, more prominent placement)
    local textWidth = font:getWidth(timeString)
    local x = (screenWidth - textWidth) / 2
    local y = 40

    -- Draw background panel with padding
    local padding = 20
    local bgWidth = textWidth + padding * 2
    local bgHeight = font:getHeight() + padding * 2
    local bgX = x - padding
    local bgY = y - padding

    -- Draw main background panel
    Panel.draw(bgX, bgY, bgWidth, bgHeight, 0.5, {0, 0, 0}, nil)

    -- Draw border panel
    Panel.draw(bgX, bgY, bgWidth, bgHeight, 1.0, {0.2, 0.2, 0.2}, "border-000")

    -- Draw main timer text
    love.graphics.setFont(font)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(timeString, x, y)

    -- Draw wave number below timer using centralized font management
    local waveFont = fonts.getUIFont(24)
    love.graphics.setFont(waveFont)
    local waveText = "WAVE " .. waveNumber
    local waveTextWidth = waveFont:getWidth(waveText)
    local waveX = (screenWidth - waveTextWidth) / 2
    local waveY = y + font:getHeight() + 4 -- Position below timer with spacing

    -- Draw wave text
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print(waveText, waveX, waveY)

    -- Reset color
    love.graphics.setColor(1, 1, 1, 1)
end

return WaveTimerSystem
