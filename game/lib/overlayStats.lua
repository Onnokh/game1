---@class overlayStats
---A performance monitoring overlay module for LÖVE games
---@field isActive boolean Whether the overlay is currently visible
---@field sampleSize number Maximum number of samples to keep for metrics
---@field vsyncEnabled boolean|nil Current VSync state
local name, version, vendor, device = love.graphics.getRendererInfo()
local overlayStats = {
  isActive = false,
  sampleSize = 60,
  vsyncEnabled = nil,
  lastControllerCheck = 0,
  CONTROLLER_COOLDOWN = 0.2,
  -- Store active particle systems
  particleSystems = {},
  renderInfo = {
    name = name,
    version = version,
    vendor = vendor,
    device = device,
  },
  sysInfo = {
    arch = love.system.getOS() ~= "Web" and require("ffi").arch or "Web",
    os = love.system.getOS(),
    cpuCount = love.system.getProcessorCount(),
  },
  supportedFeatures = {
    glsl3 = false,
    pixelShaderHighp = false,
  },
  metrics = {
    canvases = {},
    canvasSwitches = {},
    drawCalls = {},
    drawCallsBatched = {},
    frameTime = {},
    imageCount = {},
    memoryUsage = {},
    shaderSwitches = {},
    textureMemory = {},
    particleCount = {},
  },
  currentSample = 0,
  -- Touch activation parameters
  touch = {
    cornerSize = 80, -- Size of the activation area in pixels
    lastTapTime = 0, -- Time of the last tap
    doubleTapThreshold = 0.5, -- Maximum time between taps to register as double-tap
    overlayArea = { x = 10, y = 10, width = 280, height = 340 }, -- Will be updated in draw
  },
}

-- Private functions

---Calculates averages for all performance metrics
---@return table averages Table of averaged metric values
local function getAverages()
  if not overlayStats.isActive then
    return {}
  end

  local averages = {}
  for metric, samples in pairs(overlayStats.metrics) do
    local sum = 0
    local count = 0
    for _, value in ipairs(samples) do
      sum = sum + value
      count = count + 1
    end
    averages[metric] = count > 0 and sum / count or 0
  end
  return averages
end

---Checks and processes controller input for toggling the overlay
---Called from update() function
local function handleController()
  -- Controller input with cooldown
  local currentTime = love.timer.getTime()
  if currentTime - overlayStats.lastControllerCheck < overlayStats.CONTROLLER_COOLDOWN then
    return
  end

  local joysticks = love.joystick.getJoysticks()
  for _, joystick in ipairs(joysticks) do
    if joystick:isGamepadDown("back") then
      if joystick:isGamepadDown("a") then
        overlayStats.toggleOverlay()
        overlayStats.lastControllerCheck = currentTime
      elseif joystick:isGamepadDown("b") then
        overlayStats.toggleVSync()
        overlayStats.lastControllerCheck = currentTime
      end
    end
  end
end

---Toggles the visibility of the overlay
---Resets all metrics on activation
function overlayStats.toggleOverlay()
  overlayStats.isActive = not overlayStats.isActive
  -- Reset metrics when toggling
  for k, _ in pairs(overlayStats.metrics) do
    overlayStats.metrics[k] = {}
  end
  overlayStats.currentSample = 0
  print(string.format("Overlay %s", overlayStats.isActive and "enabled" or "disabled"))
end

---Toggles the VSync state in LÖVE
---Only functions when the overlay is active
function overlayStats.toggleVSync()
  if not overlayStats.isActive then
    return
  end
  overlayStats.vsyncEnabled = not overlayStats.vsyncEnabled
  love.window.setVSync(overlayStats.vsyncEnabled and 1 or 0)
  print(string.format("VSync %s", overlayStats.vsyncEnabled and "enabled" or "disabled"))
end

---Checks if the given touch position is in the top-right corner activation area
---@param x number The x-coordinate of the touch
---@param y number The y-coordinate of the touch
---@return boolean inCorner True if touch is in the activation area
local function isTouchInCorner(x, y)
  local w, h = love.graphics.getDimensions()
  return x >= w - overlayStats.touch.cornerSize and y <= overlayStats.touch.cornerSize
end

