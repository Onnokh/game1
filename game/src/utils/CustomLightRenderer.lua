local CustomLightRenderer = {}

-- Module state
local initialized = false
local lightMap = nil
local lights = {}
local nextLightId = 1
local ambient = { r = 0.55, g = 0.55, b = 0.55, a = 1.0 } -- Default: very dark
local tween = {
    active = false,
    start = { r = 0.05, g = 0.05, b = 0.05, a = 1.0 },
    target = { r = 0.05, g = 0.05, b = 0.05, a = 1.0 },
    elapsed = 0,
    duration = 0
}

-- GPU shader state
local lightShader = nil
local lightDataImageData = nil
local lightColorImageData = nil
local lightDataImage = nil
local lightColorImage = nil
local maxLights = 256
local screenWidth = 0
local screenHeight = 0

-- Initialize the renderer
function CustomLightRenderer.init(width, height)
    if initialized then return end

    print("[CustomLightRenderer] Initializing GPU-based lighting with size:", width, height)

    screenWidth = width
    screenHeight = height

    -- Create lightmap canvas
    lightMap = love.graphics.newCanvas(width, height)
    if not lightMap then
        error("Failed to create lightmap canvas")
    end

    -- Load the light shader
    local vertCode = love.filesystem.read("src/shaders/light.vert")
    local fragCode = love.filesystem.read("src/shaders/light.frag")
    if not vertCode or not fragCode then
        error("Failed to load light shader files")
    end

    lightShader = love.graphics.newShader(vertCode, fragCode)
    if not lightShader then
        error("Failed to create light shader")
    end

    -- Create image data for light textures (256x1 RGBA float format)
    lightDataImageData = love.image.newImageData(maxLights, 1, "rgba32f")
    lightColorImageData = love.image.newImageData(maxLights, 1, "rgba32f")

    -- Create images from image data
    lightDataImage = love.graphics.newImage(lightDataImageData)
    lightColorImage = love.graphics.newImage(lightColorImageData)

    -- Set nearest filtering for pixel-perfect rendering
    lightDataImage:setFilter("nearest", "nearest")
    lightColorImage:setFilter("nearest", "nearest")

    initialized = true
    print("[CustomLightRenderer] Initialized successfully with GPU shader")
end

-- Get ambient color
function CustomLightRenderer.get()
    return ambient
end

-- Set ambient color (darkness intensity)
function CustomLightRenderer.setAmbientColor(r, g, b, a, duration)
    local targetR = (r or 50) / 255
    local targetG = (g or 50) / 255
    local targetB = (b or 50) / 255
    local targetA = (a or 255) / 255

    if duration and duration > 0 and initialized then
        tween.active = true
        tween.start.r, tween.start.g, tween.start.b, tween.start.a = ambient.r, ambient.g, ambient.b, ambient.a
        tween.target.r, tween.target.g, tween.target.b, tween.target.a = targetR, targetG, targetB, targetA
        tween.elapsed = 0
        tween.duration = duration
    else
        ambient.r, ambient.g, ambient.b, ambient.a = targetR, targetG, targetB, targetA
        tween.active, tween.elapsed, tween.duration = false, 0, 0
    end
end

-- Update function for tweening
function CustomLightRenderer.update(dt, camera)
    if not initialized then return end

    -- Handle ambient color tweening
    if tween.active then
        tween.elapsed = tween.elapsed + dt
        local d = tween.duration > 0 and tween.duration or 0
        local u = d > 0 and math.min(1, tween.elapsed / d) or 1
        local function lerp(a, b, k) return a + (b - a) * k end
        ambient.r = lerp(tween.start.r, tween.target.r, u)
        ambient.g = lerp(tween.start.g, tween.target.g, u)
        ambient.b = lerp(tween.start.b, tween.target.b, u)
        ambient.a = lerp(tween.start.a, tween.target.a, u)
        if u >= 1 then tween.active = false end
    end
end

-- Add a light and return its ID
function CustomLightRenderer.addLight(x, y, radius, r, g, b, a)
    local id = nextLightId
    nextLightId = nextLightId + 1

    lights[id] = {
        x = x or 0,
        y = y or 0,
        radius = radius or 100,
        r = r or 255,
        g = g or 255,
        b = b or 255,
        a = a or 255,
        enabled = true
    }

    return id
