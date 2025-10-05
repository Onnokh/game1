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
---@field flicker boolean
---@field flickerSpeed number
---@field flickerRadiusAmplitude number
---@field flickerAlphaAmplitude number
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
    -- Keep nil when not provided so systems can auto-center using SpriteRenderer
    self.offsetX = opts.offsetX
    self.offsetY = opts.offsetY
    self.lightRef = nil
    self.enabled = opts.enabled ~= false
    self.flicker = opts.flicker == true
    self.flickerSpeed = opts.flickerSpeed or 8
    self.flickerRadiusAmplitude = opts.flickerRadiusAmplitude or 10
    self.flickerAlphaAmplitude = opts.flickerAlphaAmplitude or 20

    return self
end

return Light