---Checks if the given touch position is inside the overlay area
---@param x number The x-coordinate of the touch
---@param y number The y-coordinate of the touch
---@return boolean insideOverlay True if touch is inside the overlay area
local function isTouchInsideOverlay(x, y)
  local area = overlayStats.touch.overlayArea
  return x >= area.x and x <= area.x + area.width and y >= area.y and y <= area.y + area.height
end

---Processes touch input for the overlay toggle
---@param x number The x-coordinate of the touch
---@param y number The y-coordinate of the touch
---@return nil
local function handleTouch(x, y)
  local currentTime = love.timer.getTime()
  local timeSinceLastTap = currentTime - overlayStats.touch.lastTapTime

  if overlayStats.isActive and isTouchInsideOverlay(x, y) then
    -- Handle touches inside the active overlay
    if timeSinceLastTap <= overlayStats.touch.doubleTapThreshold then
      -- Double tap inside overlay - toggle VSync
      overlayStats.toggleVSync()
      overlayStats.touch.lastTapTime = 0
    else
      overlayStats.touch.lastTapTime = currentTime
    end
  elseif isTouchInCorner(x, y) then
    -- Original behavior for corner taps to toggle overlay
    if timeSinceLastTap <= overlayStats.touch.doubleTapThreshold then
      overlayStats.toggleOverlay()
      overlayStats.touch.lastTapTime = 0
    else
      overlayStats.touch.lastTapTime = currentTime
    end
  end
end

-- Public API

---Initializes the overlay stats module
---@return nil
function overlayStats.load()
  -- Initialize moving averages
  for k, _ in pairs(overlayStats.metrics) do
    overlayStats.metrics[k] = {}
  end
  -- Get initial vsync state from LÖVE config
  overlayStats.vsyncEnabled = love.window.getVSync() == 1

  -- Get graphics feature support information
  local supported = love.graphics.getSupported()
  overlayStats.supportedFeatures.glsl3 = supported.glsl3
  overlayStats.supportedFeatures.pixelShaderHighp = supported.pixelshaderhighp
end

---Draws 16x16 pixel gridlines in world space
---@param cameraX number Camera X position
---@param cameraY number Camera Y position
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.drawGridlines(cameraX, cameraY, cameraScale)
  local width, height = love.graphics.getDimensions()
  local gridSize = 16
  local scale = cameraScale or 1.0

  -- Save current graphics state
  love.graphics.push("all")

  -- Apply camera transform aligned with gamera (use top-left world position)
  local halfW, halfH = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
  local topLeftX = cameraX - (halfW / scale)
  local topLeftY = cameraY - (halfH / scale)
  love.graphics.scale(scale, scale)
  love.graphics.translate(-topLeftX, -topLeftY)

  -- Set gridline color (semi-transparent white)
  love.graphics.setColor(1, 1, 1, 0.3)
  love.graphics.setLineWidth(1)

  -- Calculate world bounds based on camera position
  local startX = math.floor(topLeftX / gridSize) * gridSize
  local startY = math.floor(topLeftY / gridSize) * gridSize
  local endX = startX + width + gridSize
  local endY = startY + height + gridSize

  -- Draw vertical lines
  for x = startX, endX, gridSize do
    love.graphics.line(x, startY, x, endY)
  end

  -- Draw horizontal lines
  for y = startY, endY, gridSize do
    love.graphics.line(startX, y, endX, y)
  end

  -- Draw coordinate labels (DISABLED - conflicts with game coordinate system)
  -- love.graphics.setColor(1, 0, 0, 1) -- Bright red color for coordinates (more visible)
  -- local font = love.graphics.getFont()
  -- local fontSize = .5 / scale -- Larger font size

  -- for x = startX, endX, gridSize do
  --   for y = startY, endY, gridSize do
  --     -- Convert pixel coordinates to tile coordinates (1-based)
  --     local tileX = math.floor(x / gridSize) + 1
  --     local tileY = math.floor(y / gridSize) + 1

  --     -- Only show coordinates for tiles within world bounds
  --     if tileX >= 1 and tileX <= 50 and tileY >= 1 and tileY <= 50 then
  --       local coordText = string.format("%d,%d", tileX, tileY)

  --       -- Position text in top-left corner of tile
  --       love.graphics.print(coordText, x + 2, y + 2, 0, fontSize, fontSize)
  --     end
  --   end
  -- end

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)

  -- Restore graphics state
  love.graphics.pop()
end

