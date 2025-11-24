local gameController = require("src.core.GameController")
local sprites = require("src.utils.sprites")
local fonts = require("src.utils.fonts")
local Button = require("src.ui.Button")


---@class MenuScene
local MenuScene = {}

-- Menu state
local buttons = {}
local selectedIndex = 1

-- Initialize the menu scene
function MenuScene.load()
  selectedIndex = 1
  sprites.load()

  local SaveSystem = require("src.utils.SaveSystem")
  local hasSave = SaveSystem.hasSave()

  -- Create buttons
  buttons = {
    Button.new("Continue", function()
      if SaveSystem.hasSave() then
        SaveSystem.load()
        gameController.restartGame() -- This will load the game scene which will check for pending save data
      end
    end),
    Button.new("New Game", function()
      local SaveSystem = require("src.utils.SaveSystem")
      SaveSystem.deleteSave() -- Clear any existing save
      gameController.restartGame()
    end),
    Button.new("Quit", function()
      love.event.quit()
    end)
  }

  -- Disable Continue button if no save exists
  buttons[1].disabled = not hasSave

  -- Start on first non-disabled button
  if buttons[selectedIndex].disabled then
    repeat
      selectedIndex = selectedIndex + 1
      if selectedIndex > #buttons then
        selectedIndex = 1
      end
    until not buttons[selectedIndex].disabled
  end

  buttons[selectedIndex].selected = true
end

-- Update the menu scene
function MenuScene.update(dt, gameState)
  -- Update button hover states
  local mouseX, mouseY = love.mouse.getPosition()
  for i, btn in ipairs(buttons) do
    btn:updateHover(mouseX, mouseY)
  end
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
  love.graphics.push("all")
  love.graphics.setColor(1, 1, 1)
  love.graphics.setFont(fonts.getUIFont(128))

  -- Draw buttons
  local buttonFont = fonts.getUIFont(28)
  local buttonSpacing = 20

  -- Calculate maximum button width to make all buttons same size
  local maxButtonWidth = 0
  for i, btn in ipairs(buttons) do
    local textWidth = buttonFont:getWidth(btn.text)
    local buttonWidth = textWidth + btn.paddingX * 2
    maxButtonWidth = math.max(maxButtonWidth, buttonWidth) + 80
  end

  -- Calculate total height of all buttons (including spacing)
  local totalButtonHeight = 0
  for i, btn in ipairs(buttons) do
    local textHeight = buttonFont:getHeight()
    local buttonHeight = textHeight + btn.paddingY * 2
    totalButtonHeight = totalButtonHeight + buttonHeight
    if i < #buttons then
      totalButtonHeight = totalButtonHeight + buttonSpacing
    end
  end

  -- Center buttons horizontally and vertically
  local buttonX = (width - maxButtonWidth) / 2
  local buttonY = (height - totalButtonHeight) / 2 + 100

  -- Draw all buttons with the same width
  local currentY = buttonY
  for i, btn in ipairs(buttons) do
    btn:updateBounds(buttonX, currentY, buttonFont)
    btn.width = maxButtonWidth -- Override to use max width
    btn:draw(buttonFont)
    currentY = currentY + btn.height + buttonSpacing
  end

  -- Draw instructions
  love.graphics.setColor(0.7, 0.7, 0.7)
  love.graphics.setFont(fonts.getUIFont(16))
  love.graphics.printf("Use arrow keys to navigate, Enter to select", marginX, height - 50, contentWidth, "left")

  love.graphics.pop()
end

-- Handle key press events
function MenuScene.handleKeyPressed(key, gameState)
  if key == "up" or key == "w" then
    buttons[selectedIndex].selected = false
    -- Skip disabled buttons
    repeat
      selectedIndex = selectedIndex - 1
      if selectedIndex < 1 then
        selectedIndex = #buttons
      end
    until not buttons[selectedIndex].disabled
    buttons[selectedIndex].selected = true
  elseif key == "down" or key == "s" then
    buttons[selectedIndex].selected = false
    -- Skip disabled buttons
    repeat
      selectedIndex = selectedIndex + 1
      if selectedIndex > #buttons then
        selectedIndex = 1
      end
    until not buttons[selectedIndex].disabled
    buttons[selectedIndex].selected = true
  elseif key == "return" or key == "space" then
    buttons[selectedIndex]:activate()
  end
end

-- Handle mouse press
function MenuScene.mousepressed(x, y, button, gameState)
  if button == 1 then
    for i, btn in ipairs(buttons) do
      if btn:contains(x, y) then
        btn:setPressed(true)
        return true
      end
    end
  end
  return false
end

-- Handle mouse release
function MenuScene.mousereleased(x, y, button, gameState)
  if button == 1 then
    for i, btn in ipairs(buttons) do
      btn:setPressed(false)
      if btn:handleClick(x, y) then
        return true
      end
    end
  end
  return false
end

-- Cleanup the menu scene when switching away
function MenuScene.cleanup()
  -- Reset state
  selectedIndex = 1
  buttons = {}
end

return MenuScene

