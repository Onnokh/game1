local System = require("src.core.System")
local DepthSorting = require("src.utils.depthSorting")

---@class RenderSystem : System
local RenderSystem = System:extend("RenderSystem", {"Position", "SpriteRenderer"})

---Draw a rectangle with rotation and scale
---@param x number X position
---@param y number Y position
---@param spriteRenderer SpriteRenderer The sprite renderer component
---@param isBullet boolean|nil Whether this is a bullet (to add glow effect)
local function drawRectangle(x, y, spriteRenderer, isBullet)
    love.graphics.push()
    love.graphics.translate(x + spriteRenderer.width / 2, y + spriteRenderer.height / 2)
    love.graphics.rotate(spriteRenderer.rotation)
    love.graphics.scale(spriteRenderer.scaleX, spriteRenderer.scaleY)

    -- Draw main body
    love.graphics.rectangle("fill", -spriteRenderer.width / 2, -spriteRenderer.height / 2, spriteRenderer.width, spriteRenderer.height)

    -- Add glowing yellow tail for bullets
    if isBullet then
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.rectangle("fill", -spriteRenderer.width / 2, -spriteRenderer.height / 2, 1.5, spriteRenderer.height)
        -- Restore the original color
        love.graphics.setColor(spriteRenderer.color.r, spriteRenderer.color.g, spriteRenderer.color.b, spriteRenderer.color.a)
    end

    love.graphics.pop()
end

---Draw all entities with Position and SpriteRenderer components
function RenderSystem:draw()


    -- Use the depth sorting utility for proper 2D layering
    local sortedEntities = DepthSorting.sortEntities(self.entities)

    for _, entity in ipairs(sortedEntities) do
        local position = entity:getComponent("Position")
        local spriteRenderer = entity:getComponent("SpriteRenderer")

        if position and spriteRenderer and spriteRenderer.visible then
            -- Set color
            love.graphics.setColor(spriteRenderer.color.r, spriteRenderer.color.g, spriteRenderer.color.b, spriteRenderer.color.a)

            -- Calculate final position with offset
            local x = position.x + spriteRenderer.offsetX
            local y = position.y + spriteRenderer.offsetY

            -- If Animator exists and sheet is loaded with Iffy, draw that frame
            local animator = entity:getComponent("Animator")
            local isBullet = entity:hasTag("Bullet")

            -- Apply outline shader if configured
            if spriteRenderer.outline and spriteRenderer.outline.enabled then
                self:drawWithOutlineShader(entity, x, y, spriteRenderer, animator)
            -- Apply glow shader if entity is a bullet
            elseif isBullet then
                self:drawWithGlowShader(entity, x, y, spriteRenderer, animator)
                -- Skip normal drawing since shader handles it
                goto skip_drawing
            -- Apply foliage sway shader if entity has FoliageSway tag
            elseif entity:hasTag("FoliageSway") then
                self:drawWithFoliageSwayShader(entity, x, y, spriteRenderer, animator)
                -- Skip normal drawing since shader handles it
                goto skip_drawing
            else
                -- Normal drawing without outline
                local hasDrawnSomething = false

                -- Draw all animation layers
                if animator and animator.layers then
                    local iffy = require("lib.iffy")
                    local current = animator:getCurrentFrame()

                    for _, sheetName in ipairs(animator.layers) do
                        if sheetName and sheetName ~= "" and iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][current] then
                            -- Get the actual sprite frame dimensions from Iffy tileset
                            local frameWidth = 24
                            if iffy.tilesets[sheetName] then
                                frameWidth = iffy.tilesets[sheetName][1]
                            end

                            -- Adjust position for horizontal flipping to keep sprite centered
                            local drawX = x
                            if spriteRenderer.scaleX < 0 then
                                drawX = x + frameWidth
                            end

                            love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
                            hasDrawnSomething = true
                        end
                    end
                end


                -- Then, draw static sprite overlay if it exists (can be on top of animation)
                if spriteRenderer.sprite then
                    local iffy = require("lib.iffy")
                    local spriteSheet = spriteRenderer.sprite

                    if iffy.spritesheets[spriteSheet] and iffy.spritesheets[spriteSheet][1] then
                        -- Get the actual sprite frame dimensions from Iffy tileset
                        local frameWidth = spriteRenderer.width
                        local frameHeight = spriteRenderer.height
                        if iffy.tilesets[spriteSheet] then
                            frameWidth = iffy.tilesets[spriteSheet][1]
                            frameHeight = iffy.tilesets[spriteSheet][2]
                        end

                        -- Calculate origin offset for center rotation
                        local ox = frameWidth / 2
                        local oy = frameHeight / 2

                        -- Draw with center as origin for proper rotation
                        local drawX = x + ox
                        local drawY = y + oy

                        love.graphics.draw(iffy.images[spriteSheet], iffy.spritesheets[spriteSheet][1], drawX, drawY, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY, ox, oy)
                        hasDrawnSomething = true
                    end
                end

                -- Fallback: draw rectangle if nothing was drawn
                if not hasDrawnSomething then
                    drawRectangle(x, y, spriteRenderer, isBullet)
                end

            end

            -- Draw with flash shader if entity is flashing (but not if it has foliage sway)
            if not entity:hasTag("FoliageSway") then
                local flashEffect = entity:getComponent("FlashEffect")
                if flashEffect and flashEffect:isCurrentlyFlashing() then
                    self:drawWithFlashShader(entity, x, y, spriteRenderer, animator, flashEffect)
                end
            end

            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
            ::skip_drawing::
        end
    end
