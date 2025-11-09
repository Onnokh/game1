local System = require("src.core.System")
local EntityUtils = require("src.utils.entities")
local GameState = require("src.core.GameState")
local ShaderManager = require("src.core.managers.ShaderManager")
local GameController = require("src.core.GameController")
local PlayerConfig = require("src.entities.Player.PlayerConfig")

---@class AimLineRenderSystem : System
---@field isWorldSpace boolean
---Renders an aiming line for ranged weapons from player to mouse cursor
local AimLineRenderSystem = System:extend("AimLineRenderSystem", {})

-- Laser styling and behaviour constants
local MAX_BEAM_LENGTH = 400    -- Maximum reach of the laser regardless of cursor distance
local MIN_RAY_LENGTH = 2       -- Avoid Box2D raycasts with extremely short segments
local BEAM_WIDTH = 1           -- Core thickness of the beam in pixels
local GLOW_WIDTH = 8          -- Total width of the glow area around the beam
local GLOW_FALLOFF = 2.2       -- Power falloff applied to the outer glow
local SOFT_EDGE = 2            -- Soft edge thickness applied to the beam core
local PARTICLE_FREQUENCY = 0.025 -- Controls density of laser particles along the beam (per pixel)
local PARTICLE_SPEED = 0.6       -- Scroll speed of particles
local PARTICLE_STRENGTH = 0.75   -- Intensity contribution of the particles

-- Store the original new function
local originalNew = AimLineRenderSystem.new

---Create a new AimLineRenderSystem instance
---@return AimLineRenderSystem
function AimLineRenderSystem.new()
    ---@type AimLineRenderSystem
    local self = originalNew()
    self.isWorldSpace = false -- This system draws in screen space with world-to-screen conversion

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

    -- Get player's sprite renderer and animator to get gun layer offset
    local spriteRenderer = player:getComponent("SpriteRenderer")
    local animator = player:getComponent("Animator")
    if not spriteRenderer or not animator then
        return
    end

    -- Get the gun layer offset (this already accounts for direction flipping)
    local gunOffset = animator:getLayerOffset("gun")
    local playerX = position.x + gunOffset.x
    local playerY = position.y + gunOffset.y + 3

    -- Get mouse position (use auto-aim position if active, otherwise real mouse position)
    local mouseX, mouseY
    if GameState.input.autoAim then
        -- Use auto-aim position from GameState
        mouseX = GameState.input.mouseX
        mouseY = GameState.input.mouseY
    else
        -- Use real mouse position
        local CoordinateUtils = require("src.utils.coordinates")
        local screenMouseX, screenMouseY = love.mouse.getPosition()
        mouseX, mouseY = CoordinateUtils.screenToWorld(screenMouseX, screenMouseY, GameState.camera)
    end

    -- Calculate direction from player to mouse
    local dx = mouseX - playerX
    local dy = mouseY - playerY
    local distanceToMouse = math.sqrt(dx * dx + dy * dy)

    -- Apply start offset in the aiming direction
    if distanceToMouse > 0 then
        local normalizedDx = dx / distanceToMouse
        local normalizedDy = dy / distanceToMouse
        playerX = playerX + normalizedDx * PlayerConfig.START_OFFSET
        playerY = playerY + normalizedDy * PlayerConfig.START_OFFSET
    end

    -- Perform raycasting to find collision point (raycast to actual cursor, not clamped position)
    local hitSomething = false
    local closestFraction = 1.0
    local endX, endY = mouseX, mouseY -- Start with actual cursor position

    if world.physicsWorld then
        -- Check if start and end points are different to avoid Box2D assertion error
        local rayDx = mouseX - playerX
        local rayDy = mouseY - playerY
        local rayDistance = math.sqrt(rayDx * rayDx + rayDy * rayDy)

        if rayDistance > 0.001 then -- Small threshold to avoid zero-length rays
            -- Raycast from player to actual cursor position to detect all collisions
            world.physicsWorld:rayCast(playerX, playerY, mouseX, mouseY, function(fixture, x, y, xn, yn, fraction)
            -- Check if this is a static or kinematic object (walls, obstacles, trees, decorations)
            local body = fixture:getBody()
            local bodyType = body:getType()
            if bodyType == "static" or bodyType == "kinematic" then
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
    end

    -- Limit aim line to maximum length (only if no collision detected)
    local maxLength = 100
    if not hitSomething then
        local distanceToEnd = math.sqrt((endX - playerX)^2 + (endY - playerY)^2)
        if distanceToEnd > maxLength then
            -- Scale the direction vector to maxLength
            local normalizedDx = dx / distanceToMouse
            local normalizedDy = dy / distanceToMouse
            endX = playerX + normalizedDx * maxLength
            endY = playerY + normalizedDy * maxLength
        end
    end

    -- Convert world coordinates to screen coordinates
    local CoordinateUtils = require("src.utils.coordinates")
    local screenStartX, screenStartY = CoordinateUtils.worldToScreen(playerX, playerY, GameState.camera)
    local screenEndX, screenEndY = CoordinateUtils.worldToScreen(endX, endY, GameState.camera)

    -- Convert actual mouse/cursor position to screen coordinates for targetPos
    -- This ensures the crosshair appears at the cursor, not the clamped position
    local screenTargetX, screenTargetY = CoordinateUtils.worldToScreen(mouseX, mouseY, GameState.camera)

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
    shader:send("targetPos", {screenTargetX, screenTargetY})
    shader:send("time", love.timer.getTime())
    shader:send("isHit", hitSomething)
    shader:send("particleFrequency", PARTICLE_FREQUENCY)
    shader:send("particleSpeed", PARTICLE_SPEED)
    shader:send("particleStrength", PARTICLE_STRENGTH)

    -- Style parameters
    shader:send("targetDotRadius", 3.0)

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

