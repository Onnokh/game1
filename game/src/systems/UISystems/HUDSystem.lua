local System = require("src.core.System")
local UnitframeHUD = require("src.ui.UnitframeHUD")
local DashChargesHUD = require("src.ui.DashChargesHUD")
local ActiveUpgradesHUD = require("src.ui.ActiveUpgradesHUD")
local CastBarHUD = require("src.ui.CastBarHUD")
local ExperienceHUD = require("src.ui.ExperienceHUD")
local GameState = require("src.core.GameState")
local fonts = require("src.utils.fonts")

---@class HUDSystem : System
---@field ecsWorld World
local HUDSystem = System:extend("HUDSystem", {})

function HUDSystem.new(ecsWorld, healthBarSystem)
	---@class HUDSystem
	local self = System.new()
	setmetatable(self, HUDSystem)
	self.ecsWorld = ecsWorld
	self.healthBarSystem = healthBarSystem -- Reference to HealthBarSystem for damage tracking
	self.isWorldSpace = false -- This UI system draws in screen space
	self.drawOrder = 150 -- Draw above action bar (100) but below tooltips (9999)
	return self
end

function HUDSystem:draw()
    if not self.ecsWorld then return end

    -- Draw experience bar (above action bar and unitframe)
    ExperienceHUD.draw(self.ecsWorld)

    -- Draw the existing HUD health bar
    UnitframeHUD.draw(self.ecsWorld)

    -- Draw dash charges below the health bar
    DashChargesHUD.draw(self.ecsWorld)

    -- Draw cast bar (above action bar, if casting)
    CastBarHUD.draw(self.ecsWorld)

    -- Draw active upgrades on the right side
    ActiveUpgradesHUD.draw(self.ecsWorld)

    -- Delegate HUD damage numbers to HealthBarSystem
    if self.healthBarSystem and self.healthBarSystem.drawHUD then
        self.healthBarSystem:drawHUD()
    end

    -- Auto-aim indicator (top-left, above coin counter)
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local TOP_MARGIN = 32
    local AUTO_AIM_Y = TOP_MARGIN

    local font = fonts.getUIFont(18)
    local prevFont = love.graphics.getFont()
    if font then love.graphics.setFont(font) end

    if GameState.input.autoAim then
        love.graphics.setColor(1, 0.8, 0, 1)  -- Yellow/orange color
        love.graphics.print("AUTO-AIM: ON (AUTO-SHOOT)", 32, AUTO_AIM_Y)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    else
        love.graphics.setColor(0.7, 0.7, 0.7, 1)  -- Gray color for hint
        love.graphics.print("Press T to auto Aim", 32, AUTO_AIM_Y)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end

    if prevFont then love.graphics.setFont(prevFont) end
end

return HUDSystem


