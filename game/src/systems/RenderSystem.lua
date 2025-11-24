local System = require("src.core.System")
local DepthSorting = require("src.utils.depthSorting")
local GroundShadowSystem = require("src.systems.GroundShadowSystem")
local ShaderManager = require("src.core.managers.ShaderManager")

---@class RenderSystem : System
local RenderSystem = System:extend("RenderSystem", {"Position", "SpriteRenderer"})

-- Shadow canvas for preventing additive darkening when shadows overlap
local shadowCanvas = nil
local shadowCanvasWidth = 0
local shadowCanvasHeight = 0

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

---Initialize or update shadow canvas to match current screen size
local function ensureShadowCanvas()
    local screenW = love.graphics.getWidth()
    local screenH = love.graphics.getHeight()
    
    -- Create or recreate canvas if size changed
    if not shadowCanvas or shadowCanvasWidth ~= screenW or shadowCanvasHeight ~= screenH then
        if shadowCanvas then
            shadowCanvas:release()
        end
        
        shadowCanvas = love.graphics.newCanvas(screenW, screenH)
        if shadowCanvas then
            shadowCanvas:setFilter("nearest", "nearest")
            shadowCanvasWidth = screenW
            shadowCanvasHeight = screenH
        end
    end
    
    return shadowCanvas
end

