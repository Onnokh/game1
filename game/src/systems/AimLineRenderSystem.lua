local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")
local GameState = require("src.core.GameState")
local ShaderManager = require("src.core.managers.ShaderManager")
local GameController = require("src.core.GameController")

---@class AimLineRenderSystem : System
---Renders an aiming line for ranged weapons from player to mouse cursor
local AimLineRenderSystem = System:extend("AimLineRenderSystem", {})

-- Store the original new function
local originalNew = AimLineRenderSystem.new

-- Crosshair image for the end of the aim line
local crosshairImage = nil

---Load the crosshair image for the aim line
local function loadCrosshairImage()
    if not crosshairImage then
        local crosshairPath = "resources/ui/crosshair161.png"
        local success, result = pcall(function()
            local img = love.graphics.newImage(crosshairPath)
            img:setFilter("nearest", "nearest") -- Pixel-perfect for pixel art
            return img
        end)

        if success then
            crosshairImage = result
            print("Crosshair image loaded for aim line:", crosshairPath)
            print("Crosshair image dimensions:", crosshairImage:getWidth(), "x", crosshairImage:getHeight())
        else
            print("Failed to load crosshair image for aim line:", result)
        end
    end
end

---Create a new AimLineRenderSystem instance
---@return AimLineRenderSystem
function AimLineRenderSystem.new()
    local self = originalNew()
    self.isWorldSpace = false -- This system draws in screen space with world-to-screen conversion

    -- Load crosshair image when system is created
    loadCrosshairImage()

    return self
end

---Draw the aiming line
function AimLineRenderSystem:draw()
    -- Don't draw aiming line when game is paused or over
    if GameController.paused or GameController.gameOver then
        return
    end

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

    -- Get current real-time mouse position to avoid frame lag
    local screenMouseX, screenMouseY = love.mouse.getPosition()
    local mouseX, mouseY = GameState.camera:toWorld(screenMouseX, screenMouseY)

    -- Calculate direction from player to mouse
    local dx = mouseX - playerX
    local dy = mouseY - playerY
    local distanceToMouse = math.sqrt(dx * dx + dy * dy)

    -- Limit aim line to maximum 150 pixels
    local maxLength = 100
    local endX, endY = mouseX, mouseY

    if distanceToMouse > maxLength then
        -- Scale the direction vector to maxLength
        local normalizedDx = dx / distanceToMouse
        local normalizedDy = dy / distanceToMouse
        endX = playerX + normalizedDx * maxLength
        endY = playerY + normalizedDy * maxLength
    end

    -- Perform raycasting to find collision point (only within the limited range)
    local hitSomething = false
    local closestFraction = 1.0

    if world.physicsWorld then
        -- Raycast from player to limited end position
        world.physicsWorld:rayCast(playerX, playerY, endX, endY, function(fixture, x, y, xn, yn, fraction)
            -- Check if this is a static object (walls, obstacles)
            local body = fixture:getBody()
            if body:getType() == "static" then
                -- Only update if this is closer than previous hits
                if fraction < closestFraction then
                    endX = x
                    endY = y
                    hitSomething = true
                    closestFraction = fraction
                end
                -- Return the fraction to continue checking for closer hits
                return fraction
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

    -- Calculate bounding box covering entire screen for infinite line
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

    -- Animation and style parameters
    shader:send("animationSpeed", 50.0)
    shader:send("dotRadius", 5.0)
    shader:send("dotSpacing", 64.0)
    shader:send("targetDotRadius", 6.0)
    shader:send("targetCrossThickness", 15.0)

    -- Send crosshair texture to shader
    if crosshairImage then
        shader:send("crosshairTexture", crosshairImage)
    end

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

