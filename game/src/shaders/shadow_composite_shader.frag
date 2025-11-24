// Shadow composite shader - prevents excessive darkening from overlapping shadows
// The shadow canvas has shadows rendered with alpha blending (additive darkening)
// This shader clamps the darkness to prevent overlapping shadows from getting darker
// than a single shadow would be

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the shadow canvas
    vec4 shadowColor = Texel(texture, texture_coords);
    
    // Calculate brightness (white = 1.0, black = 0.0)
    float brightness = (shadowColor.r + shadowColor.g + shadowColor.b) / 3.0;
    
    // If the area is white (brightness close to 1), there's no shadow
    // Return white so multiply blend doesn't change the scene
    if (brightness > 0.99) {
        return vec4(1.0, 1.0, 1.0, 1.0); // White (no darkening with multiply blend)
    }
    
    // Calculate darkness
    float darkness = 1.0 - brightness;
    
    // Clamp darkness to maximum shadow opacity (e.g., 0.35)
    // This prevents overlapping shadows from exceeding the darkness of a single shadow
    float maxShadowDarkness = 0.35;
    float clampedDarkness = min(darkness, maxShadowDarkness);
    
    // Convert back to brightness for multiply blend
    // We want to darken by clampedDarkness amount
    float targetBrightness = 1.0 - clampedDarkness;
    
    // Return a color that, when multiplied, will darken by the clamped amount
    return vec4(targetBrightness, targetBrightness, targetBrightness, 1.0);
}

