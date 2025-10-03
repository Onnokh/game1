---@class CastableShadow
---@field shape string Shape type: "rectangle" or "polygon"
---@field width number Rectangle width (when shape == "rectangle")
---@field height number Rectangle height (when shape == "rectangle")
---@field points number[]|nil Polygon points (when shape == "polygon")
---@field offsetX number Local X offset from entity top-left
---@field offsetY number Local Y offset from entity top-left
---@field body any|nil Shädows Body instance
---@field shapeRefs any[]|nil References to created shadow shapes
---@field enabled boolean Whether shadow is active
local CastableShadow = {}
CastableShadow.__index = CastableShadow

---Create a new CastableShadow component
---@param opts table
---@return Component|CastableShadow
function CastableShadow.new(opts)
	local Component = require("src.core.Component")
	local self = setmetatable(Component.new("CastableShadow"), CastableShadow)

	opts = opts or {}
	self.shape = opts.shape or "rectangle"
	self.width = opts.width or 16
	self.height = opts.height or 16
    self.points = opts.points or nil
	self.offsetX = opts.offsetX or 0
	self.offsetY = opts.offsetY or 0
	self.body = nil
	self.shapeRefs = nil
	self.enabled = opts.enabled ~= false

	return self
end

function CastableShadow:isCreated()
	return self.body ~= nil
end

return CastableShadow