end

---Draw entity with outline shader
---@param entity Entity The entity to draw
---@param x number X position
---@param y number Y position
---@param spriteRenderer SpriteRenderer The sprite renderer component
---@param animator Animator|nil The animator component
function RenderSystem:drawWithOutlineShader(entity, x, y, spriteRenderer, animator)
    local ShaderManager = require("src.core.managers.ShaderManager")
    local outlineShader = ShaderManager.getShader("outline")

    if not outlineShader then
        return
    end

    -- Get outline configuration
    local outline = spriteRenderer.outline

    -- Validate outline configuration
    if not outline or not outline.color then
        return
    end

    -- Set the outline shader
    love.graphics.setShader(outlineShader)

    -- Set shader uniforms with safe defaults
    local color = outline.color or {r = 1, g = 1, b = 1}
    outlineShader:send("OutlineColor", {color.r or 1, color.g or 1, color.b or 1})
    outlineShader:send("OutlineAlpha", color.a or 0.75)

    -- Get the actual texture dimensions from the image being drawn
    local textureWidth, textureHeight = spriteRenderer.width, spriteRenderer.height

    if animator and animator.layers and #animator.layers > 0 then
        local iffy = require("lib.iffy")
        local current = animator:getCurrentFrame()

        for _, sheetName in ipairs(animator.layers) do
            if sheetName and sheetName ~= "" and iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][current] then
                -- Get the actual image dimensions
                local image = iffy.images[sheetName]
                if image then
                    textureWidth, textureHeight = image:getDimensions()
                    break -- Use dimensions from first valid layer
                end
            end
        end
    elseif spriteRenderer.sprite then
        local iffy = require("lib.iffy")
        local spriteSheet = spriteRenderer.sprite

        if iffy.images[spriteSheet] then
            -- Get the actual image dimensions
            textureWidth, textureHeight = iffy.images[spriteSheet]:getDimensions()
        end
    end

    outlineShader:send("TextureSize", {textureWidth, textureHeight})

    -- Draw the sprite (shader will handle the outline effect)
    local isBullet = entity:hasTag("Bullet")
    local hasDrawnSomething = false

    -- Draw all animation layers
    if animator and animator.layers then
        local iffy = require("lib.iffy")
        local current = animator:getCurrentFrame()

        for _, sheetName in ipairs(animator.layers) do
            if sheetName and sheetName ~= "" and iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][current] then
                if entity:hasTag("Tree") then
                    print("[Foliage] anim draw id=", entity.id)
                end
                -- Get the actual sprite frame dimensions from Iffy tileset
                local frameWidth = 24
                if iffy.tilesets[sheetName] then
                    frameWidth = iffy.tilesets[sheetName][1]
                end

                -- Adjust position for horizontal flipping to keep sprite centered
                local drawX = x
                if spriteRenderer.scaleX < 0 then
                    drawX = x + frameWidth
                end

                love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
                hasDrawnSomething = true
            end
        end
    end

    -- Then, draw static sprite overlay if it exists
    if spriteRenderer.sprite then
        local iffy = require("lib.iffy")
        local spriteSheet = spriteRenderer.sprite

        if iffy.spritesheets[spriteSheet] and iffy.spritesheets[spriteSheet][1] then
            if entity:hasTag("Tree") then
                print("[Foliage] sprite draw id=", entity.id)
            end
            -- Get the actual sprite frame dimensions from Iffy tileset
            local frameWidth = spriteRenderer.width
            local frameHeight = spriteRenderer.height
            if iffy.tilesets[spriteSheet] then
                frameWidth = iffy.tilesets[spriteSheet][1]
                frameHeight = iffy.tilesets[spriteSheet][2]
            end

            -- Calculate origin offset for center rotation
            local ox = frameWidth / 2
            local oy = frameHeight / 2

            -- Draw with center as origin for proper rotation
            local drawX = x + ox
            local drawY = y + oy

            love.graphics.draw(iffy.images[spriteSheet], iffy.spritesheets[spriteSheet][1], drawX, drawY, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY, ox, oy)
            hasDrawnSomething = true
        end
    end

    -- Fallback: draw rectangle if nothing was drawn
    if not hasDrawnSomething then
        drawRectangle(x, y, spriteRenderer, isBullet)
    end

    -- Reset shader
    love.graphics.setShader()
