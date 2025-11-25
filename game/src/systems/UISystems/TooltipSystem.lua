local System = require("src.core.System")
local TooltipSystemUI = require("src.ui.TooltipSystem")

---@class TooltipSystemUISystem : System
---Draws tooltips on top of all other UI
local TooltipSystemUISystem = System:extend("TooltipSystemUISystem", {})

function TooltipSystemUISystem.new()
	---@class TooltipSystemUISystem
	local self = System.new()
	setmetatable(self, TooltipSystemUISystem)
	self.isWorldSpace = false -- This UI system draws in screen space
	self.drawOrder = 9999 -- Very high draw order to ensure it draws on top
	return self
end

function TooltipSystemUISystem:draw()
    -- Draw tooltips on top of all other UI
    TooltipSystemUI.draw()
end

return TooltipSystemUISystem

