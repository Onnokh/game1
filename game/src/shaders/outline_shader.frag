// Outline shader fragment shader
uniform vec3 OutlineColor = vec3(1.0, 1.0, 1.0); // Default white outline
uniform vec2 TextureSize; // Size of the texture being rendered

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Sample the original texture
    vec4 originalColor = Texel(texture, texture_coords);

    // If the pixel is opaque, draw it normally
    if (originalColor.a > 0.5) {
        return originalColor * color;
    }

    // For transparent pixels, check if we should draw outline
    float maxAlpha = 0.0;
    vec2 pixelSize = 1.0 / TextureSize;

    // Sample the 8 surrounding pixels including diagonals
    vec2 offsets[8] = vec2[8](
        vec2(-1.0, -1.0), vec2(0.0, -1.0), vec2(1.0, -1.0),
        vec2(-1.0, 0.0),                    vec2(1.0, 0.0),
        vec2(-1.0, 1.0),  vec2(0.0, 1.0),  vec2(1.0, 1.0)
    );

    for (int i = 0; i < 8; i++) {
        vec2 offset = offsets[i] * pixelSize;
        vec2 sampleCoord = texture_coords + offset;

        // Only sample if within texture bounds
        if (sampleCoord.x >= 0.0 && sampleCoord.x <= 1.0 &&
            sampleCoord.y >= 0.0 && sampleCoord.y <= 1.0) {
            vec4 neighbor = Texel(texture, sampleCoord);
            maxAlpha = max(maxAlpha, neighbor.a);
        }
    }

    // If we found a neighboring opaque pixel, draw the outline
    if (maxAlpha > 0.5) {
        return vec4(OutlineColor, 0.5);
    }

    // Otherwise, return transparent
    return vec4(0.0, 0.0, 0.0, 0.0);
}

