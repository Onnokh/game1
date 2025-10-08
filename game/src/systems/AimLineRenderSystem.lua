local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")
local GameState = require("src.core.GameState")
local ShaderManager = require("src.utils.ShaderManager")

---@class AimLineRenderSystem : System
---Renders an aiming line for ranged weapons from player to mouse cursor
local AimLineRenderSystem = System:extend("AimLineRenderSystem", {})

-- Store the original new function
local originalNew = AimLineRenderSystem.new

---Create a new AimLineRenderSystem instance
---@return AimLineRenderSystem
function AimLineRenderSystem.new()
    local self = originalNew()
    self.isWorldSpace = false -- This system draws in screen space with world-to-screen conversion
    return self
end

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

    -- Convert world coordinates to screen coordinates
    local screenStartX, screenStartY = playerX, playerY
    local screenEndX, screenEndY = endX, endY

    if GameState.camera and GameState.camera.toScreen then
        screenStartX, screenStartY = GameState.camera:toScreen(playerX, playerY)
        screenEndX, screenEndY = GameState.camera:toScreen(endX, endY)
    end

    -- Get the shader
    local shader = ShaderManager.getShader("aim_line")
    if not shader then
        return -- Shader not loaded
    end

    local screenWidth = love.graphics.getWidth()
    local screenHeight = love.graphics.getHeight()
    local minX = 0
    local minY = 0
    local width = screenWidth
    local height = screenHeight

    -- Draw in screen space (outside camera transform)
    love.graphics.push()
    love.graphics.origin()

    -- Set shader uniforms
    shader:send("startPos", {screenStartX, screenStartY})
    shader:send("endPos", {screenEndX, screenEndY})
    shader:send("targetPos", {screenEndX, screenEndY})
    shader:send("time", love.timer.getTime())
    shader:send("isHit", hitSomething)

    -- Draw rectangle covering the line area with shader
    love.graphics.setShader(shader)
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.rectangle("fill", minX, minY, width, height)
    love.graphics.setShader()

    love.graphics.pop()

    -- Reset graphics state
    love.graphics.setColor(1, 1, 1, 1)
end

return AimLineRenderSystem

