uniform vec2 startPos;
uniform vec2 endPos;
uniform vec2 targetPos;
uniform float time;
uniform bool isHit;
uniform float particleFrequency;
uniform float particleSpeed;
uniform float particleStrength;
uniform float targetDotRadius;

vec4 effect(vec4 color, Image texture, vec2 texture_coords, vec2 screen_coords)
{
    // Calculate line direction - always use endPos for direction (raycast/clamped position)
    vec2 lineDir = endPos - startPos;
    float lineLength = length(lineDir);
    vec2 lineNorm = normalize(lineDir);

    // Calculate visual length - extend to targetPos if it's further along the same line (when not hitting)
    // When hitting, always stop at the collision point (lineLength)
    float visualLineLength = lineLength;
    if (!isHit) {
        // Project targetPos onto the line to see how far along it is
        vec2 toTarget = targetPos - startPos;
        float targetDistAlongLine = dot(toTarget, lineNorm);
        // Only extend if targetPos is further along the line than the clamped endPos
        // This allows the beam to visually reach the cursor when not hitting
        if (targetDistAlongLine > lineLength) {
            visualLineLength = targetDistAlongLine;
        }
    }
    // When hitting (isHit == true), visualLineLength stays as lineLength (collision point)

    // Calculate perpendicular distance from the infinite line passing through startPos
    vec2 toPixel = screen_coords - startPos;
    float distAlongLine = dot(toPixel, lineNorm);
    vec2 projection = lineNorm * distAlongLine;
    float distFromLine = length(toPixel - projection);

    // Check distance to collision point (endPos) for hit indicator
    vec2 toEndPos = screen_coords - endPos;
    float distToEndPos = length(toEndPos);
    bool nearTarget = isHit && distToEndPos < targetDotRadius;

    // Clip at the start and end positions (but allow target marker area)
    if (distAlongLine < 0.0 || (distAlongLine > visualLineLength && !nearTarget)) {
        discard;
    }

    // Beam core and glow parameters (thinner beam)
    float beamWidth = 0.5;
    float glowWidth = 4.0;
    float innerEdge = beamWidth * 0.5;
    float outerEdge = glowWidth;

    // Calculate radial mask for beam glow
    float radialMask = 1.0 - smoothstep(innerEdge, outerEdge, distFromLine);

    // Base beam color (red)
    vec3 beamColor = vec3(1.0, 0.2, 0.2);
    float beamIntensity = radialMask;

    // Particle effects - moving streaks along the beam
    float axialDistance = max(distAlongLine, 0.0);

    // Create moving particle streaks
    float streakPos = fract(axialDistance * particleFrequency - time * particleSpeed);
    float streakBand = smoothstep(0.0, 0.25, streakPos) * (1.0 - smoothstep(0.65, 1.0, streakPos));

    // Add swirl effect to particles
    float swirl = sin(axialDistance * particleFrequency * 1.1 + distFromLine * 6.0 - time * particleSpeed * 1.3) * 0.5 + 0.5;
    float particleMask = streakBand * swirl * radialMask;

    // Combine particle contribution
    float particleContribution = particleMask * particleStrength;
    vec3 particleColor = vec3(1.0, 0.4, 0.3); // Brighter red for particles
    vec3 finalColor = beamColor * beamIntensity + particleColor * particleContribution;
    float finalIntensity = max(beamIntensity, particleContribution * 0.6);


    // Draw target marker at collision point (only when hitting something)
    if (nearTarget) {
        // Draw circle at collision point (endPos) when hitting
        return vec4(1.0, 0.5, 0.5, 1.0);
    }

    // Draw beam with particles (only if we're on the line)
    // When hitting: use lineLength (stops at collision)
    // When not hitting: use visualLineLength (extends to cursor)
    float beamEndLength = isHit ? lineLength : visualLineLength;
    if (distAlongLine >= 0.0 && distAlongLine <= beamEndLength && distFromLine < outerEdge) {
        return vec4(finalColor, finalIntensity * 0.45);
    }

    discard;
}

