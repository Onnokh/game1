local CustomLightRenderer = require("src.utils.CustomLightRenderer")

local initialized = false

local M = {}

function M.init()
  if initialized then return CustomLightRenderer end

  -- Initialize CustomLightRenderer with screen dimensions
  local screenWidth = love.graphics.getWidth()
  local screenHeight = love.graphics.getHeight()
  CustomLightRenderer.init(screenWidth, screenHeight)

  initialized = true
  return CustomLightRenderer
end

function M.get()
  return CustomLightRenderer
end

function M.setAmbientColor(r, g, b, a, duration)
  CustomLightRenderer.setAmbientColor(r, g, b, a, duration)
end

function M.update(dt, camera)
  if not initialized then return end

  CustomLightRenderer.update(dt, camera)
end

function M.cleanup()
  if not initialized then return end

  -- Cleanup CustomLightRenderer
  CustomLightRenderer.cleanup()
  initialized = false
end

return M
