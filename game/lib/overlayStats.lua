---@class overlayStats
---A performance monitoring overlay module for LÖVE games
---@field isActive boolean Whether the overlay is currently visible
---@field sampleSize number Maximum number of samples to keep for metrics
---@field vsyncEnabled boolean|nil Current VSync state
local name, version, vendor, device = love.graphics.getRendererInfo()
local overlayFontMain = nil
local overlayFontSmall = nil
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
  -- Cache fonts used by overlay to avoid per-frame allocations
  overlayFontMain = love.graphics.newFont(16)
  overlayFontSmall = love.graphics.newFont(8)
end

---Draws gridlines in world space using GameConstants.TILE_SIZE
---@param cameraX number Camera X position
---@param cameraY number Camera Y position
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.drawGridlines(cameraX, cameraY, cameraScale)
  local width, height = love.graphics.getDimensions()
  local GameConstants = require("src.constants")
  local gridSize = GameConstants.TILE_SIZE
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

  -- Query all entities with PathfindingCollision components (pathfinding and physics collision) using the ECS system
  local entitiesWithPathfindingCollision = gameScene.ecsWorld:getEntitiesWith({"PathfindingCollision"})

  -- Draw pathfinding colliders for each entity
  for _, entity in ipairs(entitiesWithPathfindingCollision) do
    local pathfindingCollision = entity:getComponent("PathfindingCollision")
    local position = entity:getComponent("Position")

    if pathfindingCollision and pathfindingCollision:hasCollider() and position then
      -- Set color based on collider type - pathfinding colliders use solid colors
      if pathfindingCollision.type == "static" then
        love.graphics.setColor(0, 1, 0, 0.8) -- Green for static colliders
      elseif pathfindingCollision.type == "dynamic" then
        love.graphics.setColor(1, 0, 0, 0.8) -- Red for dynamic colliders
      elseif pathfindingCollision.type == "kinematic" then
        love.graphics.setColor(0, 0, 1, 0.8) -- Blue for kinematic colliders
      else
        love.graphics.setColor(1, 1, 0, 0.8) -- Yellow for unknown types
      end

      love.graphics.setLineWidth(2) -- Thicker line for pathfinding colliders

      -- Draw Love2D physics collider manually (for static entities) or pathfinding bounds (for dynamic entities)
      if pathfindingCollision.collider and pathfindingCollision.collider.body and pathfindingCollision.collider.shape then
        -- Static entities with physics bodies
        local body = pathfindingCollision.collider.body
        local shape = pathfindingCollision.collider.shape
        local bodyX, bodyY = body:getPosition()
        local bodyAngle = body:getAngle()

        love.graphics.push()
        love.graphics.translate(bodyX, bodyY)
        love.graphics.rotate(bodyAngle)

        -- Draw shape based on type
        if shape:getType() == "rectangle" then
          local w, h = shape:getDimensions()
          love.graphics.rectangle("line", -w/2, -h/2, w, h)
        elseif shape:getType() == "polygon" then
          local points = {shape:getPoints()}
          love.graphics.polygon("line", points)
        elseif shape:getType() == "circle" then
          local radius = shape:getRadius()
          love.graphics.circle("line", 0, 0, radius)
        end

        love.graphics.pop()
      elseif pathfindingCollision.collider then
        -- Dynamic entities without physics bodies (pathfinding only)
        local colliderX, colliderY = pathfindingCollision:getPosition()
        love.graphics.rectangle("line", colliderX, colliderY, pathfindingCollision.width, pathfindingCollision.height)
      end
    end
  end

  -- Query all entities with PhysicsCollision components (physics) using the ECS system
  local entitiesWithPhysicsCollision = gameScene.ecsWorld:getEntitiesWith({"PhysicsCollision"})

  -- Draw physics colliders for each entity
  for _, entity in ipairs(entitiesWithPhysicsCollision) do
    local physicsCollision = entity:getComponent("PhysicsCollision")
    local position = entity:getComponent("Position")

    if physicsCollision and physicsCollision:hasCollider() and position then
      -- Set color based on collider type - physics colliders use dashed/dotted colors
      if physicsCollision.type == "static" then
        love.graphics.setColor(0, 1, 0, 0.6) -- Green for static colliders (dimmer)
      elseif physicsCollision.type == "dynamic" then
        love.graphics.setColor(1, 0, 0, 0.6) -- Red for dynamic colliders (dimmer)
      elseif physicsCollision.type == "kinematic" then
        love.graphics.setColor(0, 0, 1, 0.6) -- Blue for kinematic colliders (dimmer)
      else
        love.graphics.setColor(1, 1, 0, 0.6) -- Yellow for unknown types (dimmer)
      end

      love.graphics.setLineWidth(1) -- Thinner line for physics colliders
      love.graphics.setLineStyle("rough") -- Dashed line style for physics colliders

      -- Draw Love2D physics collider manually
      if physicsCollision.collider and physicsCollision.collider.body and physicsCollision.collider.shape then
        local body = physicsCollision.collider.body
        local shape = physicsCollision.collider.shape
        local bodyX, bodyY = body:getPosition()
        local bodyAngle = body:getAngle()

        love.graphics.push()
        love.graphics.translate(bodyX, bodyY)
        love.graphics.rotate(bodyAngle)

        -- Draw shape based on type
        if shape:getType() == "rectangle" then
          local w, h = shape:getDimensions()
          love.graphics.rectangle("line", -w/2, -h/2, w, h)
        elseif shape:getType() == "polygon" then
          local points = {shape:getPoints()}
          love.graphics.polygon("line", points)
        elseif shape:getType() == "circle" then
          local radius = shape:getRadius()
          love.graphics.circle("line", 0, 0, radius)
        end

        love.graphics.pop()
      end
    end
  end

  -- Draw ephemeral AttackCollider sensors with rotation
  local entitiesWithAttackCollider = gameScene.ecsWorld:getEntitiesWith({"AttackCollider"})
  for _, entity in ipairs(entitiesWithAttackCollider) do
    local attackCollider = entity:getComponent("AttackCollider")
    if attackCollider and attackCollider.collider and attackCollider.collider.body and attackCollider.collider.shape then
      local body = attackCollider.collider.body
      local shape = attackCollider.collider.shape
      local bodyX, bodyY = body:getPosition()
      local bodyAngle = body:getAngle()

      love.graphics.setColor(1, 1, 0, 0.85) -- Yellow for attack sensors
      love.graphics.setLineWidth(2)

      love.graphics.push()
      love.graphics.translate(bodyX, bodyY)
      love.graphics.rotate(bodyAngle)

      if shape:getType() == "rectangle" then
        local w, h = shape:getDimensions()
        love.graphics.rectangle("line", -w/2, -h/2, w, h)
      elseif shape:getType() == "polygon" then
        local points = {shape:getPoints()}
        love.graphics.polygon("line", points)
      elseif shape:getType() == "circle" then
        local radius = shape:getRadius()
        love.graphics.circle("line", 0, 0, radius)
      end

      love.graphics.pop()
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