end

---Draw entity with flash shader
---@param entity Entity The entity to draw
---@param x number X position
---@param y number Y position
---@param spriteRenderer SpriteRenderer The sprite renderer component
---@param animator Animator|nil The animator component
---@param flashEffect FlashEffect The flash effect component
function RenderSystem:drawWithFlashShader(entity, x, y, spriteRenderer, animator, flashEffect)
    local shader = flashEffect:getShader()
    if not shader then
        -- Fallback to normal drawing if shader not available
        return
    end

    -- Set the flash shader
    love.graphics.setShader(shader)

    -- Set shader uniforms
    shader:send("FlashIntensity", flashEffect:getIntensity())
    shader:send("Time", love.timer.getTime())

    -- Apply size pulse scaling from center
    local sizePulse = flashEffect:getSizePulse()
    local scaleMultiplier = 1.0 + sizePulse

    -- Push transformation matrix for scaling from center
    love.graphics.push()

    -- Translate to center of sprite, scale, then translate back
    local centerX = x + (spriteRenderer.width * 0.5)
    local centerY = y + (spriteRenderer.height * 0.5)

    love.graphics.translate(centerX, centerY)
    love.graphics.scale(scaleMultiplier, scaleMultiplier)
    love.graphics.translate(-centerX, -centerY)

    -- Draw the sprite normally (shader will handle the flash effect)
    local isBullet = entity:hasTag("Bullet")
    local hasDrawnSomething = false

    -- Draw all animation layers
    if animator and animator.layers then
        local iffy = require("lib.iffy")
        local current = animator:getCurrentFrame()

        for _, sheetName in ipairs(animator.layers) do
            if sheetName and sheetName ~= "" and iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][current] then
                -- Get the actual sprite frame dimensions from Iffy tileset
                local frameWidth = 24
                if iffy.tilesets[sheetName] then
                    frameWidth = iffy.tilesets[sheetName][1]
                end

                -- Adjust position for horizontal flipping to keep sprite centered
                local drawX = x
                if spriteRenderer.scaleX < 0 then
                    drawX = x + frameWidth
                end

                love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
                hasDrawnSomething = true
            end
        end
    end

    -- Then, draw static sprite overlay if it exists
    if spriteRenderer.sprite then
        local iffy = require("lib.iffy")
        local spriteSheet = spriteRenderer.sprite

        if iffy.spritesheets[spriteSheet] and iffy.spritesheets[spriteSheet][1] then
            -- Get the actual sprite frame dimensions from Iffy tileset
            local frameWidth = spriteRenderer.width
            local frameHeight = spriteRenderer.height
            if iffy.tilesets[spriteSheet] then
                frameWidth = iffy.tilesets[spriteSheet][1]
                frameHeight = iffy.tilesets[spriteSheet][2]
            end

            -- Calculate origin offset for center rotation
            local ox = frameWidth / 2
            local oy = frameHeight / 2

            -- Draw with center as origin for proper rotation
            local drawX = x + ox
            local drawY = y + oy

            love.graphics.draw(iffy.images[spriteSheet], iffy.spritesheets[spriteSheet][1], drawX, drawY, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY, ox, oy)
            hasDrawnSomething = true
        end
    end

    -- Fallback: draw rectangle if nothing was drawn
    if not hasDrawnSomething then
        drawRectangle(x, y, spriteRenderer, isBullet)
    end

    -- Reset shader
    love.graphics.setShader()

    -- Pop transformation matrix
    love.graphics.pop()
