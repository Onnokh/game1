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
---@field facingMouse boolean Whether the sprite should face the mouse
---@field outline table|nil Outline configuration {enabled, color, thickness}
local SpriteRenderer = {}
SpriteRenderer.__index = SpriteRenderer

---Create a new SpriteRenderer component
---@param sprite string|nil The sprite name or path
---@param width number Width of the sprite
---@param height number Height of the sprite
---@return Component|SpriteRenderer
function SpriteRenderer.new(sprite, width, height)
    local Component = require("src.core.Component")
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
    self.facingMouse = false
    self.spriteIndex = nil
    self.outline = nil -- Outline configuration {enabled, color, thickness}

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

---Enable outline effect
---@param color table RGBA color table {r, g, b, a} (a is optional, defaults to 0.75)
function SpriteRenderer:setOutline(color)
    self.outline = {
        enabled = true,
        color = color or {r = 1, g = 1, b = 1, a = 0.75}
    }
    -- Ensure alpha has a default value
    if self.outline.color.a == nil then
        self.outline.color.a = 0.75
    end
end

---Disable outline effect
function SpriteRenderer:clearOutline()
    self.outline = nil
end

---Serialize the SpriteRenderer component for saving
---@return table Serialized sprite renderer data
function SpriteRenderer:serialize()
    return {
        sprite = self.sprite,
        width = self.width,
        height = self.height,
        color = {r = self.color.r, g = self.color.g, b = self.color.b, a = self.color.a},
        visible = self.visible,
        scaleX = self.scaleX,
        scaleY = self.scaleY,
        rotation = self.rotation,
        offsetX = self.offsetX,
        offsetY = self.offsetY,
        facingMouse = self.facingMouse,
        spriteIndex = self.spriteIndex,
        outline = self.outline and {
            enabled = self.outline.enabled,
            color = {
                r = self.outline.color.r,
                g = self.outline.color.g,
                b = self.outline.color.b,
                a = self.outline.color.a
            }
        } or nil
    }
end

---Deserialize SpriteRenderer component from saved data
---@param data table Serialized sprite renderer data
---@return SpriteRenderer Recreated SpriteRenderer component
function SpriteRenderer.deserialize(data)
    local renderer = SpriteRenderer.new(data.sprite, data.width, data.height)
    renderer.color = data.color or {r = 1, g = 1, b = 1, a = 1}
    renderer.visible = data.visible ~= false
    renderer.scaleX = data.scaleX or 1
    renderer.scaleY = data.scaleY or 1
    renderer.rotation = data.rotation or 0
    renderer.offsetX = data.offsetX or 0
    renderer.offsetY = data.offsetY or 0
    renderer.facingMouse = data.facingMouse or false
    renderer.spriteIndex = data.spriteIndex
    renderer.outline = data.outline
    return renderer
end

return SpriteRenderer
