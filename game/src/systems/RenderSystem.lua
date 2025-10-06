local System = require("src.core.System")
local DepthSorting = require("src.utils.depthSorting")

---@class RenderSystem : System
local RenderSystem = System:extend("RenderSystem", {"Position", "SpriteRenderer"})

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
            if animator and animator.sheet then
                local iffy = require("lib.iffy")
                local current = animator:getCurrentFrame()

                -- Debug output
                if not iffy.spritesheets[animator.sheet] then
                    print(string.format("ERROR: Spritesheet '%s' not found!", animator.sheet))
                elseif not iffy.spritesheets[animator.sheet][current] then
                    print(string.format("ERROR: Frame %d not found in spritesheet '%s' (total frames: %d)", current, animator.sheet, #iffy.spritesheets[animator.sheet]))
                end

                if iffy.spritesheets[animator.sheet] and iffy.spritesheets[animator.sheet][current] then
                    -- Use the sprite renderer's color settings
                    love.graphics.setColor(spriteRenderer.color.r, spriteRenderer.color.g, spriteRenderer.color.b, spriteRenderer.color.a)

                    -- Get the actual sprite frame dimensions from Iffy tileset
                    local frameWidth = 24 -- Default to 24x24 for character sprites
                    if iffy.tilesets[animator.sheet] then
                        frameWidth = iffy.tilesets[animator.sheet][1] -- tile width
                    end

                    -- Adjust position for horizontal flipping to keep sprite centered
                    local drawX = x
                    if spriteRenderer.scaleX < 0 then
                        drawX = x + frameWidth
                    end

                    love.graphics.draw(iffy.images[animator.sheet], iffy.spritesheets[animator.sheet][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)

                else
                    -- Adjust rectangle position for horizontal flipping
                    local drawX = x
                    if spriteRenderer.scaleX < 0 then
                        drawX = x + spriteRenderer.width
                    end
                    love.graphics.rectangle("fill", drawX, y, spriteRenderer.width, spriteRenderer.height)
                end
            else
                -- Adjust rectangle position for horizontal flipping
                local drawX = x
                if spriteRenderer.scaleX < 0 then
                    drawX = x + spriteRenderer.width
                end
                love.graphics.rectangle("fill", drawX, y, spriteRenderer.width, spriteRenderer.height)
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
    if animator and animator.sheet then
        local iffy = require("lib.iffy")
        local current = animator:getCurrentFrame()

        if iffy.spritesheets[animator.sheet] and iffy.spritesheets[animator.sheet][current] then
            -- Get the actual sprite frame dimensions from Iffy tileset
            local frameWidth = 24 -- Default to 24x24 for character sprites
            if iffy.tilesets[animator.sheet] then
                frameWidth = iffy.tilesets[animator.sheet][1] -- tile width
            end

            -- Adjust position for horizontal flipping to keep sprite centered
            local drawX = x
            if spriteRenderer.scaleX < 0 then
                drawX = x + frameWidth
            end

            love.graphics.draw(iffy.images[animator.sheet], iffy.spritesheets[animator.sheet][current], drawX, y, spriteRenderer.rotation, spriteRenderer.scaleX, spriteRenderer.scaleY)
        else
            -- Draw rectangle fallback
            local drawX = x
            if spriteRenderer.scaleX < 0 then
                drawX = x + spriteRenderer.width
            end
            love.graphics.rectangle("fill", drawX, y, spriteRenderer.width, spriteRenderer.height)
        end
    else
        -- Draw rectangle fallback
        local drawX = x
        if spriteRenderer.scaleX < 0 then
            drawX = x + spriteRenderer.width
        end
        love.graphics.rectangle("fill", drawX, y, spriteRenderer.width, spriteRenderer.height)
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
