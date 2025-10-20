---@class GameTimeManager
---Manages game time tracking for wave spawning and other time-based features
local GameTimeManager = {}

-- Internal state
GameTimeManager.elapsedTime = 0
GameTimeManager.paused = false

---Initialize the game time manager
function GameTimeManager.init()
    GameTimeManager.elapsedTime = 0
    GameTimeManager.paused = false
    print("[GameTimeManager] Initialized")
end

---Update the game time
---@param dt number Delta time in seconds
function GameTimeManager.update(dt)
    if not GameTimeManager.paused then
        GameTimeManager.elapsedTime = GameTimeManager.elapsedTime + dt
    end
end

---Get the current elapsed game time
---@return number Elapsed time in seconds
function GameTimeManager.getTime()
    return GameTimeManager.elapsedTime
end

---Reset the game time to zero
function GameTimeManager.reset()
    GameTimeManager.elapsedTime = 0
    print("[GameTimeManager] Reset to 0")
end

---Pause the game time
function GameTimeManager.pause()
    GameTimeManager.paused = true
end

---Resume the game time
function GameTimeManager.resume()
    GameTimeManager.paused = false
end

---Check if the game time is paused
---@return boolean True if paused
function GameTimeManager.isPaused()
    return GameTimeManager.paused
end

---Format time as MM:SS or HH:MM:SS
---@param time number Time in seconds
---@return string Formatted time string
function GameTimeManager.formatTime(time)
    local hours = math.floor(time / 3600)
    local minutes = math.floor((time % 3600) / 60)
    local seconds = math.floor(time % 60)

    if hours > 0 then
        return string.format("%d:%02d:%02d", hours, minutes, seconds)
    else
        return string.format("%d:%02d", minutes, seconds)
    end
end

---Add time to the elapsed time (for debug purposes)
---@param seconds number Seconds to add to the elapsed time
function GameTimeManager.addTime(seconds)
    GameTimeManager.elapsedTime = GameTimeManager.elapsedTime + seconds
    print(string.format("[GameTimeManager] Added %d seconds. New time: %s", seconds, GameTimeManager.formatTime(GameTimeManager.elapsedTime)))
end

---Get the current wave number based on elapsed time
---@return number Current wave number (1-based)
function GameTimeManager.getCurrentWave()
    local currentTime = GameTimeManager.getTime()

    -- Import waves definition
    local waves = require("src.definitions.enemy_waves")

    -- Find the current wave based on time
    for i, wave in ipairs(waves) do
        if currentTime >= wave.time and currentTime < wave.time + wave.duration then
            return i
        end
    end

    -- If no wave is active, return 0 (no wave)
    return 0
end

return GameTimeManager