---Draws physics colliders in world space using ECS component system
---@param cameraX number Camera X position
---@param cameraY number Camera Y position
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.drawPhysicsColliders(cameraX, cameraY, cameraScale)
  -- Try to access the game scene's ECS world
  local gameState = require("src.core.GameState")
  if not gameState or not gameState.scenes or not gameState.scenes.game then
    return
  end

  -- Access the ECS world from the game scene
  local gameScene = gameState.scenes.game
  if not gameScene.ecsWorld then
    return
  end

  local scale = cameraScale or 1.0

  -- Save current graphics state
  love.graphics.push("all")

  -- Apply camera transform aligned with gamera (use top-left world position)
  local halfW, halfH = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
  local topLeftX = cameraX - (halfW / scale)
  local topLeftY = cameraY - (halfH / scale)
  love.graphics.scale(scale, scale)
  love.graphics.translate(-topLeftX, -topLeftY)

  -- Query all entities with Collision components using the ECS system
  local entitiesWithCollision = gameScene.ecsWorld:getEntitiesWith({"Collision"})

  -- Draw colliders for each entity
  for _, entity in ipairs(entitiesWithCollision) do
    local collision = entity:getComponent("Collision")
    local position = entity:getComponent("Position")

    if collision and collision:hasCollider() and position then
      -- Set color based on collider type
      if collision.type == "static" then
        love.graphics.setColor(0, 1, 0, 0.8) -- Green for static colliders
      elseif collision.type == "dynamic" then
        love.graphics.setColor(1, 0, 0, 0.8) -- Red for dynamic colliders
      elseif collision.type == "kinematic" then
        love.graphics.setColor(0, 0, 1, 0.8) -- Blue for kinematic colliders
      else
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow for unknown types
      end

      love.graphics.setLineWidth(2)

      -- Use Breezefield's built-in drawing method
      collision.collider:__draw__()
    end
  end

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)

  -- Restore graphics state
  love.graphics.pop()
end

---Draws sprite outlines in world space using ECS component system
---@param cameraX number Camera X position
---@param cameraY number Camera Y position
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.drawSpriteOutlines(cameraX, cameraY, cameraScale)
  -- Try to access the game scene's ECS world
  local gameState = require("src.core.GameState")
  if not gameState or not gameState.scenes or not gameState.scenes.game then
    return
  end

  -- Access the ECS world from the game scene
  local gameScene = gameState.scenes.game
  if not gameScene.ecsWorld then
    return
  end

  local scale = cameraScale or 1.0

  -- Save current graphics state
  love.graphics.push("all")

  -- Apply camera transform aligned with gamera (use top-left world position)
  local halfW, halfH = love.graphics.getWidth() / 2, love.graphics.getHeight() / 2
  local topLeftX = cameraX - (halfW / scale)
  local topLeftY = cameraY - (halfH / scale)
  love.graphics.scale(scale, scale)
  love.graphics.translate(-topLeftX, -topLeftY)

  -- Query all entities with SpriteRenderer components using the ECS system
  local entitiesWithSprites = gameScene.ecsWorld:getEntitiesWith({"SpriteRenderer"})

  -- Draw sprite outlines for each entity
  for _, entity in ipairs(entitiesWithSprites) do
    local spriteRenderer = entity:getComponent("SpriteRenderer")
    local position = entity:getComponent("Position")

    if spriteRenderer and position then
      -- Set color for sprite outline (cyan)
      love.graphics.setColor(0, 1, 1, 0.8)
      love.graphics.setLineWidth(1)

      -- Draw rectangle outline around sprite
      love.graphics.rectangle("line", position.x, position.y, spriteRenderer.width, spriteRenderer.height)
    end
  end

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)

  -- Restore graphics state
  love.graphics.pop()
end

