local System = require("src.core.System")
local ActionBarHUD = require("src.ui.ActionBarHUD")

---@class ActionBarSystem : System
---@field ecsWorld World
local ActionBarSystem = System:extend("ActionBarSystem", {})

function ActionBarSystem.new(ecsWorld)
	---@class ActionBarSystem
	local self = System.new()
	setmetatable(self, ActionBarSystem)
	self.ecsWorld = ecsWorld
	self.isWorldSpace = false -- This UI system draws in screen space
	self.drawOrder = 100 -- Draw before tooltips
	return self
end

function ActionBarSystem:update(dt)
    if not self.ecsWorld then return end

    -- Update hover state and tooltips
    ActionBarHUD.update(self.ecsWorld)
end

function ActionBarSystem:draw()
    if not self.ecsWorld then return end

    -- Draw the action bar
    ActionBarHUD.draw(self.ecsWorld)
end

return ActionBarSystem