end

---Draw entity with foliage sway shader
---@param entity Entity The entity to draw
---@param x number X position
---@param y number Y position
---@param spriteRenderer SpriteRenderer The sprite renderer component
---@param animator Animator|nil The animator component
function RenderSystem:drawWithFoliageSwayShader(entity, x, y, spriteRenderer, animator)
    local ShaderManager = require("src.core.managers.ShaderManager")
    local foliageSwayShader = ShaderManager.getShader("foliage_sway")
    local noiseTexture = ShaderManager.getNoiseTexture()

    if not foliageSwayShader or not noiseTexture then
        -- Fallback to normal drawing if shader not available
        return
    end

    -- Set the foliage sway shader
    love.graphics.setShader(foliageSwayShader)

    -- Set shader uniforms
    foliageSwayShader:send("Time", love.timer.getTime())
    foliageSwayShader:send("NoiseTexture", noiseTexture)
    foliageSwayShader:send("WorldPosition", {x, y})

    -- Get the actual texture dimensions from the image being drawn
    local textureWidth, textureHeight = spriteRenderer.width, spriteRenderer.height

    if animator and animator.layers and #animator.layers > 0 then
        local iffy = require("lib.iffy")
        local current = animator:getCurrentFrame()

        for _, sheetName in ipairs(animator.layers) do
            if sheetName and sheetName ~= "" and iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][current] then
                -- Get the actual image dimensions
                local image = iffy.images[sheetName]
                if image then
                    textureWidth, textureHeight = image:getDimensions()
                    break -- Use dimensions from first valid layer
                end
            end
        end
    elseif spriteRenderer.sprite then
        local iffy = require("lib.iffy")
        local spriteSheet = spriteRenderer.sprite

        if iffy.images[spriteSheet] then
            -- Get the actual image dimensions
            textureWidth, textureHeight = iffy.images[spriteSheet]:getDimensions()
        end
    end

    foliageSwayShader:send("TextureSize", {textureWidth, textureHeight})

    -- Draw the sprite (shader will handle the sway effect)
    local isBullet = entity:hasTag("Bullet")
    local hasDrawnSomething = false

    -- Draw animation if it exists, otherwise draw static sprite (not both!)
    if animator and animator.layers then
        local iffy = require("lib.iffy")
        local current = animator:getCurrentFrame()

        for _, sheetName in ipairs(animator.layers) do
            if sheetName and sheetName ~= "" and iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][current] then
            -- Get the actual sprite frame dimensions from Iffy tileset
            local frameWidth = 24
            if iffy.tilesets[sheetName] then
                frameWidth = iffy.tilesets[sheetName][1]
            end

            -- Adjust position for horizontal flipping to keep sprite centered
            local drawX = x
            if spriteRenderer.scaleX < 0 then
                drawX = x + frameWidth
            end

            love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
            hasDrawnSomething = true
            end
        end
    elseif spriteRenderer.sprite then
        local iffy = require("lib.iffy")
        local spriteSheet = spriteRenderer.sprite

        if iffy.spritesheets[spriteSheet] and iffy.spritesheets[spriteSheet][1] then
            -- Get the actual sprite frame dimensions from Iffy tileset
            local frameWidth = spriteRenderer.width
            local frameHeight = spriteRenderer.height
            if iffy.tilesets[spriteSheet] then
                frameWidth = iffy.tilesets[spriteSheet][1]
                frameHeight = iffy.tilesets[spriteSheet][2]
            end

            -- Calculate origin offset for center rotation
            local ox = frameWidth / 2
            local oy = frameHeight / 2

            -- Draw with center as origin for proper rotation
            local drawX = x + ox
            local drawY = y + oy

            love.graphics.draw(iffy.images[spriteSheet], iffy.spritesheets[spriteSheet][1], drawX, drawY, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY, ox, oy)
            hasDrawnSomething = true
        end
    end

    -- Fallback: draw rectangle if nothing was drawn
    if not hasDrawnSomething then
        drawRectangle(x, y, spriteRenderer, isBullet)
    end


    -- Reset shader and color
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
end

