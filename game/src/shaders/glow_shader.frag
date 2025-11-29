// Glow shader fragment shader for projectiles
uniform float Time;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the original texture
    vec4 originalColor = Texel(texture, texture_coords);

    // If pixel is transparent, check surrounding pixels for glow
    float glowIntensity = 0.0;
    vec2 texelSize = vec2(1.0 / 8.0, 1.0 / 8.0); // Projectile is 8x8 pixels

    // Sample surrounding pixels to create outer glow
    for (float y = -2.0; y <= 2.0; y += 1.0) {
        for (float x = -2.0; x <= 2.0; x += 1.0) {
            vec2 offset = vec2(x, y) * texelSize;
            vec4 sampleColor = Texel(texture, texture_coords + offset);
            glowIntensity += sampleColor.a * (1.0 - length(vec2(x, y)) / 3.0);
        }
    }

    // Create pulsing effect (subtle pulse between 0.8 and 1.2)
    float pulse = 1.0 + sin(Time * 4.0) * 0.2;

    // Glow color (bright cyan/blue to match projectile light)
    vec3 glowColor = vec3(0.4, 0.7, 1.0);

    // Brighten the projectile core
    vec3 brightenedColor = originalColor.rgb + glowColor * 0.3 * originalColor.a;

    // Apply outer glow to transparent areas
    float outerGlow = glowIntensity * 0.15 * pulse * (1.0 - originalColor.a);

    // Combine core brightness with outer glow
    vec3 finalColor = brightenedColor + glowColor * outerGlow * pulse;
    float finalAlpha = originalColor.a + outerGlow;

    return vec4(finalColor, finalAlpha) * color;
}

