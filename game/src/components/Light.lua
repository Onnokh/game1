local Component = require("src.core.Component")

---@class Light : Component
---@field radius number
---@field r number
---@field g number
---@field b number
---@field a number
---@field offsetX number
---@field offsetY number
---@field lightRef any|nil
---@field enabled boolean
local Light = {}
Light.__index = Light

---Create a new Light component
---@param opts table|nil
---@return Component|Light
function Light.new(opts)
    local self = setmetatable(Component.new("Light"), Light)

    opts = opts or {}
    self.radius = opts.radius or 400
    self.r = opts.r or 255
    self.g = opts.g or 255
    self.b = opts.b or 255
    self.a = opts.a or 255
    self.offsetX = opts.offsetX or 0
    self.offsetY = opts.offsetY or 0
    self.lightRef = nil
    self.enabled = opts.enabled ~= false

    return self
end

return Light


