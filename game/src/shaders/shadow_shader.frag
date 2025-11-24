// Shadow shader fragment shader
// Tints sprite black with configurable opacity
uniform float shadowAlpha = 0.35; // Shadow opacity

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the original texture
    vec4 originalColor = Texel(texture, texture_coords);
    
    // If pixel is transparent, return transparent
    if (originalColor.a < 0.01) {
        return vec4(0.0, 0.0, 0.0, 0.0);
    }
    
    // Tint sprite black with shadow opacity
    // Multiply original alpha by shadowAlpha for final opacity
    return vec4(0.0, 0.0, 0.0, originalColor.a * shadowAlpha);
}

