---@class MenuScene
local MenuScene = {}

-- Menu state
local selectedOption = 1
local menuOptions = {"Start Game", "Quit"}
local menuY = 200
local optionHeight = 40

-- Initialize the menu scene
function MenuScene.load()
  selectedOption = 1
end

-- Update the menu scene
function MenuScene.update(dt, gameState)
  -- Menu doesn't need much updating
end

-- Draw the menu scene
function MenuScene.draw(gameState)
  local width = love.graphics.getWidth()
  local height = love.graphics.getHeight()

  -- Draw background
  love.graphics.setColor(0.1, 0.1, 0.2)
  love.graphics.rectangle("fill", 0, 0, width, height)

  -- Draw title
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(love.graphics.newFont(32))
  love.graphics.printf("Pixel Top-Down Game", 0, 100, width, "center")

  -- Draw menu options
  love.graphics.setFont(love.graphics.newFont(24))
  for i, option in ipairs(menuOptions) do
    local y = menuY + (i - 1) * optionHeight

    if i == selectedOption then
      love.graphics.setColor(1, 1, 0) -- Yellow for selected
      love.graphics.printf("> " .. option, 0, y, width, "center")
    else
      love.graphics.setColor(1, 1, 1) -- White for unselected
      love.graphics.printf(option, 0, y, width, "center")
    end
  end

  -- Draw instructions
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.setFont(love.graphics.newFont(16))
  love.graphics.printf("Use arrow keys to navigate, Enter to select", 0, height - 50, width, "center")
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
      -- Start game
      gameState.changeScene("game")
    elseif selectedOption == 2 then
      -- Quit
      love.event.quit()
    end
  end
end

return MenuScene

