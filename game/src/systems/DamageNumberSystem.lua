local System = require("src.core.System")
local FontManager = require("src.utils.FontManager")
local ShaderManager = require("src.utils.ShaderManager")
local gameState = require("src.core.GameState")

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
                    local w, h = (sr and sr.width) or 24, (sr and sr.height) or 24
                    dn.worldX = pos.x + w * 0.5 + dn.offsetX + dn.localX
                    dn.worldY = pos.y - 4 + dn.offsetY + dn.localY
                end
            end

            dn.ttl = dn.ttl - dt
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
            -- Draw in screen space so text is not scaled by camera
            local r, g, b, a = love.graphics.getColor()
            love.graphics.setColor(dn.color.r, dn.color.g, dn.color.b, dn.color.a)

            -- Convert world position to screen coordinates
            local screenX, screenY = dn.worldX or 0, dn.worldY or 0
            if gameState and gameState.camera and gameState.camera.toScreen then
                screenX, screenY = gameState.camera:toScreen(screenX, screenY)
            end

            -- Choose an appropriate font size so it appears crisp at current zoom
            local cameraScale = (gameState and gameState.camera and gameState.camera.scale) or 1
            local basePx = 14
            local targetPx = math.max(8, math.floor(basePx * cameraScale + 0.5))
            local font = FontManager.getDetermination(targetPx)

            -- Draw at UI origin so it is not affected by camera transforms
            local prevFont = love.graphics.getFont()
            love.graphics.push()
            love.graphics.origin()
            if font then love.graphics.setFont(font) end

            -- Center horizontally using the actual font width (no camera scale applied)
            local textWidth = (font and font:getWidth(dn.text) or 0)
            local halfW = textWidth * 0.5
            local x = math.floor(screenX - halfW + 0.5)
            local y = math.floor(screenY + 0.5)
            -- Damage number animation via shader + transforms
            local ttlMax = dn.ttlMax or dn.ttl or 1
            local progress = 1 - math.max(0, math.min(1, (dn.ttl or 0) / ttlMax))
            local moveUp = 20 -- pixels to move up over lifetime
            local startScale, endScale = 1.1, 0.3
            local currentScale = startScale + (endScale - startScale) * progress

            -- Apply movement up and scale in screen space around the text center (x+halfW, y)
            love.graphics.push()
            love.graphics.translate(x + halfW, y - moveUp * progress)
            love.graphics.scale(currentScale, currentScale)

            -- Set shader uniforms (shader doesn't change position, but can be used for effects)
            local shader = ShaderManager.getShader("damage_number")
            if shader then
                love.graphics.setShader(shader)
                ShaderManager.setUniform(shader, "Progress", progress)
                ShaderManager.setUniform(shader, "MoveUp", moveUp)
                ShaderManager.setUniform(shader, "StartScale", startScale)
                ShaderManager.setUniform(shader, "EndScale", endScale)
                ShaderManager.setUniform(shader, "JitterX", dn.jitterX or 0)
                ShaderManager.setUniform(shader, "JitterY", dn.jitterY or 0)
            end

            -- Draw outline first (8-directional) for readability
            local outlineColor = {0, 0, 0, dn.color.a}
            love.graphics.setColor(outlineColor)
            local o = 2 / currentScale -- keep ~2px outline visually after scaling
            love.graphics.print(dn.text, -halfW - o, 0)
            love.graphics.print(dn.text, -halfW + o, 0)
            love.graphics.print(dn.text, -halfW, -o)
            love.graphics.print(dn.text, -halfW,  o)
            love.graphics.print(dn.text, -halfW - o, -o)
            love.graphics.print(dn.text, -halfW + o, -o)
            love.graphics.print(dn.text, -halfW - o,  o)
            love.graphics.print(dn.text, -halfW + o,  o)
            -- Draw main text on top
            love.graphics.setColor(dn.color.r, dn.color.g, dn.color.b, dn.color.a)
            love.graphics.print(dn.text, -halfW, 0)

            -- Reset shader and transforms for UI layer
            if shader then love.graphics.setShader() end
            love.graphics.pop() -- pop scale/translate

            love.graphics.pop()
            if prevFont then love.graphics.setFont(prevFont) end
            love.graphics.setColor(r, g, b, a)
        end
    end
end

return DamageNumberSystem


