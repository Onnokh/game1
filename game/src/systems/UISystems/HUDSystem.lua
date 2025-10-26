local System = require("src.core.System")
local HealthBarHUD = require("src.ui.HealthBarHUD")
local DashChargesHUD = require("src.ui.DashChargesHUD")
local ActiveUpgradesHUD = require("src.ui.ActiveUpgradesHUD")
local GameState = require("src.core.GameState")

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
	return self
end

function HUDSystem:draw()
    if not self.ecsWorld then return end

    -- Draw the existing HUD health bar
    HealthBarHUD.draw(self.ecsWorld)

    -- Draw dash charges below the health bar
    DashChargesHUD.draw(self.ecsWorld)


    -- Draw active upgrades on the right side
    ActiveUpgradesHUD.draw(self.ecsWorld)

    -- Delegate HUD damage numbers to HealthBarSystem
    if self.healthBarSystem and self.healthBarSystem.drawHUD then
        self.healthBarSystem:drawHUD()
    end

    -- Auto-aim indicator
    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()

    if GameState.input.autoAim then
        love.graphics.setColor(1, 0.8, 0, 1)  -- Yellow/orange color
        love.graphics.print("AUTO-AIM: ON (AUTO-SHOOT)", 10, screenHeight - 60)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    else
        love.graphics.setColor(0.7, 0.7, 0.7, 1)  -- Gray color for hint
        love.graphics.print("Press T to auto Aim", 10, screenHeight - 60)
        love.graphics.setColor(1, 1, 1, 1)  -- Reset color
    end
end

return HUDSystem


