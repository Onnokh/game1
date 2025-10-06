local gameController = require("src.core.GameController")
local sprites = require("src.utils.sprites")
local fonts = require("src.utils.fonts")


---@class MenuScene
local MenuScene = {}

-- Menu state
local selectedOption = 1
local menuOptions = {"Start Game", "Quit"}
local menuY = 300
local optionHeight = 56

-- Initialize the menu scene
function MenuScene.load()
  selectedOption = 1
  sprites.load()
end

-- Update the menu scene
function MenuScene.update(dt, gameState)
  -- Menu doesn't need much updating
end

-- Draw the menu scene
function MenuScene.draw(gameState)
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()
  local marginX = 80
  local contentWidth = width - marginX * 2
  local titleY = 120

  -- Draw background
  sprites.drawMenuBackground()

  -- Draw title
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fonts.getUIFont(128))
  love.graphics.printf("Outpost", marginX, titleY, contentWidth, "left")

  -- Draw menu options
  love.graphics.setFont(fonts.getUIFont(36))
  for i, option in ipairs(menuOptions) do
    local y = menuY + (i - 1) * optionHeight

    if i == selectedOption then
      love.graphics.setColor(1, 1, 0) -- Yellow for selected
      love.graphics.printf("> " .. option, marginX, y, contentWidth, "left")
    else
      love.graphics.setColor(1, 1, 1) -- White for unselected
      love.graphics.printf(option, marginX, y, contentWidth, "left")
    end
  end

  -- Draw instructions
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.setFont(fonts.getUIFont(16))
  love.graphics.printf("Use arrow keys to navigate, Enter to select", marginX, height - 50, contentWidth, "left")
end

-- Handle key press events
function MenuScene.handleKeyPressed(key, gameState)
  if key == "up" or key == "w" then
    selectedOption = selectedOption - 1
    if selectedOption < 1 then
      selectedOption = #menuOptions
    end
  elseif key == "down" or key == "s" then
    selectedOption = selectedOption + 1
    if selectedOption > #menuOptions then
      selectedOption = 1
    end
  elseif key == "return" or key == "space" then
    if selectedOption == 1 then
      -- Start game - ensure we're not paused
      gameController.resetPauseState()
      gameState.changeScene("game")
    elseif selectedOption == 2 then
      -- Quit
      love.event.quit()
    end
  end
end

-- Cleanup the menu scene when switching away
function MenuScene.cleanup()
  -- Menu scene doesn't need much cleanup, just reset state
  selectedOption = 1
end

return MenuScene

