---@class UIElement
---@field visible boolean
local UIElement = {}
UIElement.__index = UIElement

function UIElement.new()
	local self = setmetatable({}, UIElement)
	self.visible = true
	return self
end

function UIElement:update(dt)
	-- override in subclasses
end

function UIElement:draw()
	-- override in subclasses
end

return UIElement


