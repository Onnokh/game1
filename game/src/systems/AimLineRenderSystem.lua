local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")
local GameState = require("src.core.GameState")

---@class AimLineRenderSystem : System
---Renders an aiming line for ranged weapons from player to mouse cursor
local AimLineRenderSystem = System:extend("AimLineRenderSystem", {})

---Draw the aiming line
function AimLineRenderSystem:draw()
    -- Get the world reference
    local world = self.world
    if not world then
        return
    end

    -- Find the player entity
    local player = EntityUtils.findPlayer(world)
    if not player then
        return
    end

    -- Check if player has a weapon component
    local weapon = player:getComponent("Weapon")
    if not weapon then
        return
    end

    -- Get current weapon data
    local currentWeapon = weapon:getCurrentWeapon()
    if not currentWeapon then
        return
    end

    -- Only draw aim line for ranged weapons
    if currentWeapon.type ~= "ranged" then
        return
    end

    -- Get player position
    local position = player:getComponent("Position")
    if not position then
        return
    end

    -- Get player's visual center
    local playerX, playerY = EntityUtils.getEntityVisualCenter(player, position)

    -- Get mouse position from GameState
    local mouseX = GameState.input.mouseX
    local mouseY = GameState.input.mouseY

    -- Perform raycasting to find collision point
    local endX, endY = mouseX, mouseY
    local hitSomething = false

    if world.physicsWorld then
        -- Raycast from player to mouse position
        world.physicsWorld:rayCast(playerX, playerY, mouseX, mouseY, function(fixture, x, y, xn, yn, fraction)
            -- Check if this is a static object (walls, obstacles)
            local body = fixture:getBody()
            if body:getType() == "static" then
                -- Hit a wall! Update the end point
                endX = x
                endY = y
                hitSomething = true
                -- Return 0 to stop the raycast (we found the first collision)
                return 0
            end
            -- Return 1 to continue the raycast (ignore dynamic objects like enemies)
            return 1
        end)
    end

    -- Draw the aiming line
    love.graphics.setColor(1, 1, 1, 1) -- Yellow with 50% opacity
    love.graphics.setLineWidth(1)
    love.graphics.line(playerX, playerY, endX, endY)

    -- Draw different indicator based on whether we hit something
    if hitSomething then
        -- Draw an X or impact marker at the collision point
        love.graphics.setColor(1, 1, 1, 1) -- Yellow
        love.graphics.circle("fill", endX, endY, 2)
    else
      love.graphics.circle("fill", endX, endY, 1)
    end

    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.setLineWidth(1)
end

return AimLineRenderSystem

