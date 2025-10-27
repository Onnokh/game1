// Light Fragment Shader
// GPU-based lighting implementation for Love2D
// Processes up to 256 lights in a single full-screen pass
// Generates a lightmap (not the final lit scene)

// External textures
extern Image lightData;    // Light positions, radius, intensity (1xN texture)
extern Image lightColor;   // Light colors (1xN texture)

// Uniforms
extern int numLights;
extern vec2 screenSize;
extern vec3 ambientColor;

// Pixel-art stepped falloff function
// Creates discrete brightness rings instead of smooth gradient
float pixelFalloff(float dist, float radius, float steps) {
    // Normalize distance to 0-1 range
    float normalized = clamp(1.0 - dist / radius, 0.0, 1.0);

    // Quantize into discrete steps
    float stepped = floor(normalized * steps) / steps;

    // Ensure full intensity at center
    return stepped;
}

vec4 effect(vec4 color, Image tex, vec2 textureCoords, vec2 screenCoords)
{
    // Start with ambient lighting
    vec3 accumulatedLight = ambientColor;

    // Process each light
    for (int i = 0; i < 256; i++) {
        if (i >= numLights) break;

        // Calculate UV coordinate for this light in the 1D texture
        float u = (float(i) + 0.5) / 256.0;

        // Sample light data (x, y, radius, intensity)
        vec4 ld = Texel(lightData, vec2(u, 0.5));

        // Sample light color (r, g, b, a)
        vec4 lc = Texel(lightColor, vec2(u, 0.5));

        // Unpack light data
        vec2 lightPos = ld.xy * screenSize;  // Denormalize position
        float radius = ld.z * screenSize.x;  // Denormalize radius (using screen width)
        float intensity = ld.w;              // Intensity multiplier

        // Calculate distance from current pixel to light
        float dist = distance(screenCoords, lightPos);

        // Calculate stepped pixel-art falloff (3 brightness rings)
        float falloff = pixelFalloff(dist, radius, 8.0);

        // Accumulate light contribution
        accumulatedLight += lc.rgb * falloff * intensity;
    }

    // Output lightmap (full intensity = white, no light = ambient)
    // This will be multiplied with the scene later
    return vec4(accumulatedLight, 1.0);
}

