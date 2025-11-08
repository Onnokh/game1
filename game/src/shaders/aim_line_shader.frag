// Solid laser beam fragment shader with soft inner core and glow falloff.
uniform vec2 startPos;
uniform vec2 endPos;
uniform vec3 beamColor;
uniform float beamWidth;
uniform float glowWidth;
uniform float glowFalloff;
uniform float softEdge;
uniform bool isHit;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    vec2 lineDir = endPos - startPos;
    float lineLength = length(lineDir);
    if (lineLength < 0.001) {
        discard;
    }
    vec2 lineNorm = normalize(lineDir);

    vec2 toPixel = screen_coords - startPos;
    float distAlongLine = dot(toPixel, lineNorm);
    float extendedLength = lineLength + glowWidth;
    if (distAlongLine < -glowWidth || distAlongLine > extendedLength) {
        discard;
    }

    float t = clamp(distAlongLine / lineLength, 0.0, 1.0);
    vec2 closestPoint = startPos + lineDir * t;
    float distToSegment = length(screen_coords - closestPoint);

    float halfWidth = beamWidth * 0.5;
    float innerEdge = halfWidth - softEdge;
    float outerEdge = halfWidth + softEdge;

    float beamFactor = 1.0 - smoothstep(innerEdge, outerEdge, distToSegment);

    float glowFactor = 0.0;
    if (glowWidth > halfWidth) {
        float glowRadius = glowWidth - halfWidth;
        float glowDist = distToSegment - halfWidth;
        float normalizedGlow = 1.0 - clamp(glowDist / max(glowRadius, 0.0001), 0.0, 1.0);
        glowFactor = pow(normalizedGlow, glowFalloff);
    }

    float intensity = max(beamFactor, glowFactor * 0.75);

    if (intensity <= 0.0) {
        discard;
    }

    vec3 glowColor = mix(beamColor, vec3(1.0, 0.3, 0.3), 0.35);
    vec3 finalColor = mix(glowColor, beamColor, beamFactor);

    if (isHit) {
        float distToEnd = length(screen_coords - endPos);
        float tipRadius = max(beamWidth * 1.5, 4.0);
        float innerEdge = max(tipRadius - 0.5, 0.0);
        float dotFactor = 1.0 - smoothstep(innerEdge, tipRadius, distToEnd);

        vec3 highlightColor = beamColor + vec3(0.4, 0.15, 0.15);
        finalColor = mix(finalColor, highlightColor, dotFactor);
        intensity = max(intensity, dotFactor);
    }

    return vec4(finalColor, intensity);
}

