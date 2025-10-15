---@class NoiseGenerator
local NoiseGenerator = {}

-- Simple tileable noise using sine waves (guaranteed seamless)
---@param width number Width of the texture
---@param height number Height of the texture
---@param scale number Noise scale factor
---@return love.ImageData
function NoiseGenerator.generatePerlinNoise(width, height, scale)
    scale = scale or 1.0

    -- Create ImageData for the noise texture
    local imageData = love.image.newImageData(width, height)

    -- Generate tileable noise using multiple sine wave layers
    for y = 0, height - 1 do
        for x = 0, width - 1 do
            local fx = (x / width) * scale
            local fy = (y / height) * scale

            -- Multiple sine wave layers for natural-looking noise
            local noise = 0
            noise = noise + math.sin(fx * 2 * math.pi) * 0.5
            noise = noise + math.sin(fy * 2 * math.pi) * 0.5
            noise = noise + math.sin(fx * 4 * math.pi) * 0.25
            noise = noise + math.sin(fy * 4 * math.pi) * 0.25
            noise = noise + math.sin(fx * 8 * math.pi) * 0.125
            noise = noise + math.sin(fy * 8 * math.pi) * 0.125
            noise = noise + math.sin((fx + fy) * 3 * math.pi) * 0.3
            noise = noise + math.sin((fx - fy) * 5 * math.pi) * 0.2

            -- Normalize to 0-1 range
            noise = (noise + 2) / 4

            -- Set pixel in ImageData (grayscale)
            imageData:setPixel(x, y, noise, noise, noise, 1)
        end
    end

    return imageData
end

-- Generate and cache a wind noise texture for foliage sway
local windNoiseTexture = nil

---@return love.Image
function NoiseGenerator.getWindNoiseTexture()
    if not windNoiseTexture then
        print("Generating wind noise texture...")
        local imageData = NoiseGenerator.generatePerlinNoise(256, 256, 4.0)
        windNoiseTexture = love.graphics.newImage(imageData)
        windNoiseTexture:setWrap("repeat", "repeat")
        windNoiseTexture:setFilter("linear", "linear")
        print("Wind noise texture generated successfully")
    end

    return windNoiseTexture
end

-- Clear the cached noise texture (useful for regeneration)
function NoiseGenerator.clearCache()
    windNoiseTexture = nil
    print("Wind noise texture cache cleared")
end

return NoiseGenerator