---Draws the performance overlay when active
---@param cameraX number Camera X position (optional)
---@param cameraY number Camera Y position (optional)
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.draw(cameraX, cameraY, cameraScale)
  if not overlayStats.isActive then
    return
  end

  local averages = getAverages()

  -- Set up overlay drawing
  love.graphics.push("all")
  local font = love.graphics.setNewFont(16)

  if cameraX and cameraY then
    -- Draw 16x16 gridlines in world space
    overlayStats.drawGridlines(cameraX, cameraY, cameraScale)
    -- Draw physics colliders in world space
    overlayStats.drawPhysicsColliders(cameraX, cameraY, cameraScale)
    -- Draw sprite outlines in world space
    overlayStats.drawSpriteOutlines(cameraX, cameraY, cameraScale)
  end


  -- Calculate dynamic width based on renderer version and other content
  local padding = 20 -- 10px padding on each side
  local baseWidth = 280 -- Minimum width

  -- Check width needed for the renderer version text
  local versionTextWidth = font:getWidth(string.format("%s", overlayStats.renderInfo.version))
  local rendererInfoWidth =
    font:getWidth(string.format("Renderer: %s (%s)", overlayStats.renderInfo.name, overlayStats.renderInfo.vendor))
  local systemInfoWidth = font:getWidth(
    overlayStats.sysInfo.os .. " " .. overlayStats.sysInfo.arch .. ": " .. overlayStats.sysInfo.cpuCount .. "x CPU"
  )

  -- Calculate rectangle width based on the widest content
  local contentWidth = math.max(versionTextWidth, rendererInfoWidth, systemInfoWidth, baseWidth)
  local rectangleWidth = contentWidth + padding

  -- Update the overlay area dimensions for touch detection
  overlayStats.touch.overlayArea = {
    x = 10,
    y = 10,
    width = rectangleWidth,
    height = 340,
  }

  -- Draw background rectangle with dynamic width
  love.graphics.setColor(0, 0, 0, 0.8)
  love.graphics.rectangle("fill", 10, 10, rectangleWidth, 340)
  love.graphics.setColor(0.678, 0.847, 0.902, 1)

  -- System Info
  local y = 20
  love.graphics.print(
    overlayStats.sysInfo.os .. " " .. overlayStats.sysInfo.arch .. ": " .. overlayStats.sysInfo.cpuCount .. "x CPU",
    20,
    y
  )
  y = y + 30

  love.graphics.setColor(1, 1, 1, 1)
  love.graphics.print(
    string.format("Renderer: %s (%s)", overlayStats.renderInfo.name, overlayStats.renderInfo.vendor),
    20,
    y
  )
  y = y + 20

  love.graphics.print(string.format("%s", overlayStats.renderInfo.version), 20, y)
  y = y + 30

  -- Safely handle frameTime with nil/zero checks
  love.graphics.setColor(0, 1, 0, 1)
  local frameTime = averages.frameTime or 0
  local fps = frameTime > 0 and (1 / frameTime) or 0
  love.graphics.print(string.format("FPS: %.1f (%.1fms)", fps, frameTime * 1000), 20, y)
  y = y + 20

  -- Reset canvases each frame
  local currentCanvases = love.graphics.getStats().canvases
  love.graphics.print(string.format("Canvases: %d", currentCanvases), 20, y)
  y = y + 20

  -- Reset canvas switches each frame
  local currentCanvasSwitches = love.graphics.getStats().canvasswitches
  love.graphics.print(string.format("Canvas Switches: %d", currentCanvasSwitches), 20, y)
  y = y + 20

  -- Reset shader switches each frame
  local currentShaderSwitches = love.graphics.getStats().shaderswitches
  love.graphics.print(string.format("Shader Switches: %d", currentShaderSwitches), 20, y)
  y = y + 20

  -- Reset draw calls each frame
  local currentDrawCalls = love.graphics.getStats().drawcalls
  local currentDrawCallsBatched = love.graphics.getStats().drawcallsbatched
  love.graphics.print(string.format("Draw Calls: %d (%d batched)", currentDrawCalls, currentDrawCallsBatched), 20, y)
  y = y + 20

  love.graphics.print(string.format("RAM: %.1f MB", averages.memoryUsage / 1024), 20, y)
  y = y + 20

  -- Reset texture memory usage  each frame
  local currentTextureMemory = love.graphics.getStats().texturememory / (1024 * 1024)
  love.graphics.print(string.format("VRAM: %.1f MB", currentTextureMemory), 20, y)
  y = y + 20

  -- Reset images each frame
  local currentImages = love.graphics.getStats().images
  love.graphics.print(string.format("Images: %d", currentImages), 20, y)
  y = y + 20

  -- Display particle count
  local currentParticleCount = averages.particleCount or 0
  love.graphics.print(string.format("Particles: %d", math.floor(currentParticleCount)), 20, y)
  y = y + 20

  -- Display collider count using ECS system
  local colliderCount = 0
  if cameraX and cameraY then
    local gameState = require("src.core.GameState")
    if gameState and gameState.scenes and gameState.scenes.game and gameState.scenes.game.ecsWorld then
      local entitiesWithCollision = gameState.scenes.game.ecsWorld:getEntitiesWith({"Collision"})
      colliderCount = #entitiesWithCollision
    end
  end
  love.graphics.print(string.format("Colliders: %d", colliderCount), 20, y)
  y = y + 20

  -- Add GLSL 3 support indicator
  love.graphics.setColor(overlayStats.supportedFeatures.glsl3 and { 0, 1, 0, 1 } or { 1, 0, 0, 1 })
  love.graphics.print(string.format("GLSL 3: %s", overlayStats.supportedFeatures.glsl3 and "Yes" or "No"), 20, y)
  y = y + 20

  -- Add pixel shader highp support indicator
  love.graphics.setColor(overlayStats.supportedFeatures.pixelShaderHighp and { 0, 1, 0, 1 } or { 1, 0, 0, 1 })
  love.graphics.print(
    string.format("Pixel Shader highp: %s", overlayStats.supportedFeatures.pixelShaderHighp and "Yes" or "No"),
    20,
    y
  )
  y = y + 20

  -- Add VSync status with color indication
  love.graphics.setColor(overlayStats.vsyncEnabled and { 0, 1, 0, 1 } or { 1, 0, 0, 1 })
  love.graphics.print(string.format("VSync: %s", overlayStats.vsyncEnabled and "ON" or "OFF"), 20, y)

  love.graphics.pop()
