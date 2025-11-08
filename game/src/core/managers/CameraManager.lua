local CameraManager = {}

---@class LookAheadController
---@field _deadzone number
---@field _maxAimDistance number
---@field _maxLookAheadDistance number
---@field _smoothSpeed number
---@field _offset { x: number, y: number }

---Create a controller that keeps the camera ahead of the aim direction.
---@param config table|nil
---@return LookAheadController
function CameraManager.createLookAheadController(config)
  local options = config or {}

  local controller = {
    _deadzone = options.deadzone or 0,
    _maxAimDistance = options.maxDistance or options.lookAheadDistance or 100,
    _maxLookAheadDistance = options.lookAheadDistance or options.maxDistance or 100,
    _smoothSpeed = options.smoothSpeed or 10,
    _offset = { x = 0, y = 0 }
  }

  ---Reset the look-ahead offset.
  function controller:reset()
    self._offset.x = 0
    self._offset.y = 0
  end

  ---Advance the look-ahead state and optionally move the camera.
  ---@param camera table|nil
  ---@param playerX number
  ---@param playerY number
  ---@param aimX number|nil
  ---@param aimY number|nil
  ---@param dt number
  ---@return number offsetX
  ---@return number offsetY
  function controller:update(camera, playerX, playerY, aimX, aimY, dt)
    local currentOffsetX = self._offset.x
    local currentOffsetY = self._offset.y

    local adjustedAimX = (aimX or playerX) - currentOffsetX
    local adjustedAimY = (aimY or playerY) - currentOffsetY

    local dx = adjustedAimX - playerX
    local dy = adjustedAimY - playerY
    local distance = math.sqrt(dx * dx + dy * dy)

    local targetOffsetX, targetOffsetY = 0, 0

    if distance > self._deadzone then
      local normalizedX = dx / distance
      local normalizedY = dy / distance
      local clampedDistance = math.min(distance, self._maxAimDistance)
      local distanceBeyondDeadzone = clampedDistance - self._deadzone

      if distanceBeyondDeadzone > 0 and self._maxAimDistance > self._deadzone then
        local t = distanceBeyondDeadzone / (self._maxAimDistance - self._deadzone)
        local lookAheadDistance = self._maxLookAheadDistance * math.min(math.max(t, 0), 1)
        targetOffsetX = normalizedX * lookAheadDistance
        targetOffsetY = normalizedY * lookAheadDistance
      end
    end

    local lerpFactor = math.min((dt or 0) * self._smoothSpeed, 1)
    self._offset.x = currentOffsetX + (targetOffsetX - currentOffsetX) * lerpFactor
    self._offset.y = currentOffsetY + (targetOffsetY - currentOffsetY) * lerpFactor

    if camera and camera.setPosition then
      camera:setPosition(playerX + self._offset.x, playerY + self._offset.y)
    end

    return self._offset.x, self._offset.y
  end

  ---Get the current look-ahead offset.
  ---@return number offsetX
  ---@return number offsetY
  function controller:getOffset()
    return self._offset.x, self._offset.y
  end

  return controller
end

return CameraManager

