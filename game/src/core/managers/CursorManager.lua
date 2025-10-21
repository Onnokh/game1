local CursorManager = {}
local EventBus = require("src.utils.EventBus")

-- Cursor storage
local cursors = {
  game = nil,    -- crosshair001.png for game scene
  menu = nil     -- crosshair003.png for menu scene
}

---Load all cursor images
function CursorManager.load()
  -- Load crosshair cursors for different scenes
  local cursorPaths = {
    game = "resources/ui/crosshair001.png",
    menu = "resources/ui/crosshair003.png"
  }

  for sceneName, path in pairs(cursorPaths) do
    local cursorSuccess, cursorResult = pcall(function()
      -- Load ImageData directly from file
      local imageData = love.image.newImageData(path)

      -- Scale to 75% of original size
      local originalWidth = imageData:getWidth()
      local originalHeight = imageData:getHeight()
      local scaledWidth = math.floor(originalWidth * 0.75)
      local scaledHeight = math.floor(originalHeight * 0.75)

      -- Create scaled ImageData
      local scaledImageData = love.image.newImageData(scaledWidth, scaledHeight)

      -- Scale the image data (simple nearest neighbor scaling for 75% size)
      local scaleFactor = originalWidth / scaledWidth
      for y = 0, scaledHeight - 1 do
        for x = 0, scaledWidth - 1 do
          local sourceX = math.floor(x * scaleFactor)
          local sourceY = math.floor(y * scaleFactor)
          -- Clamp to image bounds
          sourceX = math.min(sourceX, originalWidth - 1)
          sourceY = math.min(sourceY, originalHeight - 1)
          local r, g, b, a = imageData:getPixel(sourceX, sourceY)
          scaledImageData:setPixel(x, y, r, g, b, a)
        end
      end

      -- Create cursor centered at the middle of the scaled crosshair
      return love.mouse.newCursor(scaledImageData, scaledWidth / 2, scaledHeight / 2)
    end)

    if cursorSuccess then
      cursors[sceneName] = cursorResult
      print("Cursor loaded for", sceneName, ":", path, "(scaled to 75% size)")
    else
      print("Failed to load cursor for", sceneName, ":", cursorResult)
    end
  end

  -- Set default cursor (will be changed when scenes load)
  if cursors.game then
    love.mouse.setCursor(cursors.game)
  end

  -- Subscribe to game state events
  EventBus.subscribe("showPauseMenu", function(data)
    CursorManager.setCursorForScene("menu")
  end)

  EventBus.subscribe("hidePauseMenu", function(data)
    local gameState = require("src.core.GameState")
    CursorManager.setCursorForScene(gameState.currentScene)
  end)

  EventBus.subscribe("sceneChanged", function(data)
    CursorManager.setCursorForScene(data.sceneName)
  end)

  -- Subscribe to shop and crystal events
  EventBus.subscribe("shopEntered", function(data)
    CursorManager.setCursorForScene("menu")
  end)

  EventBus.subscribe("shopExited", function(data)
    CursorManager.setCursorForScene("game")
  end)

  EventBus.subscribe("crystalOpened", function(data)
    CursorManager.setCursorForScene("menu")
  end)

  EventBus.subscribe("crystalClosed", function(data)
    CursorManager.setCursorForScene("game")
  end)
end

---Set cursor based on scene and game state
---@param sceneName string The current scene name
function CursorManager.setCursorForScene(sceneName)
  -- Use menu cursor for pause/game over or menu scene
  if sceneName == "menu" then
    love.mouse.setVisible(true)
    if cursors.menu then
      love.mouse.setCursor(cursors.menu)
      print("Cursor switched to menu (", sceneName, ")")
    end
  elseif sceneName == "game" then
    -- Use game cursor for normal gameplay (crosshair will be drawn in shader)
    if cursors.game then
      love.mouse.setCursor(cursors.game)
      print("Cursor set for gameplay")
    end
  else
    -- Default to menu cursor for other scenes
    love.mouse.setVisible(true)
    if cursors.menu then
      love.mouse.setCursor(cursors.menu)
      print("Cursor switched to menu (default for scene:", sceneName, ")")
    end
  end
end

---Update cursor based on current state (can be called anytime)
function CursorManager.updateCursor()
  local gameState = require("src.core.GameState")
  CursorManager.setCursorForScene(gameState.currentScene)
end

return CursorManager
