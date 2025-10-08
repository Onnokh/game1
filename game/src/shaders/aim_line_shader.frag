uniform vec2 startPos;
uniform vec2 endPos;
uniform vec2 targetPos;
uniform float time;
uniform bool isHit;

uniform float animationSpeed;
uniform float dotRadius;
uniform float dotSpacing;
uniform float targetDotRadius;
uniform float targetCrossThickness;

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

    // Clip at the start and end positions (but allow target marker area)
    if (distAlongLine < 0.0 || (distAlongLine > lineLength && !nearTarget)) {
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
    // But don't draw dots too close to the target marker
    if (distToDotCenter < dotRadius && !nearTarget) {
        // Inside a dot
        return vec4(1.0, 1.0, 1.0, .5);
    }

    // Draw target marker
    if (distToTarget < targetDotRadius) {
          // Draw circle at target
        if (isHit) {
            return vec4(1.0, 0.5, 0.5, 1.0);
        } else {
            return vec4(1.0, 1.0, 1.0, 1.0);
        }
    }

    discard;
}

