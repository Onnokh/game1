local System = require("src.core.System")
local HealthBarHUD = require("src.ui.HealthBarHUD")
local DashChargesHUD = require("src.ui.DashChargesHUD")
local OxygenHUD = require("src.ui.OxygenHUD")

---@class HUDSystem : System
---@field ecsWorld World
local HUDSystem = System:extend("HUDSystem", {})

function HUDSystem.new(ecsWorld, healthBarSystem)
	---@class HUDSystem
	local self = System.new({})
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

    -- Draw oxygen bar above the health bar
    OxygenHUD.draw(self.ecsWorld)

    -- Delegate HUD damage numbers to HealthBarSystem
    if self.healthBarSystem and self.healthBarSystem.drawHUD then
        self.healthBarSystem:drawHUD()
    end
end

return HUDSystem


