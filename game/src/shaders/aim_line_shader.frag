uniform vec2 startPos;
uniform vec2 endPos;
uniform vec2 targetPos;
uniform float time;
uniform bool isHit;
uniform float time;
uniform float particleFrequency;
uniform float particleSpeed;
uniform float particleStrength;

uniform float animationSpeed;
uniform float dotRadius;
uniform float dotSpacing;
uniform float targetDotRadius;
uniform float targetCrossThickness;

uniform Image crosshairTexture;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Calculate line direction and length
    vec2 lineDir = endPos - startPos;
    float lineLength = length(lineDir);
    vec2 lineNorm = normalize(lineDir);

    // Calculate perpendicular distance from the infinite line passing through startPos
    vec2 toPixel = screen_coords - startPos;
    float distAlongLine = dot(toPixel, lineNorm);
    vec2 projection = lineNorm * distAlongLine;
    float distFromLine = length(toPixel - projection);

    // Check distance to target marker
    vec2 toTarget = screen_coords - targetPos;
    float distToTarget = length(toTarget);
    float targetArea = max(targetDotRadius, targetCrossThickness);
    bool nearTarget = distToTarget < targetArea;

    // Clip at the start and end positions (but allow target marker area and crosshair)
    if (distAlongLine < 0.0 || (distAlongLine > lineLength && !nearTarget && !(!isHit && distAlongLine < lineLength + 120.0))) {
        discard;
    }

    // Animation offset (continuous flow from player)
    float animationOffset = time * animationSpeed;

    // Calculate position for dot pattern relative to startPos
    float absolutePos = distAlongLine - animationOffset;

    // Find distance to nearest dot center (dots are at multiples of dotSpacing)
    float dotIndex = mod(absolutePos, dotSpacing);
    float nearestDotDist = dotIndex < dotSpacing * 0.5 ? dotIndex : dotSpacing - dotIndex;

    // Calculate distance from pixel to nearest dot center (combining along-line and perpendicular distances)
    float distToDotCenter = sqrt(nearestDotDist * nearestDotDist + distFromLine * distFromLine);

    // Check if we're inside a dot (circular)
    // But don't draw dots too close to the target marker or beyond line length when crosshair is present
    if (distToDotCenter < dotRadius && !nearTarget && !(!isHit && distAlongLine > lineLength)) {
        // Inside a dot
        return vec4(1.0, 1.0, 1.0, .5);
    }

    // Draw target marker (only when hitting something)
    if (distToTarget < targetDotRadius && isHit) {
        // Draw circle at target only when hitting
        return vec4(1.0, 0.5, 0.5, 1.0);
    }

    // Draw crosshair texture at the end of the line when not hitting anything
    if (!isHit && distAlongLine >= lineLength - 120.0 && distAlongLine <= lineLength + 120.0) {
        // Calculate position relative to the end of the line
        vec2 endPoint = startPos + lineNorm * lineLength;
        vec2 toEnd = screen_coords - endPoint;

<<<<<<< Updated upstream
        // Calculate distance from end point
        float distFromEnd = length(toEnd);
=======
    // Foggy particles drifting along the beam
    float axialProgress = clamp(distAlongLine / max(lineLength, 0.0001), 0.0, 1.0);
    float radialMask = 1.0 - smoothstep(innerEdge, outerEdge, distToSegment);

    float axialDistance = max(distAlongLine, 0.0);
    float streakPos = fract(axialDistance * particleFrequency - time * particleSpeed);
    float streakBand = smoothstep(0.0, 0.25, streakPos) * (1.0 - smoothstep(0.65, 1.0, streakPos));

    float swirl = sin(axialDistance * particleFrequency * 1.1 + distToSegment * 6.0 - time * particleSpeed * 1.3) * 0.5 + 0.5;
    float particleMask = streakBand * swirl * radialMask;

    float particleContribution = particleMask * particleStrength;
    vec3 particleColor = beamColor + vec3(0.5, 0.18, 0.18);
    finalColor += particleColor * particleContribution;
    intensity = max(intensity, beamFactor + particleContribution * 0.6);

    if (isHit) {
        float distToEnd = length(screen_coords - endPos);
        float tipRadius = max(beamWidth * 1.5, 4.0);
        float innerEdge = max(tipRadius - 0.5, 0.0);
        float dotFactor = 1.0 - smoothstep(innerEdge, tipRadius, distToEnd);
>>>>>>> Stashed changes

        // Draw crosshair texture within a larger radius to show the full crosshair
        if (distFromEnd < 120.0) {
            // Calculate texture coordinates
            // Map screen coordinates to texture coordinates (0-1 range)
            vec2 crosshairSize = vec2(120.0, 120.0); // Scaled down size
            vec2 textureCoords = (toEnd + crosshairSize * 0.5) / crosshairSize;

            // Clamp texture coordinates to valid range
            textureCoords = clamp(textureCoords, vec2(0.0, 0.0), vec2(1.0, 1.0));

            // Sample the crosshair texture
            vec4 crosshairColor = Texel(crosshairTexture, textureCoords);

            // Only draw if the texture has alpha (not transparent)
            if (crosshairColor.a > 0.1) { // Lower threshold to catch more pixels
                return crosshairColor;
            }
        }
    }

    discard;
}

