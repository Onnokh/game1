local System = require("src.core.System")
local FontManager = require("src.utils.FontManager")

---@class DamageNumberSystem : System
local DamageNumberSystem = System:extend("DamageNumberSystem", {"DamageNumber"})

function DamageNumberSystem:update(dt)
    for i = #self.entities, 1, -1 do
        local e = self.entities[i]
        local dn = e:getComponent("DamageNumber")
        if dn then
            -- Follow owner if available
            if dn.owner and dn.stickToOwner and dn.owner.active ~= false then
                local pos = dn.owner:getComponent("Position")
                local sr = dn.owner:getComponent("SpriteRenderer")
                if pos then
                    local w = (sr and sr.width) or 24
                    dn.worldX = pos.x + w * 0.5 + dn.offsetX + dn.localX
                    dn.worldY = pos.y + dn.offsetY + dn.localY
                end
            else
                -- If no owner, just move by velocity
                dn.worldX = (dn.worldX or 0) + dn.vx * dt
                dn.worldY = (dn.worldY or 0) + dn.vy * dt
            end

            -- Always float upwards a bit in local offset
            dn.localY = dn.localY + dn.vy * dt

            dn.ttl = dn.ttl - dt
            -- Fade out near the end
            if dn.ttl < 0.3 then
                dn.color.a = math.max(0, dn.ttl / 0.3)
            end
            if dn.ttl <= 0 then
                e.active = false
                table.remove(self.entities, i)
            end
        end
    end
end

function DamageNumberSystem:draw()
    for _, e in ipairs(self.entities) do
        local dn = e:getComponent("DamageNumber")
        if dn then
            -- Draw in world space so it matches in-world health bars
            local r, g, b, a = love.graphics.getColor()
            love.graphics.setColor(dn.color.r, dn.color.g, dn.color.b, dn.color.a)
            local font = FontManager.getDetermination(8)
            local prevFont = love.graphics.getFont()
            if font then love.graphics.setFont(font) end
            local textWidth = (font and font:getWidth(dn.text) or 0) * dn.scale
            local x = math.floor(((dn.worldX or 0) - textWidth * 0.5) + 0.5)
            local y = math.floor((dn.worldY or 0) + 0.5)
            love.graphics.print(dn.text, x, y, 0, dn.scale, dn.scale)
            if prevFont then love.graphics.setFont(prevFont) end
            love.graphics.setColor(r, g, b, a)
        end
    end
end

return DamageNumberSystem