---Draws pathfinding debug information in screen space
---@param cameraX number Camera X position
---@param cameraY number Camera Y position
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.drawPathfindingDebug(cameraX, cameraY, cameraScale)
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

  local GameConstants = require("src.constants")
  local tileSize = GameConstants.TILE_SIZE
  local scale = cameraScale or 1.0
  local screenWidth, screenHeight = love.graphics.getDimensions()
  local halfW, halfH = screenWidth / 2, screenHeight / 2

  -- Use main font for better readability
  if overlayFontMain then
    love.graphics.setFont(overlayFontMain)
  end

  -- Query all entities with Pathfinding components using the ECS system
  local entitiesWithPathfinding = gameScene.ecsWorld:getEntitiesWith({"Pathfinding"})

  -- Draw pathfinding debug for each entity
  for _, entity in ipairs(entitiesWithPathfinding) do
    local pathfinding = entity:getComponent("Pathfinding")
    local position = entity:getComponent("Position")
    local pathfindingCollision = entity:getComponent("PathfindingCollision")

    if pathfinding and position then
      -- Draw current path
      if pathfinding.currentPath and not pathfinding:isPathComplete() then
        -- Draw the complete path from skeleton to destination
        love.graphics.setColor(0, 1, 0, 0.8) -- Green

        -- Start from pathfinding collision center position (or sprite center if no collision)
        local prevWorldX, prevWorldY = position.x + 8, position.y + 8
        if pathfindingCollision and pathfindingCollision:hasCollider() then
          -- Use pathfinding collision center position
          prevWorldX, prevWorldY = pathfindingCollision:getCenterPosition()
        end

        -- Convert to screen coordinates
        local prevScreenX = halfW + (prevWorldX - cameraX) * scale
        local prevScreenY = halfH + (prevWorldY - cameraY) * scale

        -- Draw line from skeleton to first waypoint
        if pathfinding.pathIndex <= #pathfinding.currentPath._nodes then
          local firstNode = pathfinding.currentPath._nodes[pathfinding.pathIndex]
          local firstWorldX = (firstNode._x - 1) * tileSize + tileSize / 2
          local firstWorldY = (firstNode._y - 1) * tileSize + tileSize / 2
          local firstScreenX = halfW + (firstWorldX - cameraX) * scale
          local firstScreenY = halfH + (firstWorldY - cameraY) * scale

          love.graphics.line(prevScreenX, prevScreenY, firstScreenX, firstScreenY)
          prevScreenX, prevScreenY = firstScreenX, firstScreenY
        end

        -- Draw remaining path segments
        for i = pathfinding.pathIndex + 1, #pathfinding.currentPath._nodes do
          local node = pathfinding.currentPath._nodes[i]
          local worldX = (node._x - 1) * tileSize + tileSize / 2
          local worldY = (node._y - 1) * tileSize + tileSize / 2
          local screenX = halfW + (worldX - cameraX) * scale
          local screenY = halfH + (worldY - cameraY) * scale

          love.graphics.line(prevScreenX, prevScreenY, screenX, screenY)
          prevScreenX, prevScreenY = screenX, screenY
        end

        -- Draw coordinate labels along the path in screen space
        love.graphics.setColor(1, 1, 1, 0.9) -- White text

        for i = pathfinding.pathIndex, #pathfinding.currentPath._nodes do
          local node = pathfinding.currentPath._nodes[i]
          local worldX = (node._x - 1) * tileSize + tileSize / 2
          local worldY = (node._y - 1) * tileSize + tileSize / 2
          local screenX = halfW + (worldX - cameraX) * scale
          local screenY = halfH + (worldY - cameraY) * scale

          -- Only draw if waypoint is on screen
          if screenX >= 0 and screenX <= screenWidth and screenY >= 0 and screenY <= screenHeight then
            -- Draw coordinate text slightly offset from the waypoint
            local coordText = string.format("%d,%d", node._x, node._y)
            love.graphics.print(coordText, screenX + 2, screenY - 10)
          end
        end
      end

      -- Draw target destination even if no path (e.g., direct chase)
      if pathfinding.targetX and pathfinding.targetY then
        local targetScreenX = halfW + (pathfinding.targetX - cameraX) * scale
        local targetScreenY = halfH + (pathfinding.targetY - cameraY) * scale

        -- Only draw if target is on screen
        if targetScreenX >= 0 and targetScreenX <= screenWidth and targetScreenY >= 0 and targetScreenY <= screenHeight then
          love.graphics.setColor(1, 0, 0, 0.8) -- Red
          love.graphics.circle("fill", targetScreenX, targetScreenY, 6)
        end
      end
    end
  end

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
end

