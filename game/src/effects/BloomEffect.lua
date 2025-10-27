---@class BloomEffect
---@field width number
---@field height number
---@field canvases table
---@field thresholdShader love.Shader|nil
---@field blurShader love.Shader|nil
---@field threshold number
---@field strength number
---@field intensity number
local BloomEffect = {}
BloomEffect.__index = BloomEffect

---Create a new BloomEffect instance
---@param width number Canvas width
---@param height number Canvas height
---@return BloomEffect BloomEffect instance
function BloomEffect.new(width, height)
  local self = setmetatable({}, BloomEffect)
  self.width = width
  self.height = height

  -- Create canvases for ping-ponging
  self.canvases = {
    front = love.graphics.newCanvas(width, height),
    back = love.graphics.newCanvas(width, height)
  }

  -- Load shaders from ShaderManager
  local ShaderManager = require("src.core.managers.ShaderManager")
  self.thresholdShader = ShaderManager.getShader("bloom")
  self.blurShader = ShaderManager.getShader("bloom_blur")

  -- Default parameters
  self.threshold = 0.7
  self.strength = 5.0
  self.intensity = 1.0

  return self
end

---Set the brightness threshold for bloom
---@param value number Threshold value (0.0-1.0)
function BloomEffect:setThreshold(value)
  self.threshold = math.max(0.0, math.min(1.0, value))
end

---Set the blur strength/radius (same as setSpread)
---@param value number Strength value (1.0-10.0+)
function BloomEffect:setStrength(value)
  self.strength = math.max(1.0, value)
end

---Set the bloom intensity multiplier
---@param value number Intensity value (0.0-2.0+)
function BloomEffect:setIntensity(value)
  self.intensity = math.max(0.0, value)
end

---Apply bloom effect to the source canvas
---@param sourceCanvas love.Canvas The canvas to process
---@param outputCanvas love.Canvas|nil Optional canvas to render to (nil = screen)
function BloomEffect:apply(sourceCanvas, outputCanvas)
  if not self.thresholdShader or not self.blurShader then
    -- Fallback: just draw the source canvas
    if outputCanvas then
      love.graphics.setCanvas(outputCanvas)
      love.graphics.clear(0, 0, 0, 1)
      love.graphics.draw(sourceCanvas, 0, 0)
      love.graphics.setCanvas()
    else
      love.graphics.clear(0, 0, 0, 1)
      love.graphics.draw(sourceCanvas, 0, 0)
    end
    return
  end

  local front, back = self.canvases.front, self.canvases.back
  local screenW, screenH = self.width, self.height

  -- Pass 1: Extract bright pixels with threshold
  love.graphics.setCanvas(front)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setShader(self.thresholdShader)
  self.thresholdShader:send("min_luma", self.threshold)
  love.graphics.draw(sourceCanvas, 0, 0)

  -- Pass 2: Horizontal blur
  self.blurShader:send("direction", {1.0 / screenW, 0})
  self.blurShader:send("strength", self.strength)
  love.graphics.setCanvas(back)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setShader(self.blurShader)
  love.graphics.draw(front, 0, 0)

  -- Pass 3: Vertical blur
  self.blurShader:send("direction", {0, 1.0 / screenH})
  love.graphics.setCanvas(front)
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.draw(back, 0, 0)

  -- Pass 4: Draw original scene to output canvas
  if outputCanvas then
    love.graphics.setCanvas(outputCanvas)
  else
    love.graphics.setCanvas() -- to screen
  end
  love.graphics.clear(0, 0, 0, 1)
  love.graphics.setShader()
  love.graphics.draw(sourceCanvas, 0, 0)

  -- Pass 5: Add blurred bright pixels with intensity
  love.graphics.setColor(1, 1, 1, self.intensity)
  love.graphics.setBlendMode("add", "premultiplied")
  love.graphics.draw(front, 0, 0)
  love.graphics.setBlendMode("alpha")
  love.graphics.setColor(1, 1, 1, 1)

  -- Reset canvas if we were rendering to output
  if outputCanvas then
    love.graphics.setCanvas()
  end
end

---Clean up resources
function BloomEffect:cleanup()
  if self.canvases then
    if self.canvases.front then
      self.canvases.front:release()
    end
    if self.canvases.back then
      self.canvases.back:release()
    end
  end
end

return BloomEffect