---Draw all entities with Position and SpriteRenderer components
function RenderSystem:draw()
    -- Ensure shadow canvas exists
    local canvas = ensureShadowCanvas()
    if not canvas then
        -- Fallback to old behavior if canvas creation fails
        return
    end

    -- Store current canvas and render target
    local previousCanvas = love.graphics.getCanvas()
    
    -- Get camera from world if available for coordinate conversion
    local camera = self.world and self.world.camera
    local cameraScale = camera and camera:getScale() or 1

    -- Render all shadows to shadow canvas first
    love.graphics.setCanvas(canvas)
    love.graphics.push()
    love.graphics.origin() -- Reset to screen space for canvas rendering
    -- Clear to white (represents no darkness/no shadow)
    love.graphics.clear(1, 1, 1, 1)
    
    -- Apply full camera transform to match how sprites are rendered
    -- This ensures shadows align perfectly with sprites and eliminates stuttering
    if camera then
        local scale = camera:getScale()
        local angle = camera:getAngle()
        local camX, camY = camera:getPosition()
        local w2, h2 = camera.w2 or (love.graphics.getWidth() / 2), camera.h2 or (love.graphics.getHeight() / 2)
        local l, t = camera.l or 0, camera.t or 0
        
        love.graphics.scale(scale, scale)
        love.graphics.translate((w2 + l) / scale, (h2 + t) / scale)
        love.graphics.rotate(-angle)
        love.graphics.translate(-camX, -camY)
    else
        -- Fallback: just apply scale if no camera
        love.graphics.scale(cameraScale, cameraScale)
    end
    
    -- Use normal alpha blending - shadows will accumulate additively
    -- We'll prevent excessive darkening in the composite shader
    love.graphics.setBlendMode("alpha")
    
    -- Use the depth sorting utility for proper 2D layering
    local sortedEntities = DepthSorting.sortEntities(self.entities)

    -- First pass: Render all shadows to shadow canvas
    for _, entity in ipairs(sortedEntities) do
        local position = entity:getComponent("Position")
        local spriteRenderer = entity:getComponent("SpriteRenderer")

        if position and spriteRenderer and spriteRenderer.visible then
            -- Calculate final position with offset (in world coordinates)
            -- Since we're applying the full camera transform, we can use world coordinates directly
            local x = position.x + spriteRenderer.offsetX
            local y = position.y + spriteRenderer.offsetY
            
            -- Round to whole pixels for pixel-perfect rendering
            x = math.floor(x + 0.5)
            y = math.floor(y + 0.5)

            -- If Animator exists and sheet is loaded with Iffy, draw that frame
            local animator = entity:getComponent("Animator")
            local isBullet = entity:hasTag("Bullet")

            -- Check if entity has GroundShadow component and render shadow first
            local shadowComp = entity:getComponent("GroundShadow")
            if shadowComp and shadowComp.enabled then
                -- Temporarily set Z-index to BACKGROUND layer so shadow renders behind entities
                local originalZ = position.z
                position:setZ(DepthSorting.LAYERS.BACKGROUND)

                -- Get actual sprite dimensions for shadow calculation
                local actualSpriteWidth, actualSpriteHeight = GroundShadowSystem.getActualSpriteDimensions(entity, spriteRenderer, animator)

                local shadowAlpha = shadowComp.alpha or 0.35

                -- Get shadow shader
                local shadowShader = ShaderManager.getShader("shadow")
                if shadowShader then
                    -- Set shadow color (white for shader - shader will make it black)
                    love.graphics.setColor(1, 1, 1, 1)

                    -- Apply shadow shader
                    love.graphics.setShader(shadowShader)

                    -- Send shader uniforms
                    shadowShader:send("shadowAlpha", shadowAlpha)

                    -- Calculate origin point ONCE for all layers (use override if provided, otherwise will calculate per-layer)
                    local globalOriginX, globalOriginY
                    if shadowComp.originX ~= nil and shadowComp.originY ~= nil then
                        -- Use override origin (relative to sprite position)
                        globalOriginX = x + shadowComp.originX
                        globalOriginY = y + shadowComp.originY
                    end

                    -- Render shadow for animated sprites (at exact same position as sprite)
                    if animator and animator.layers then
                        local iffy = require("lib.iffy")
                        local current = animator:getCurrentFrame()

                        for _, sheetName in ipairs(animator.layers) do
                            if sheetName and sheetName ~= "" and iffy.spritesheets[sheetName] and iffy.spritesheets[sheetName][current] then
                                local frameWidth = iffy.tilesets[sheetName] and iffy.tilesets[sheetName][1] or 24
                                local frameHeight = iffy.tilesets[sheetName] and iffy.tilesets[sheetName][2] or actualSpriteHeight

                                local layerRotation = animator:getLayerRotation(sheetName)
                                local layerOffset = animator:getLayerOffset(sheetName)
                                local layerPivot = animator:getLayerPivot(sheetName)

                                -- Calculate origin point for skew (use global override if provided, otherwise calculate per-layer)
                                local originX, originY
                                if globalOriginX ~= nil and globalOriginY ~= nil then
                                    -- Use global override origin
                                    originX = globalOriginX
                                    originY = globalOriginY
                                else
                                    -- Auto-calculate bottom-center point for this layer
                                    originX = x + (layerOffset.x or 0) + (layerPivot.x or frameWidth / 2)
                                    originY = y + (layerOffset.y or 0) + frameHeight + (shadowComp.offsetY or 0)
                                end

                                -- Apply skew transformation using Love2D's transform system
                                love.graphics.push()

                                -- Translate to origin point, apply skew, translate back
                                love.graphics.translate(originX, originY)

                                -- Create skew transform (shear horizontally)
                                local transform = love.math.newTransform()
                                transform:setTransformation(0, 0, 0, 1, 1, 0, 0, GroundShadowSystem.SKEW_FACTOR, 0)
                                love.graphics.applyTransform(transform)

                                love.graphics.translate(-originX, -originY)

                                -- Draw shadow at exact same position as sprite (with same scale)
                                if layerRotation ~= 0 then
                                    -- Same as normal sprite: draw at x + layerOffset.x, y + layerOffset.y with layerPivot origin
                                    local layerScale = animator:getLayerScale(sheetName)
                                    love.graphics.draw(
                                        iffy.images[sheetName],
                                        iffy.spritesheets[sheetName][current],
                                        x + layerOffset.x,
                                        y + layerOffset.y,
                                        layerRotation,
                                        layerScale.x,
                                        layerScale.y,
                                        layerPivot.x,
                                        layerPivot.y
                                    )
                                else
                                    -- Same as normal sprite: draw at x (or x + frameWidth if flipped), y
                                    local shadowDrawX = x
                                    if spriteRenderer.scaleX < 0 then
                                        shadowDrawX = x + frameWidth
                                    end
                                    love.graphics.draw(
                                        iffy.images[sheetName],
                                        iffy.spritesheets[sheetName][current],
                                        shadowDrawX,
                                        y,
                                        spriteRenderer.rotation,
                                        spriteRenderer.scaleX,
                                        spriteRenderer.scaleY
                                    )
                                end

                                love.graphics.pop()
                            end
                        end
                    end

                    -- Render shadow for static sprite (at exact same position as sprite)
                    if spriteRenderer.sprite then
                        local iffy = require("lib.iffy")
                        local spriteSheet = spriteRenderer.sprite

                        if iffy.spritesheets[spriteSheet] and iffy.spritesheets[spriteSheet][1] then
                            local frameWidth = spriteRenderer.width
                            local frameHeight = spriteRenderer.height
                            if iffy.tilesets[spriteSheet] then
                                frameWidth = iffy.tilesets[spriteSheet][1]
                                frameHeight = iffy.tilesets[spriteSheet][2]
                            end

                            -- Calculate origin point for skew (use override if provided, otherwise bottom-center)
                            local ox = frameWidth / 2
                            local oy = frameHeight / 2
                            local originX, originY
                            if shadowComp.originX ~= nil and shadowComp.originY ~= nil then
                                -- Use override origin (relative to sprite position)
                                -- Note: override origin already includes desired offset, so don't add offsetY again
                                originX = x + shadowComp.originX
                                originY = y + shadowComp.originY
                            else
                                -- Auto-calculate bottom-center point
                                originX = x + ox
                                originY = y + frameHeight + (shadowComp.offsetY or 0)
                            end

                            -- Apply skew transformation using Love2D's transform system
                            love.graphics.push()

                            -- Translate to origin point, apply skew, translate back
                            love.graphics.translate(originX, originY)

                            -- Create skew transform (shear horizontally)
                            local transform = love.math.newTransform()
                            transform:setTransformation(0, 0, 0, 1, 1, 0, 0, GroundShadowSystem.SKEW_FACTOR, 0)
                            love.graphics.applyTransform(transform)

                            love.graphics.translate(-originX, -originY)

                            love.graphics.draw(
                                iffy.images[spriteSheet],
                                iffy.spritesheets[spriteSheet][1],
                                x + ox,
                                y + oy,
                                spriteRenderer.rotation,
                                spriteRenderer.scaleX,
                                spriteRenderer.scaleY,
                                ox,
                                oy
                            )

                            love.graphics.pop()
                        end
                    end

                    -- Reset shader
                    love.graphics.setShader()

                    -- Restore original Z-index after drawing shadow
                    position:setZ(originalZ)
                end
            end
        end
    end

    -- Pop the screen space transform we pushed earlier
    love.graphics.pop()
    
    -- Reset blend mode after rendering shadows to canvas
    love.graphics.setBlendMode("alpha")
    
    -- Restore previous canvas (back to world canvas or screen)
    love.graphics.setCanvas(previousCanvas)

    -- Composite shadow canvas onto scene using a shader that prevents excessive darkening
    -- Draw in screen space to match the canvas coordinate system
    local compositeShader = ShaderManager.getShader("shadow_composite")
    
    -- Store current transform
    love.graphics.push()
    love.graphics.origin() -- Reset to screen space for canvas
    
    if compositeShader then
        -- Use composite shader that clamps darkness to prevent additive darkening
        love.graphics.setShader(compositeShader)
        love.graphics.setBlendMode("multiply", "premultiplied")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvas, 0, 0)
        love.graphics.setShader()
    else
        -- Fallback: simple multiply blend
        love.graphics.setBlendMode("multiply", "premultiplied")
        love.graphics.setColor(1, 1, 1, 1)
        love.graphics.draw(canvas, 0, 0)
    end
    
    love.graphics.setBlendMode("alpha")
    love.graphics.pop()

    -- Second pass: Render all sprites normally
    for _, entity in ipairs(sortedEntities) do
        local position = entity:getComponent("Position")
        local spriteRenderer = entity:getComponent("SpriteRenderer")

        if position and spriteRenderer and spriteRenderer.visible then
            -- Calculate final position with offset, rounded to whole pixels
            local x = math.floor(position.x + spriteRenderer.offsetX + 0.5)
            local y = math.floor(position.y + spriteRenderer.offsetY + 0.5)

            -- If Animator exists and sheet is loaded with Iffy, draw that frame
            local animator = entity:getComponent("Animator")
            local isBullet = entity:hasTag("Bullet")

            -- Set color for normal sprite
            love.graphics.setColor(spriteRenderer.color.r, spriteRenderer.color.g, spriteRenderer.color.b, spriteRenderer.color.a)

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
                            local frameWidth = iffy.tilesets[sheetName] and iffy.tilesets[sheetName][1] or 24

                            -- Check if this layer has a specific rotation
                            local layerRotation = animator:getLayerRotation(sheetName)
                            local layerOffset = animator:getLayerOffset(sheetName)
                            local layerPivot = animator:getLayerPivot(sheetName)

                            if layerRotation ~= 0 then
                                -- Draw with layer-specific rotation and pivot offset
                                local ox = layerPivot.x
                                local oy = layerPivot.y
                                local drawX = x + layerOffset.x
                                local drawY = y + layerOffset.y

                                -- Use layer-specific scale if available, otherwise use sprite scale
                                local layerScale = animator:getLayerScale(sheetName)
                                local scaleX = layerScale.x
                                local scaleY = layerScale.y

                                love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, drawY, layerRotation, scaleX, scaleY, ox, oy)
                            else
                                -- Use normal drawing logic
                                local drawX = x
                                if spriteRenderer.scaleX < 0 then
                                    drawX = x + frameWidth
                                end

                                love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
                            end
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

            -- -- Debug: Draw red square at gun layer offset point for player entities
            -- if entity:hasTag("Player") and animator then
            --     local layerOffset = animator:getLayerOffset("gun")
            --     if layerOffset.x ~= 0 or layerOffset.y ~= 0 then
            --         local debugX = x + layerOffset.x
            --         local debugY = y + layerOffset.y

            --         love.graphics.setColor(1, 0, 0, 1) -- Red color
            --         love.graphics.rectangle("fill", debugX - 2, debugY - 2, 4, 4) -- 4x4 red square
            --         love.graphics.setColor(1, 1, 1, 1) -- Reset color
            --     end
            -- end

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
                local frameWidth = iffy.tilesets[sheetName] and iffy.tilesets[sheetName][1] or 24

                -- Check if this layer has a specific rotation
                local layerRotation = animator:getLayerRotation(sheetName)
                local layerOffset = animator:getLayerOffset(sheetName)
                local layerPivot = animator:getLayerPivot(sheetName)

                if layerRotation ~= 0 then
                    -- Draw with layer-specific rotation and pivot offset
                    local ox = layerPivot.x
                    local oy = layerPivot.y
                    local drawX = x + layerOffset.x
                    local drawY = y + layerOffset.y

                    -- Use layer-specific scale if available, otherwise use sprite scale
                    local layerScale = animator:getLayerScale(sheetName)
                    local scaleX = layerScale.x
                    local scaleY = layerScale.y

                    love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, drawY, layerRotation, scaleX, scaleY, ox, oy)
                else
                    -- Use normal drawing logic
                    local drawX = x
                    if spriteRenderer.scaleX < 0 then
                        drawX = x + frameWidth
                    end

                    love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
                end
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
                local frameWidth = iffy.tilesets[sheetName] and iffy.tilesets[sheetName][1] or 24

                -- Check if this layer has a specific rotation
                local layerRotation = animator:getLayerRotation(sheetName)
                local layerOffset = animator:getLayerOffset(sheetName)
                local layerPivot = animator:getLayerPivot(sheetName)

                if layerRotation ~= 0 then
                    -- Draw with layer-specific rotation and pivot offset
                    local ox = layerPivot.x
                    local oy = layerPivot.y
                    local drawX = x + layerOffset.x
                    local drawY = y + layerOffset.y

                    -- Use layer-specific scale if available, otherwise use sprite scale
                    local layerScale = animator:getLayerScale(sheetName)
                    local scaleX = layerScale.x
                    local scaleY = layerScale.y

                    love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, drawY, layerRotation, scaleX, scaleY, ox, oy)
                else
                    -- Use normal drawing logic
                    local drawX = x
                    if spriteRenderer.scaleX < 0 then
                        drawX = x + frameWidth
                    end

                    love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
                end
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
            local frameWidth = iffy.tilesets[sheetName] and iffy.tilesets[sheetName][1] or 24

            -- Check if this layer has a specific rotation
            local layerRotation = animator:getLayerRotation(sheetName)
            local layerOffset = animator:getLayerOffset(sheetName)
            local layerPivot = animator:getLayerPivot(sheetName)

            if layerRotation ~= 0 then
                -- Draw with layer-specific rotation and pivot offset
                local ox = layerPivot.x
                local oy = layerPivot.y
                local drawX = x + layerOffset.x
                local drawY = y + layerOffset.y

                love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, drawY, layerRotation, spriteRenderer.scaleX, spriteRenderer.scaleY, ox, oy)
            else
                -- Use normal drawing logic
                local drawX = x
                if spriteRenderer.scaleX < 0 then
                    drawX = x + frameWidth
                end

                love.graphics.draw(iffy.images[sheetName], iffy.spritesheets[sheetName][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
            end
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


