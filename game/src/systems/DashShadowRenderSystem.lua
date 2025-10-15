local System = require("src.core.System")
local DepthSorting = require("src.utils.depthSorting")

---@class DashShadowRenderSystem : System
---System that renders dash shadows with reduced opacity
local DashShadowRenderSystem = System:extend("DashShadowRenderSystem", {"Position", "DashShadow"})

---Draw all dash shadows with motion blur effect
function DashShadowRenderSystem:draw()
    -- Use depth sorting for proper layering
    local sortedEntities = DepthSorting.sortEntities(self.entities)

    for _, entity in ipairs(sortedEntities) do
        local position = entity:getComponent("Position")
        local dashShadow = entity:getComponent("DashShadow")

        if position and dashShadow and dashShadow.spriteSheet and dashShadow.frameIndex then
            local iffy = require("lib.iffy")
            local x = position.x
            local y = position.y

            -- Check if the sprite sheet and frame exist in Iffy
            if iffy.spritesheets[dashShadow.spriteSheet] and
               iffy.spritesheets[dashShadow.spriteSheet][dashShadow.frameIndex] then

                -- Get the actual sprite frame dimensions from Iffy tileset
                local frameWidth = 24
                if iffy.tilesets[dashShadow.spriteSheet] then
                    frameWidth = iffy.tilesets[dashShadow.spriteSheet][1]
                end

                -- Adjust position for horizontal flipping to keep sprite centered
                local drawX = x
                if dashShadow.scaleX < 0 then
                    drawX = x + frameWidth
                end

                -- Motion blur effect: draw multiple slightly offset copies
                local baseOpacity = dashShadow:getOpacity()
                local blurSteps = 4  -- Number of blur layers
                local blurOffset = 6  -- Pixels to offset each blur layer

                -- Get dash direction for motion blur direction from stored dash direction
                local blurDirX = dashShadow.dashDirX or 0
                local blurDirY = dashShadow.dashDirY or 0

                -- Draw motion blur layers (further back = more transparent)
                for i = blurSteps, 1, -1 do
                    local blurAlpha = baseOpacity * (1 * i / blurSteps)  -- Fade each layer
                    love.graphics.setColor(1, 1, 1, blurAlpha)

                    local offsetX = blurDirX * blurOffset * i
                    local offsetY = blurDirY * blurOffset * i

                    love.graphics.draw(
                        iffy.images[dashShadow.spriteSheet],
                        iffy.spritesheets[dashShadow.spriteSheet][dashShadow.frameIndex],
                        drawX + offsetX,
                        y + offsetY,
                        0, -- rotation
                        dashShadow.scaleX,
                        dashShadow.scaleY
                    )
                end

                -- Draw the main shadow sprite (most opaque)
                love.graphics.setColor(1, 1, 1, baseOpacity * 0.8)
                love.graphics.draw(
                    iffy.images[dashShadow.spriteSheet],
                    iffy.spritesheets[dashShadow.spriteSheet][dashShadow.frameIndex],
                    drawX,
                    y,
                    0, -- rotation
                    dashShadow.scaleX,
                    dashShadow.scaleY
                )
            end

            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
        end
    end
end

return DashShadowRenderSystem
