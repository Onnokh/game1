---@class SpriteRenderer
---@field sprite string|nil The sprite name or path
---@field width number Width of the sprite
---@field height number Height of the sprite
---@field color table Color table {r, g, b, a}
---@field visible boolean Whether the sprite is visible
---@field scaleX number X scale factor
---@field scaleY number Y scale factor
---@field rotation number Rotation in radians
---@field offsetX number X offset from entity position
---@field offsetY number Y offset from entity position
local SpriteRenderer = {}
SpriteRenderer.__index = SpriteRenderer

---Create a new SpriteRenderer component
---@param sprite string|nil The sprite name or path
---@param width number Width of the sprite
---@param height number Height of the sprite
---@return Component|SpriteRenderer
function SpriteRenderer.new(sprite, width, height)
    local Component = require("src.ecs.Component")
    local self = setmetatable(Component.new("SpriteRenderer"), SpriteRenderer)

    self.sprite = sprite
    self.width = width or 32
    self.height = height or 32
    self.color = {r = 1, g = 1, b = 1, a = 1}
    self.visible = true
    self.scaleX = 1
    self.scaleY = 1
    self.rotation = 0
    self.offsetX = 0
    self.offsetY = 0

    return self
end

---Set the color of the sprite
---@param r number Red component (0-1)
---@param g number Green component (0-1)
---@param b number Blue component (0-1)
---@param a number|nil Alpha component (0-1), defaults to 1
function SpriteRenderer:setColor(r, g, b, a)
    self.color.r = r
    self.color.g = g
    self.color.b = b
    self.color.a = a or 1
end

---Set the scale of the sprite
---@param scaleX number X scale factor
---@param scaleY number|nil Y scale factor, defaults to scaleX
function SpriteRenderer:setScale(scaleX, scaleY)
    self.scaleX = scaleX
    self.scaleY = scaleY or scaleX
end

---Set the rotation of the sprite
---@param rotation number Rotation in radians
function SpriteRenderer:setRotation(rotation)
    self.rotation = rotation
end

---Set the offset of the sprite from entity position
---@param offsetX number X offset
---@param offsetY number Y offset
function SpriteRenderer:setOffset(offsetX, offsetY)
    self.offsetX = offsetX
    self.offsetY = offsetY
end

return SpriteRenderer
