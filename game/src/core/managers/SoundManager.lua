---@class SoundManager
---Global sound manager for playing sound effects and music
local SoundManager = {}

-- Sound effect storage
local sounds = {}
local music = {}

-- Volume settings
local sfxVolume = 1.0
local musicVolume = 0.7

---Initialize the sound manager and load all sounds
function SoundManager.load()
  print("SoundManager: Loading sounds...")

  -- Load sound effects
  SoundManager.loadSound("coin", "resources/sounds/coin2.mp3", "static")
  SoundManager.loadSound("gunshot", "resources/sounds/shot1.mp3", "static")
  SoundManager.loadSound("running", "resources/sounds/running.mp3", "static")
  SoundManager.loadSound("dash", "resources/sounds/dash2.mp3", "static")
  SoundManager.loadSound("upgrade_selected", "resources/sounds/upgrade_selected.mp3", "static")
  SoundManager.loadSound("lightningbolt", "resources/sounds/lightningbolt.mp3", "static")
  SoundManager.loadSound("flameshock", "resources/sounds/flameshock.mp3", "static")

  print("SoundManager: Sounds loaded successfully")
end

---Load a sound file
---@param name string The name to reference this sound by
---@param path string The path to the sound file
---@param sourceType string "static" for short sounds, "stream" for long sounds/music
function SoundManager.loadSound(name, path, sourceType)
  sourceType = sourceType or "static"

  local success, sound = pcall(function()
    return love.audio.newSource(path, sourceType)
  end)

  if success then
    sounds[name] = sound
    print("SoundManager: Loaded sound '" .. name .. "' from " .. path)
  else
    print("SoundManager: Failed to load sound '" .. name .. "' from " .. path .. ": " .. tostring(sound))
  end
end

---Play a sound effect
---@param name string The name of the sound to play
---@param volume number|nil Optional volume override (0.0 to 1.0)
---@param pitch number|nil Optional pitch (default 1.0)
function SoundManager.play(name, volume, pitch)
  local sound = sounds[name]
  if not sound then
    print("SoundManager: Sound '" .. name .. "' not found")
    return
  end

  -- Clone the sound so we can play multiple instances
  local instance = sound:clone()

  -- Set volume
  local finalVolume = (volume or 1.0) * sfxVolume
  instance:setVolume(finalVolume)

  -- Set pitch if provided
  if pitch then
    instance:setPitch(pitch)
  end

  -- Play the sound
  instance:play()
end

---Play a looping sound effect
---@param name string The name of the sound to play
---@param volume number|nil Optional volume override (0.0 to 1.0)
---@param pitch number|nil Optional pitch (default 1.0)
---@return table|nil The sound instance for stopping later
function SoundManager.playLooping(name, volume, pitch)
  local sound = sounds[name]
  if not sound then
    print("SoundManager: Sound '" .. name .. "' not found")
    return nil
  end

  -- Clone the sound so we can play multiple instances
  local instance = sound:clone()

  -- Set volume
  local finalVolume = (volume or 1.0) * sfxVolume
  instance:setVolume(finalVolume)

  -- Set pitch if provided
  if pitch then
    instance:setPitch(pitch)
  end

  -- Set looping
  instance:setLooping(true)

  -- Play the sound
  instance:play()

  return instance
end

---Play music (replaces currently playing music)
---@param name string The name of the music to play
---@param loop boolean Whether to loop the music
---@param volume number|nil Optional volume override (0.0 to 1.0)
function SoundManager.playMusic(name, loop, volume)
  -- Stop current music if playing
  SoundManager.stopMusic()

  local sound = sounds[name]
  if not sound then
    print("SoundManager: Music '" .. name .. "' not found")
    return
  end

  -- Set volume
  local finalVolume = (volume or 1.0) * musicVolume
  sound:setVolume(finalVolume)

  -- Set looping
  sound:setLooping(loop or false)

  -- Play the music
  sound:play()

  music.current = sound
end

---Stop currently playing music
function SoundManager.stopMusic()
  if music.current then
    music.current:stop()
    music.current = nil
  end
end

---Set the global sound effects volume
---@param volume number Volume level (0.0 to 1.0)
function SoundManager.setSFXVolume(volume)
  sfxVolume = math.max(0, math.min(1, volume))
end

---Set the global music volume
---@param volume number Volume level (0.0 to 1.0)
function SoundManager.setMusicVolume(volume)
  musicVolume = math.max(0, math.min(1, volume))
  if music.current then
    music.current:setVolume(musicVolume)
  end
end

---Get the current SFX volume
---@return number The current SFX volume (0.0 to 1.0)
function SoundManager.getSFXVolume()
  return sfxVolume
end

---Get the current music volume
---@return number The current music volume (0.0 to 1.0)
function SoundManager.getMusicVolume()
  return musicVolume
end

---Stop all sounds (useful for cleanup)
function SoundManager.stopAll()
  love.audio.stop()
  music.current = nil
end

return SoundManager

