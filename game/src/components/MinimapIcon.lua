---@class MinimapIcon
---@field iconType string Icon type identifier ("shop", "upgrade", "player", etc.)
---@field color table RGB color table {r, g, b} (0-255 range)
---@field iconSize number Size override in pixels
---Component that marks an entity to be displayed on the minimap
local MinimapIcon = {}
MinimapIcon.__index = MinimapIcon

---Create a new MinimapIcon component
---@param iconType string Icon type identifier ("shop", "upgrade", "player", etc.)
---@param color table RGB color table {r, g, b} (0-255 range)
---@param iconSize number|nil Optional size override in pixels (default: 5)
---@return MinimapIcon
function MinimapIcon.new(iconType, color, iconSize)
    ---@class MinimapIcon
    local self = setmetatable({}, MinimapIcon)
    self.iconType = iconType or "default"
    self.color = color or {r = 255, g = 255, b = 255}
    self.iconSize = iconSize or 5
    return self
end

return MinimapIcon

