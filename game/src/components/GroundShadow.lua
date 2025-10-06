local Component = require("src.core.Component")

---@class GroundShadow : Component
---@field enabled boolean Whether to render the ground shadow
---@field alpha number Shadow opacity (0-1)
---@field widthFactor number Multiplier against sprite width for shadow ellipse width
---@field heightFactor number Multiplier against sprite height for shadow ellipse height
---@field offsetY number Extra vertical offset in pixels from the sprite bottom
---@field pixelSize number Size of pixelation blocks (higher = more blocky)
local GroundShadow = {}
GroundShadow.__index = GroundShadow

---Create a new GroundShadow component
---@param params table|nil Optional parameters { alpha, widthFactor, heightFactor, offsetY, pixelSize }
---@return Component|GroundShadow
function GroundShadow.new(params)
	local self = setmetatable(Component.new("GroundShadow"), GroundShadow)

	params = params or {}
	self.enabled = true
	self.alpha = params.alpha or 0.35
	self.widthFactor = params.widthFactor or 0.85
	self.heightFactor = params.heightFactor or 0.22
	self.offsetY = params.offsetY or 0
	self.pixelSize = params.pixelSize or 2.0 -- Default pixelation size

	return self
end

return GroundShadow


