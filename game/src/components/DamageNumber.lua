---@class DamageNumber
---@field text string
---@field owner Entity|nil
---@field offsetX number
---@field offsetY number
---@field localX number
---@field localY number
---@field worldX number
---@field worldY number
---@field vx number
---@field vy number
---@field ttl number
---@field color table
---@field scale number
---@field stickToOwner boolean
local DamageNumber = {}
DamageNumber.__index = DamageNumber

---Create a new DamageNumber component
---@param owner Entity The entity this number should follow
---@param amount number
---@return Component|DamageNumber
function DamageNumber.new(owner, amount)
    local Component = require("src.core.Component")
    local self = setmetatable(Component.new("DamageNumber"), DamageNumber)

    self.text = tostring(math.floor(amount or 0))
    self.owner = owner
    self.offsetX = 0
    self.offsetY = -8
    self.localX = 0
    self.localY = 0
    self.worldX = 0
    self.worldY = 0
    self.vx = 0
    self.vy = -20 -- float upward
    self.ttl = 0.8 -- seconds
    self.scale = 1.0

    -- White color for damage numbers
    self.color = { r = 1.0, g = 1.0, b = 1.0, a = 1.0 }
    self.stickToOwner = true

    return self
end

return DamageNumber