---Draw entity with glow shader (for bullets)
---@param entity Entity The entity to draw
---@param x number X position
---@param y number Y position
---@param spriteRenderer SpriteRenderer The sprite renderer component
---@param animator Animator|nil The animator component
function RenderSystem:drawWithGlowShader(entity, x, y, spriteRenderer, animator)
    local ShaderManager = require("src.core.managers.ShaderManager")
    local glowShader = ShaderManager.getShader("glow")

    if not glowShader then
        -- Fallback to normal drawing if shader not available
        return
    end

    -- Pulsing effect based on time
    local time = love.timer.getTime()
    local pulse = 1.0 + math.sin(time * 4.0) * 0.2

    -- Get glow color from sprite renderer or use default bright white/orange
    local glowColor = {1.0, 0.85, 0.6}
    if spriteRenderer.glowColor then
        glowColor = {spriteRenderer.glowColor.r, spriteRenderer.glowColor.g, spriteRenderer.glowColor.b}
    end

    -- Bullets typically use static sprites, not animations
    if spriteRenderer.sprite then
        local iffy = require("lib.iffy")
        local spriteSheet = spriteRenderer.sprite

        if iffy.spritesheets[spriteSheet] and iffy.spritesheets[spriteSheet][1] then
            -- Get the actual sprite frame dimensions from Iffy tileset
            local frameWidth = spriteRenderer.width
            local frameHeight = spriteRenderer.height
            if iffy.tilesets[spriteSheet] then
                frameWidth = iffy.tilesets[spriteSheet][1]
                frameHeight = iffy.tilesets[spriteSheet][2]
            end

            -- Calculate origin offset for center rotation
            local ox = frameWidth / 2
            local oy = frameHeight / 2

            -- Draw with center as origin for proper rotation
            local drawX = x + ox
            local drawY = y + oy

            local image = iffy.images[spriteSheet]
            local quad = iffy.spritesheets[spriteSheet][1]

            -- Draw outer glow layers (multiple passes with offset and transparency)
            love.graphics.setShader()
            for i = 3, 1, -1 do
                local offset = i * 1.5 * pulse
                local alpha = (0.3 / i) * pulse
                love.graphics.setColor(glowColor[1], glowColor[2], glowColor[3], alpha)

                -- Draw glow in 8 directions (cardinal + diagonal)
                for angle = 0, 7 do
                    local rad = (angle * math.pi) / 4
                    local offsetX = math.cos(rad) * offset
                    local offsetY = math.sin(rad) * offset
                    love.graphics.draw(image, quad, drawX + offsetX, drawY + offsetY, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY, ox, oy)
                end
            end

            -- Draw the core bullet with shader for extra brightness
            love.graphics.setShader(glowShader)
            glowShader:send("Time", time)
            love.graphics.setColor(spriteRenderer.color.r, spriteRenderer.color.g, spriteRenderer.color.b, spriteRenderer.color.a)
            love.graphics.draw(image, quad, drawX, drawY, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY, ox, oy)
        end
    end

    -- Reset shader and color
    love.graphics.setShader()
    love.graphics.setColor(1, 1, 1, 1)
end

return RenderSystem


