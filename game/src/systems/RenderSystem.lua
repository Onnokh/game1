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
    -- Draw oxygen safe zone at tile level (behind entities)
    self:drawOxygenSafeZone()

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

            if animator and animator.sheet then
                local iffy = require("lib.iffy")
                local current = animator:getCurrentFrame()

                if iffy.spritesheets[animator.sheet] and iffy.spritesheets[animator.sheet][current] then
                    -- Get the actual sprite frame dimensions from Iffy tileset
                    local frameWidth = 24
                    if iffy.tilesets[animator.sheet] then
                        frameWidth = iffy.tilesets[animator.sheet][1]
                    end

                    -- Adjust position for horizontal flipping to keep sprite centered
                    local drawX = x
                    if spriteRenderer.scaleX < 0 then
                        drawX = x + frameWidth
                    end

                    love.graphics.draw(iffy.images[animator.sheet], iffy.spritesheets[animator.sheet][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
                else
                    drawRectangle(x, y, spriteRenderer, isBullet)
                end
            else
                drawRectangle(x, y, spriteRenderer, isBullet)
            end

            -- Draw with flash shader if entity is flashing
            local flashEffect = entity:getComponent("FlashEffect")
            if flashEffect and flashEffect:isCurrentlyFlashing() then
                self:drawWithFlashShader(entity, x, y, spriteRenderer, animator, flashEffect)
            end

            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
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

    if animator and animator.sheet then
        local iffy = require("lib.iffy")
        local current = animator:getCurrentFrame()

        if iffy.spritesheets[animator.sheet] and iffy.spritesheets[animator.sheet][current] then
            -- Get the actual sprite frame dimensions from Iffy tileset
            local frameWidth = 24
            if iffy.tilesets[animator.sheet] then
                frameWidth = iffy.tilesets[animator.sheet][1]
            end

            -- Adjust position for horizontal flipping to keep sprite centered
            local drawX = x
            if spriteRenderer.scaleX < 0 then
                drawX = x + frameWidth
            end

            love.graphics.draw(iffy.images[animator.sheet], iffy.spritesheets[animator.sheet][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
        else
            drawRectangle(x, y, spriteRenderer, isBullet)
        end
    else
        drawRectangle(x, y, spriteRenderer, isBullet)
    end

    -- Reset shader
    love.graphics.setShader()

    -- Pop transformation matrix
    love.graphics.pop()
end


---Draw oxygen safe zone around the reactor
function RenderSystem:drawOxygenSafeZone()
    -- Get world reference
    local world = nil
    if #self.entities > 0 and self.entities[1]._world then
        world = self.entities[1]._world
    end

    if not world then
        return
    end

    -- Find the reactor entity
    local reactor = nil
    for _, entity in ipairs(world.entities) do
        if entity:hasTag("Reactor") then
            reactor = entity
            break
        end
    end

    if not reactor then
        return
    end

    -- Get reactor position
    local position = reactor:getComponent("Position")
    if not position then
        return
    end

    -- Get the safe zone radius from constants
    local GameConstants = require("src.constants")
    local safeRadius = GameConstants.REACTOR_SAFE_RADIUS

    -- Calculate reactor center (reactor is 64x64)
    local reactorCenterX = position.x + 32
    local reactorCenterY = position.y + 32

    -- Draw the oxygen safe zone as a semi-transparent circle
    -- Use a cyan/light blue color to indicate "breathable air"
    love.graphics.setColor(0.3, 0.7, 1.0, 0.15) -- Light blue with low opacity
    love.graphics.circle("fill", reactorCenterX, reactorCenterY, safeRadius, 64)

    -- Draw a slightly visible border
    love.graphics.setColor(0.4, 0.8, 1.0, 0.4) -- Brighter blue for border
    love.graphics.setLineWidth(2)
    love.graphics.circle("line", reactorCenterX, reactorCenterY, safeRadius, 64)

    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return RenderSystem
