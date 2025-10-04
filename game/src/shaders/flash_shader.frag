// Flash shader fragment shader
uniform float FlashIntensity;
uniform float Time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the original texture
    vec4 originalColor = Texel(texture, texture_coords);

    // Create a pulsing white flash effect
    float pulse = sin(Time * 20.0) * 0.5 + 0.5; // 0 to 1 pulsing
    float flash = FlashIntensity * pulse;

    // Mix original color with white based on flash intensity
    vec3 flashColor = mix(originalColor.rgb, vec3(1.0, 1.0, 1.0), flash);

    // Output the final color
    return vec4(flashColor, originalColor.a);
}