---Draws blocked pathfinding tiles in world space
---@param cameraX number Camera X position
---@param cameraY number Camera Y position
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.drawBlockedTiles(cameraX, cameraY, cameraScale)
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

  -- Restore graphics state
  love.graphics.pop()
end

---Draws skeleton state overlays in screen space at skeleton positions
---@param cameraX number Camera X position
---@param cameraY number Camera Y position
---@param cameraScale number Camera scale factor (optional)
---@return nil
function overlayStats.drawSkeletonStateOverlays(cameraX, cameraY, cameraScale)
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
  local screenWidth, screenHeight = love.graphics.getDimensions()
  local halfW, halfH = screenWidth / 2, screenHeight / 2

  -- Query all entities with Position, SpriteRenderer, and StateMachine components
  local entitiesWithSprites = gameScene.ecsWorld:getEntitiesWith({"Position", "SpriteRenderer", "StateMachine"})

  -- Use main font for better readability in screen space
  if overlayFontMain then
    love.graphics.setFont(overlayFontMain)
  end

  -- Draw state overlays for skeleton entities
  for _, entity in ipairs(entitiesWithSprites) do
    if entity:hasTag("Skeleton") then
      local position = entity:getComponent("Position")
      local spriteRenderer = entity:getComponent("SpriteRenderer")
      local stateMachine = entity:getComponent("StateMachine")

      if position and spriteRenderer and stateMachine then
        local currentState = stateMachine:getCurrentState()
        local target = entity.target

        -- Color code the state
        local stateColor = {1, 1, 1, 1} -- Default white

        -- Convert world position to screen position
        local worldX = position.x + spriteRenderer.offsetX + (spriteRenderer.width / 2)
        local worldY = position.y + spriteRenderer.offsetY

        -- Convert to screen coordinates (camera is centered)
        local screenX = halfW + (worldX - cameraX) * scale
        local screenY = halfH + (worldY - cameraY) * scale

        -- Only draw if skeleton is on screen
        if screenX >= 0 and screenX <= screenWidth and screenY >= 0 and screenY <= screenHeight then
          local textY = screenY - 20 -- Above skeleton

          -- Set color and draw state text (can show full state name now)
          love.graphics.setColor(stateColor)
          love.graphics.print(currentState, screenX - 15, textY) -- Full state name

        end
      end
    end
  end

  -- Reset color
  love.graphics.setColor(1, 1, 1, 1)
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
  local font
  if overlayFontMain then
    love.graphics.setFont(overlayFontMain)
    font = overlayFontMain
  else
    font = love.graphics.setNewFont(16)
  end

  if cameraX and cameraY then
    -- Draw gridlines in world space
    overlayStats.drawGridlines(cameraX, cameraY, cameraScale)
    -- Draw blocked pathfinding tiles in world space
    overlayStats.drawBlockedTiles(cameraX, cameraY, cameraScale)
    -- Draw physics colliders in world space
    overlayStats.drawPhysicsColliders(cameraX, cameraY, cameraScale)
    -- Draw sprite outlines in world space
    overlayStats.drawSpriteOutlines(cameraX, cameraY, cameraScale)
    -- Draw pathfinding debug in world space
    overlayStats.drawPathfindingDebug(cameraX, cameraY, cameraScale)
    -- Draw skeleton state overlays in world space
    overlayStats.drawSkeletonStateOverlays(cameraX, cameraY, cameraScale)
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
  love.graphics.rectangle("fill", 10, 10, rectangleWidth, 400)
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

  -- Display collider count using ECS system (both types)
  local pathfindingColliderCount = 0
  local physicsColliderCount = 0
  if cameraX and cameraY then
    local gameState = require("src.core.GameState")
    if gameState and gameState.scenes and gameState.scenes.game and gameState.scenes.game.ecsWorld then
      local entitiesWithPathfindingCollision = gameState.scenes.game.ecsWorld:getEntitiesWith({"PathfindingCollision"})
      local entitiesWithPhysicsCollision = gameState.scenes.game.ecsWorld:getEntitiesWith({"PhysicsCollision"})
      pathfindingColliderCount = #entitiesWithPathfindingCollision
      physicsColliderCount = #entitiesWithPhysicsCollision
    end
  end
  love.graphics.print(string.format("Pathfinding Colliders: %d", pathfindingColliderCount), 20, y)
  y = y + 20
  love.graphics.print(string.format("Physics Colliders: %d", physicsColliderCount), 20, y)
  y = y + 20

  -- Reset color to white
  love.graphics.setColor(1, 1, 1, 1)

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
