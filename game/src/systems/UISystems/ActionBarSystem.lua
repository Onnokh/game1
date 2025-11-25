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
	return self
end

function ActionBarSystem:draw()
    if not self.ecsWorld then return end

    -- Draw the action bar
    ActionBarHUD.draw(self.ecsWorld)
end

return ActionBarSystem