end

-- Remove a light
function CustomLightRenderer.removeLight(id)
    if lights[id] then
        lights[id].enabled = false
    end
end

-- Set light position
function CustomLightRenderer.setLightPosition(id, x, y)
    if lights[id] then
        lights[id].x = x
        lights[id].y = y
    end
end

-- Render the darkness overlay using GPU shader
function CustomLightRenderer.renderDarknessMap(camera)
    if not initialized or not lightShader then
        return
    end

    -- Render to lightmap canvas
    love.graphics.setCanvas(lightMap)

    -- Clear to ambient darkness color
    love.graphics.clear(ambient.r, ambient.g, ambient.b, 1.0)

    if not camera then
        love.graphics.setCanvas()
        return
    end

    -- Collect active lights and transform to screen space
    -- Use canvas dimensions (not screen) since we're rendering to lightMap
    local screenW, screenH = lightMap:getWidth(), lightMap:getHeight()
    local camScale = camera:getScale()

    local lightCount = 0
    local lightData = {}
    local lightColors = {}

    for id, light in pairs(lights) do
        if light.enabled and lightCount < maxLights then
            -- Transform light position from world to screen coordinates
            local screenX, screenY = camera:toScreen(light.x, light.y)
            local normalizedX = screenX / screenW
            local normalizedY = screenY / screenH

            -- Transform radius to screen space and normalize
            local screenRadius = (light.radius or 100) * camScale
            local normalizedRadius = screenRadius / screenW

            -- Store light data: (normalizedX, normalizedY, normalizedRadius, intensity)
            lightData[lightCount + 1] = {
                x = normalizedX,
                y = normalizedY,
                radius = normalizedRadius,
                intensity = 1.0  -- intensity multiplier
            }

            -- Store light color: (r, g, b, a) normalized
            lightColors[lightCount + 1] = {
                r = (light.r or 255) / 255,
                g = (light.g or 255) / 255,
                b = (light.b or 255) / 255,
                a = (light.a or 255) / 255
            }

            lightCount = lightCount + 1
        end
    end

    -- Upload light data to textures
    if lightCount > 0 then
        -- Pack light data into image data
        for i = 1, lightCount do
            local data = lightData[i]
            if data then
                lightDataImageData:setPixel(i - 1, 0, data.x, data.y, data.radius, data.intensity)

                local color = lightColors[i]
                if color then
                    lightColorImageData:setPixel(i - 1, 0, color.r, color.g, color.b, color.a)
                end
            end
        end

        -- Update image textures
        lightDataImage = love.graphics.newImage(lightDataImageData)
        lightColorImage = love.graphics.newImage(lightColorImageData)
        lightDataImage:setFilter("nearest", "nearest")
        lightColorImage:setFilter("nearest", "nearest")

        -- Set shader uniforms
        lightShader:send("numLights", lightCount)
        lightShader:send("screenSize", {screenW, screenH})
        lightShader:send("ambientColor", {ambient.r, ambient.g, ambient.b})
        lightShader:send("lightData", lightDataImage)
        lightShader:send("lightColor", lightColorImage)

        -- Set shader and draw full-screen quad
        love.graphics.setShader(lightShader)
        love.graphics.rectangle("fill", 0, 0, screenW, screenH)
        love.graphics.setShader()
    end

    love.graphics.setCanvas()
end

-- Draw the darkness overlay on top of the world (called after world renders)
function CustomLightRenderer.drawOverlay()
    if not initialized then
        return
    end

    -- Draw the lightmap with multiply blend to darken based on lightmap values
    love.graphics.setBlendMode("multiply", "premultiplied")
    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.draw(lightMap, 0, 0)
    love.graphics.setBlendMode("alpha")
end

-- Cleanup
function CustomLightRenderer.cleanup()
    if not initialized then return end

    -- Remove all lights
    lights = {}
    nextLightId = 1

    -- Release canvas
    if lightMap then
        lightMap:release()
        lightMap = nil
    end

    -- Release shader resources
    if lightShader then
        lightShader:release()
        lightShader = nil
    end

    if lightDataImage then
        lightDataImage:release()
        lightDataImage = nil
    end

    if lightColorImage then
        lightColorImage:release()
        lightColorImage = nil
    end

    initialized = false
end

return CustomLightRenderer
