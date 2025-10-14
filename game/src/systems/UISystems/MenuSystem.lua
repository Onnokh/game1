local System = require("src.core.System")

---@class MenuSystem : System
local MenuSystem = System:extend("MenuSystem", {})

function MenuSystem.new()
	---@class MenuSystem
	local self = System.new({})
	setmetatable(self, MenuSystem)
	self.visible = false
	self.isWorldSpace = false -- This UI system draws in screen space
	self.drawOrder = 1000 -- Draw on top of other UI elements
	return self
end

function MenuSystem:update(dt)
	-- Placeholder: toggle visibility with ESC in future
end

function MenuSystem:draw()
	if not self.visible then return end
	local sw, sh = love.graphics.getDimensions()
	local r,g,b,a = love.graphics.getColor()
	love.graphics.setColor(0, 0, 0, 0.5)
	love.graphics.rectangle("fill", 0, 0, sw, sh)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.print("Menu", sw * 0.5 - 20, sh * 0.5)
	love.graphics.setColor(r,g,b,a)
end

return MenuSystem