end

---Updates performance metrics and handles controller input
---@param dt number Delta time since the last frame
---@return nil
function overlayStats.update(dt)
  handleController()

  if not overlayStats.isActive then
    return
  end
  overlayStats.currentSample = overlayStats.currentSample + 1
  if overlayStats.currentSample > overlayStats.sampleSize then
    overlayStats.currentSample = 1
  end

  -- Get draw call stats before any drawing occurs
  local stats = love.graphics.getStats()
  overlayStats.metrics.canvases[overlayStats.currentSample] = stats.canvases
  overlayStats.metrics.canvasSwitches[overlayStats.currentSample] = stats.canvasswitches
  overlayStats.metrics.drawCalls[overlayStats.currentSample] = stats.drawcalls
  overlayStats.metrics.drawCallsBatched[overlayStats.currentSample] = stats.drawcallsbatched
  overlayStats.metrics.imageCount[overlayStats.currentSample] = stats.images
  overlayStats.metrics.shaderSwitches[overlayStats.currentSample] = stats.shaderswitches
  overlayStats.metrics.textureMemory[overlayStats.currentSample] = stats.texturememory / (1024 * 1024)
  overlayStats.metrics.memoryUsage[overlayStats.currentSample] = collectgarbage("count")
  overlayStats.metrics.frameTime[overlayStats.currentSample] = dt

  -- Calculate total particle count from all registered systems
  local totalParticles = 0
  for ps, _ in pairs(overlayStats.particleSystems) do
    if ps:isActive() then
      totalParticles = totalParticles + ps:getCount()
    end
  end
  overlayStats.metrics.particleCount[overlayStats.currentSample] = totalParticles
end

---Processes keyboard input for the overlay
---@param key string The key that was pressed
---@return nil
function overlayStats.handleKeyboard(key)
  if key == "f3" or key == "`" then
    overlayStats.toggleOverlay()
  elseif key == "f5" then
    overlayStats.toggleVSync()
  end
end

---Handles touch press events for toggling the overlay
---@param id any Touch ID from LÖVE
---@param x number The x-coordinate of the touch
---@param y number The y-coordinate of the touch
---@param dx number The horizontal component of the touch press
---@param dy number The vertical component of the touch press
---@param pressure number The pressure of the touch
---@return nil
function overlayStats.handleTouch(id, x, y, dx, dy, pressure)
  handleTouch(x, y)
end

---Register a particle system to be tracked
---@param particleSystem love.ParticleSystem The particle system to register
---@return nil
function overlayStats.registerParticleSystem(particleSystem)
  overlayStats.particleSystems[particleSystem] = true
end

---Unregister a particle system from tracking
---@param particleSystem love.ParticleSystem The particle system to unregister
---@return nil
function overlayStats.unregisterParticleSystem(particleSystem)
  overlayStats.particleSystems[particleSystem] = nil
end

return overlayStats
