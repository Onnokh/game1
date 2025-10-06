// Pure pixel-art "danger border" shader (8x8 blocks, black or transparent)
// Creates a rectangular border of solid 8x8 black pixels with subtle random variation
// No pulsing, no opacity, strictly on/off for pixel-art style

uniform float opacity;        // 0.0 = off, 1.0 = full effect
uniform vec2 resolution;      // Screen resolution
uniform float time;           // Time in seconds

// Simple pseudo-random function
float random(vec2 co) {
    return fract(sin(dot(co.xy, vec2(12.9898, 78.233))) * 43758.5453);
}

vec4 effect(vec4 color, Image tex, vec2 texture_coords, vec2 screen_coords)
{
    // Pixel block size
    float blockSize = 8.0;

    // Quantize to 8x8 pixel grid
    vec2 blockCoords = floor(screen_coords / blockSize) * blockSize;
    vec2 blockCenter = blockCoords + vec2(blockSize * 0.5);

    // Distance to nearest edge (rectangular shape)
    float distToEdgeX = min(blockCenter.x, resolution.x - blockCenter.x);
    float distToEdgeY = min(blockCenter.y, resolution.y - blockCenter.y);
    float distToEdge = min(distToEdgeX, distToEdgeY) + 8.0;

    // Normalize distance
    float maxEdgeDist = min(resolution.x, resolution.y) * 0.5;
    float normalizedDist = distToEdge / maxEdgeDist;

    // Randomize border thickness per block
    float randVal = random(blockCoords / blockSize + floor(time * 12.0));
    float thicknessOffset = mix(-0.01, 0.01, randVal);

    // Rectangular border threshold
    // 0.02–0.1 defines border thickness range
    float border = 1.0 - smoothstep(0.01 + thicknessOffset, 0.1 + thicknessOffset, normalizedDist);

    // Hard pixel cutoff — only on/off
    float pixelOn = step(0.5, border);

    // If pixelOn == 1.0, render red pixel with varying opacity based on edge proximity
    // For the future - Oxygen safe zone blue color (0.4, 0.8, 1.0)
    vec3 redColor = vec3(0.3, 0.1, 0.1); // Very dark red

    if (pixelOn > 0.5) {
        // Check if this block is touching the actual screen edge
        float edgeThreshold = blockSize * 1.5; // Within 1.5 blocks of edge
        float minDistToScreenEdge = min(
            min(blockCenter.x, resolution.x - blockCenter.x),
            min(blockCenter.y, resolution.y - blockCenter.y)
        );

        // Fully opaque at edges, 60% opacity further in
        float baseAlpha = (minDistToScreenEdge < edgeThreshold) ? 1.0 : 0.35;
        // Apply opacity to fade the effect in/out
        float alpha = baseAlpha * opacity;
        return vec4(redColor, alpha);
    } else {
        return vec4(0.0, 0.0, 0.0, 0.0); // Fully transparent
    }
}
