-- Import System base class
local System = require("src.core.System")

---@class RenderSystem : System
local RenderSystem = setmetatable({}, {__index = System})
RenderSystem.__index = RenderSystem

---Create a new RenderSystem
---@return RenderSystem|System
function RenderSystem.new()
    local self = System.new({"Position", "SpriteRenderer"})
    setmetatable(self, RenderSystem)
    return self
end

---Draw all entities with Position and SpriteRenderer components
function RenderSystem:draw()
    -- Sort entities by z-level (lower z renders first, higher z renders on top)
    local sortedEntities = {}
    for _, entity in ipairs(self.entities) do
        table.insert(sortedEntities, entity)
    end

    table.sort(sortedEntities, function(a, b)
        local posA = a:getComponent("Position")
        local posB = b:getComponent("Position")
        local zA = posA and posA.z or 0
        local zB = posB and posB.z or 0
        return zA < zB
    end)

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

            -- Reset color
            love.graphics.setColor(1, 1, 1, 1)
        end
    end

end


return RenderSystem
