local System = require("src.core.System")
local DepthSorting = require("src.utils.depthSorting")

---@class RenderSystem : System
local RenderSystem = System:extend("RenderSystem", {"Position", "SpriteRenderer"})

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

    -- Draw attack hit areas for entities that are attacking
    self:drawAttackHitAreas()
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

-- Health bars are now handled by UISystems.HealthBarSystem

---Draw attack hit areas for entities that are attacking
function RenderSystem:drawAttackHitAreas()
    local currentTime = love.timer.getTime()

    -- Get all entities with Attack components
    local world = nil
    if #self.entities > 0 and self.entities[1]._world then
        world = self.entities[1]._world
    end

    if not world then
        return
    end

    local entitiesWithAttack = world:getEntitiesWith({"Attack"})

    for _, entity in ipairs(entitiesWithAttack) do
        local attack = entity:getComponent("Attack")
        local position = entity:getComponent("Position")

        if attack and position and attack.enabled then
            -- Check if attack is currently active (within a short time window after attack)
            local timeSinceAttack = currentTime - attack.lastAttackTime
            local attackDuration = 0.2 -- Show hit area for 0.2 seconds after attack

            if timeSinceAttack >= 0 and timeSinceAttack <= attackDuration then
                -- Draw the attack hit area as a rotated rectangle pointing at the mouse
                -- Recompute center from the attacker's current center so it moves with the entity
                local angle = attack.attackAngleRad or 0
                -- Prefer actual physics/pathfinding collider center over sprite center
                local entityCenterX, entityCenterY = position.x, position.y
                local pfc = entity:getComponent("PathfindingCollision")
                local phys = entity:getComponent("PhysicsCollision")
                if pfc and pfc.hasCollider and pfc:hasCollider() and pfc.getCenterPosition then
                    entityCenterX, entityCenterY = pfc:getCenterPosition()
                elseif phys and phys.hasCollider and phys:hasCollider() and phys.collider and phys.collider.body then
                    entityCenterX, entityCenterY = phys.collider.body:getPosition()
                else
                    local spriteRenderer = entity:getComponent("SpriteRenderer")
                    entityCenterX = position.x + ((spriteRenderer and spriteRenderer.width) or 24) * 0.5
                    entityCenterY = position.y + ((spriteRenderer and spriteRenderer.height) or 24) * 0.5
                end

                -- Offset so the near edge starts at collider edge instead of center
                local colliderHalfExtent = 0
                if pfc then
                    colliderHalfExtent = math.max(pfc.width or 0, pfc.height or 0) * 0.5
                elseif phys then
                    colliderHalfExtent = math.max(phys.width or 0, phys.height or 0) * 0.5
                end

                local halfLength = attack.hitAreaWidth * 0.5
                local cx = entityCenterX + math.cos(angle) * (colliderHalfExtent + halfLength)
                local cy = entityCenterY + math.sin(angle) * (colliderHalfExtent + halfLength)

                love.graphics.push()
                love.graphics.translate(cx, cy)
                love.graphics.rotate(angle)

                love.graphics.setColor(1, 0, 0, .5) -- Solid white fill
                love.graphics.rectangle("fill", -attack.hitAreaWidth * 0.5, -attack.hitAreaHeight * 0.5, attack.hitAreaWidth, attack.hitAreaHeight)

                -- Draw outline
                love.graphics.setColor(1, 0, 0, 1) -- Solid black outline
                love.graphics.rectangle("line", -attack.hitAreaWidth * 0.5, -attack.hitAreaHeight * 0.5, attack.hitAreaWidth, attack.hitAreaHeight)

                love.graphics.pop()

                -- Reset color
                love.graphics.setColor(1, 1, 1, 1)
            end
        end
    end
end

return RenderSystem
