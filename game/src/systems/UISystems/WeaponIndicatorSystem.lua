local System = require("src.core.System")

---@class WeaponIndicatorSystem : System
---@field ecsWorld World
local WeaponIndicatorSystem = System:extend("WeaponIndicatorSystem", {})

function WeaponIndicatorSystem.new(ecsWorld)
	---@class WeaponIndicatorSystem
	local self = System.new()
	setmetatable(self, WeaponIndicatorSystem)
	self.ecsWorld = ecsWorld
	self.isWorldSpace = false -- This UI system draws in screen space

	return self
end

---Draw the weapon indicator in screen space
function WeaponIndicatorSystem:draw()
	local WeaponIndicator = require("src.ui.WeaponIndicator")
	WeaponIndicator.draw(self.ecsWorld)
end

return WeaponIndicatorSystem

