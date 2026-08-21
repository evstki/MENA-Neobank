#include <metal_stdlib>
using namespace metal;

static float backgroundHash(float2 point) {
    float3 sample = fract(float3(point.x, point.y, point.x) * 0.1031);
    sample += dot(sample, sample.yzx + 33.33);
    return fract((sample.x + sample.y) * sample.z);
}

static float backgroundNoise(float2 point) {
    float2 cell = floor(point);
    float2 local = fract(point);
    float2 blend = local * local * (3.0 - 2.0 * local);

    float bottomLeft = backgroundHash(cell);
    float bottomRight = backgroundHash(cell + float2(1.0, 0.0));
    float topLeft = backgroundHash(cell + float2(0.0, 1.0));
    float topRight = backgroundHash(cell + float2(1.0, 1.0));

    return mix(
        mix(bottomLeft, bottomRight, blend.x),
        mix(topLeft, topRight, blend.x),
        blend.y
    );
}

static float backgroundFBM(float2 point) {
    float value = 0.0;
    float amplitude = 0.5;
    float2 offset = float2(19.1, 7.7);

    for (int octave = 0; octave < 4; octave++) {
        value += amplitude * backgroundNoise(point);
        point = point * 2.03 + offset;
        amplitude *= 0.5;
    }

    return value;
}

static float smoothRandom(float coordinate, float seed) {
    return backgroundNoise(float2(coordinate, seed)) * 2.0 - 1.0;
}

static float2 loopedSourceMotion(float lightTime, float speed, float seed) {
    // Integer harmonics make this irregular-looking path close perfectly after
    // one revolution of the base angle.
    float angle = lightTime * speed + seed;
    float horizontal = sin(angle);
    horizontal += sin(angle * 2.0 + seed * 1.37) * 0.34;
    horizontal += sin(angle * 3.0 - seed * 0.71) * 0.16;

    float vertical = cos(angle + seed * 0.23);
    vertical += cos(angle * 2.0 - seed * 1.11) * 0.27;
    vertical += cos(angle * 3.0 + seed * 0.53) * 0.12;

    return float2(horizontal / 1.50, vertical / 1.39);
}

static float3 rotateSpectrumHue(float3 color, float angle) {
    // Rotate around the neutral grey axis. Small angles preserve the original
    // dispersion palette while giving every bunch its own evolving tint.
    const float3 greyAxis = float3(0.577350269);
    float sine = sin(angle);
    float cosine = cos(angle);
    float3 rotated = color * cosine;
    rotated += cross(greyAxis, color) * sine;
    rotated += greyAxis * dot(greyAxis, color) * (1.0 - cosine);
    return clamp(rotated, 0.0, 1.0);
}

static float spectralLightRay(
    float2 unitPosition,
    float2 source,
    float slope,
    float dispersion,
    float lightTime,
    float phase
) {
    float depth = max(unitPosition.y - source.y, 0.0);
    float movingSlope = slope + sin(lightTime * 0.42 + phase) * 0.026;
    float center = source.x + depth * (movingSlope + dispersion * 0.135);
    center += sin(lightTime * 0.63 + phase + depth * 2.4)
        * (0.004 + depth * 0.012);

    // The beam starts tightly focused and opens as it travels down the screen.
    // Doubling the Gaussian spread keeps each ray soft beneath the smoke layer.
    float width = (0.010 + depth * 0.024) * 2.0;
    float distanceToRay = abs(unitPosition.x - center);
    float core = exp(-pow(distanceToRay / width, 2.0));
    float feather = exp(-pow(distanceToRay / (width * 2.8), 2.0)) * 0.22;

    float verticalFade = smoothstep(source.y - 0.02, source.y + 0.06, unitPosition.y)
        * (1.0 - smoothstep(0.58, 1.08, depth));
    float rayTexture = 0.74 + backgroundNoise(
        float2(unitPosition.x * 7.0 - lightTime * 0.08, depth * 4.8 + phase)
    ) * 0.36;

    return (core + feather) * verticalFade * rayTexture;
}

static float spectralRayOpacity(float lightTime, float phase) {
    float primarySpeed = 0.50 + fract(phase * 0.137) * 0.26;
    float secondarySpeed = 0.22 + fract(phase * 0.271) * 0.10;

    return clamp(
        0.58 + sin(lightTime * primarySpeed + phase) * 0.28
            + sin(lightTime * secondarySpeed + phase * 1.71) * 0.12,
        0.18,
        1.0
    );
}

static float rayBundleDominance(float dominanceAngle, float targetAngle) {
    float presence = 0.5 + 0.5 * cos(dominanceAngle - targetAngle);

    // A narrow lobe preserves a clear lead bunch while keeping every secondary
    // at no less than one-third of the primary opacity.
    return 0.3333333 + pow(presence, 5.0) * 0.6666667;
}

static float longitudinalHueFlow(float depth, float lightTime, float phase) {
    // Broad noise gives the whole bundle a coherent vertical color drift. The
    // slower wave keeps the transition alive without forming hard color bands.
    float noise = smoothRandom(
        depth * 2.15 - lightTime * 0.055 + phase * 0.41,
        211.3 + phase * 2.17
    );
    float wave = sin(
        depth * (4.4 + fract(phase * 0.37) * 1.2)
            - lightTime * 0.16
            + phase * 1.31
    );

    return noise * 0.20 + wave * 0.09;
}

static float4 spectralRayBundle(
    float2 unitPosition,
    float2 source,
    float slope,
    float lightTime,
    float phase,
    float hueShift
) {
    float rayOne = spectralLightRay(
        unitPosition, source, slope, -1.00, lightTime, phase + 0.10
    ) * spectralRayOpacity(lightTime, phase + 0.20);
    float rayTwo = spectralLightRay(
        unitPosition, source, slope, -0.34, lightTime, phase + 0.76
    ) * spectralRayOpacity(lightTime, phase + 1.90);
    float rayThree = spectralLightRay(
        unitPosition, source, slope, 0.34, lightTime, phase + 1.40
    ) * spectralRayOpacity(lightTime, phase + 3.50);
    float rayFour = spectralLightRay(
        unitPosition, source, slope, 1.00, lightTime, phase + 2.06
    ) * spectralRayOpacity(lightTime, phase + 5.20);

    float depth = max(unitPosition.y - source.y, 0.0);
    float dispersionAmount = smoothstep(0.025, 0.26, depth);
    float verticalHue = longitudinalHueFlow(depth, lightTime, phase);
    float hueOne = hueShift + verticalHue
        + sin(depth * 6.7 - lightTime * 0.11 + phase + 0.20) * 0.045;
    float hueTwo = hueShift + verticalHue
        + sin(depth * 6.1 - lightTime * 0.13 + phase + 1.60) * 0.045;
    float hueThree = hueShift + verticalHue
        + sin(depth * 7.2 - lightTime * 0.10 + phase + 3.10) * 0.045;
    float hueFour = hueShift + verticalHue
        + sin(depth * 6.4 - lightTime * 0.12 + phase + 4.70) * 0.045;
    float3 sourceWhite = float3(1.0, 0.985, 0.96);
    float3 colorOne = mix(
        sourceWhite,
        rotateSpectrumHue(float3(1.00, 0.24, 0.10), hueOne),
        dispersionAmount
    );
    float3 colorTwo = mix(
        sourceWhite,
        rotateSpectrumHue(float3(0.78, 1.00, 0.25), hueTwo),
        dispersionAmount
    );
    float3 colorThree = mix(
        sourceWhite,
        rotateSpectrumHue(float3(0.12, 0.70, 1.00), hueThree),
        dispersionAmount
    );
    float3 colorFour = mix(
        sourceWhite,
        rotateSpectrumHue(float3(0.72, 0.28, 1.00), hueFour),
        dispersionAmount
    );

    float3 light = colorOne * rayOne;
    light += colorTwo * rayTwo;
    light += colorThree * rayThree;
    light += colorFour * rayFour;

    return float4(light, rayOne + rayTwo + rayThree + rayFour);
}

static float spectralSourceGlow(float2 unitPosition, float2 source) {
    float2 sourceDelta = (unitPosition - source) * float2(1.0, 1.65);
    return exp(-dot(sourceDelta, sourceDelta) * 28.0)
        * (1.0 - smoothstep(0.30, 0.76, unitPosition.y));
}

static float dustLayer(
    float2 position,
    float time,
    float cellSize,
    float seed,
    float minimumHash
) {
    float2 cell = floor(position / cellSize);
    float visibilityHash = backgroundHash(cell + float2(seed, seed * 1.73));
    float isVisible = step(minimumHash, visibilityHash);

    float2 randomPosition = float2(
        backgroundHash(cell + float2(seed * 2.1, 17.3)),
        backgroundHash(cell + float2(41.7, seed * 3.4))
    );
    float phase = backgroundHash(cell + float2(seed * 5.7, 63.1)) * 6.2831853;
    float2 particlePosition = (cell + 0.12 + randomPosition * 0.76) * cellSize;

    // Tiny independent drifts make the particles feel suspended rather than
    // attached to the procedural grid.
    particlePosition.x += sin(time * 0.16 + phase) * cellSize * 0.055;
    particlePosition.y += cos(time * 0.11 + phase * 1.37) * cellSize * 0.035;

    float particleSize = mix(
        0.55,
        1.35,
        backgroundHash(cell + float2(seed * 7.9, 91.2))
    );
    float distanceToParticle = length(position - particlePosition);
    float particle = 1.0 - smoothstep(
        particleSize * 0.28,
        particleSize + 1.15,
        distanceToParticle
    );
    float twinkle = 0.55 + 0.45 * sin(time * 0.54 + phase);

    return particle * isVisible * twinkle;
}

[[ stitchable ]] half4 animatedBlurBackground(
    float2 position,
    float2 size,
    float time,
    float motionAmount,
    half4 accentColor,
    float darkMode
) {
    float2 safeSize = max(size, float2(1.0));
    float2 unitPosition = position / safeSize;
    float aspectRatio = safeSize.x / safeSize.y;
    float2 point = (unitPosition - 0.5) * float2(aspectRatio, 1.0);
    float animationTime = time * 0.16 * motionAmount;
    float lightTime = time * 0.24 * motionAmount;

    float2 warp = float2(
        backgroundFBM(
            point * 1.42
            + float2(animationTime * 0.72, -animationTime * 0.36)
        ),
        backgroundFBM(
            point * 1.42
            + float2(5.2 - animationTime * 0.28, 1.7 + animationTime * 0.52)
        )
    );

    float2 warpedPoint = point + (warp - 0.48) * 0.76;
    warpedPoint.y += sin(warpedPoint.x * 3.2 + animationTime * 1.7) * 0.11;
    warpedPoint.x += sin(warpedPoint.y * 2.8 - animationTime * 1.4) * 0.08;

    float cloud = backgroundFBM(
        warpedPoint * 2.15
        + float2(-animationTime * 0.24, animationTime * 0.18)
    );

    float wave = 0.5 + 0.5 * sin(
        warpedPoint.x * 4.4
        + sin(warpedPoint.y * 3.1 - animationTime) * 1.42
        + animationTime * 1.3
    );

    float crossingWave = 0.5 + 0.5 * cos(
        warpedPoint.y * 5.0
        - sin(warpedPoint.x * 2.4 + animationTime * 0.7) * 1.15
        - animationTime
    );

    float softField = smoothstep(0.30, 0.82, cloud);
    float ribbon = pow(wave, 3.2) * 0.62 + pow(crossingWave, 4.0) * 0.38;

    float centerDistance = length((unitPosition - 0.5) * float2(0.82, 1.0));
    float vignette = 1.0 - smoothstep(0.28, 0.78, centerDistance);

    float frame = floor(time * 24.0 * motionAmount);
    float grain = backgroundHash(
        position * 1.55 + float2(frame * 1.37, frame * -0.91)
    ) - 0.5;

    float3 accent = float3(accentColor.rgb);
    float field = softField * 0.58;
    field += ribbon * (0.30 + vignette * 0.24);
    field = clamp(field, 0.0, 1.0);

    float maximumAlpha = mix(0.085, 0.16, darkMode);
    float alpha = 0.012 + field * maximumAlpha;
    alpha *= 0.70 + vignette * 0.30;
    alpha += grain * mix(0.008, 0.018, darkMode);
    alpha = clamp(alpha, 0.0, maximumAlpha);

    // Each starting point follows a different closed orbit. The horizontal and
    // vertical movement loops seamlessly while the ray angle continues to wander.
    float2 sourceMotionOne = loopedSourceMotion(lightTime, 0.70, 0.30);
    float2 sourceMotionTwo = loopedSourceMotion(lightTime, 0.57, 1.90);
    float2 sourceMotionThree = loopedSourceMotion(lightTime, 0.63, 3.50);
    float2 sourceMotionFour = loopedSourceMotion(lightTime, 0.76, 5.20);

    float2 sourceOne = float2(
        clamp(0.10 + sourceMotionOne.x * 0.085, 0.02, 0.28),
        -0.055 + sourceMotionOne.y * 0.024
    );
    float2 sourceTwo = float2(
        clamp(0.36 + sourceMotionTwo.x * 0.115, 0.17, 0.52),
        -0.055 + sourceMotionTwo.y * 0.028
    );
    float2 sourceThree = float2(
        clamp(0.64 + sourceMotionThree.x * 0.115, 0.48, 0.83),
        -0.055 + sourceMotionThree.y * 0.028
    );
    float2 sourceFour = float2(
        clamp(0.90 + sourceMotionFour.x * 0.085, 0.72, 0.98),
        -0.055 + sourceMotionFour.y * 0.024
    );

    float slopeOne = 0.25
        + smoothRandom(lightTime * 0.14, 71.3) * 0.15
        + smoothRandom(lightTime * 0.055, 78.5) * 0.050;
    float slopeTwo = 0.10
        + smoothRandom(lightTime * 0.13, 84.7) * 0.18
        + smoothRandom(lightTime * 0.051, 91.2) * 0.055;
    float slopeThree = -0.10
        + smoothRandom(lightTime * 0.12, 97.9) * 0.18
        + smoothRandom(lightTime * 0.057, 104.6) * 0.055;
    float slopeFour = -0.25
        + smoothRandom(lightTime * 0.15, 112.8) * 0.15
        + smoothRandom(lightTime * 0.061, 119.4) * 0.050;

    slopeOne = clamp(slopeOne, -0.05, 0.50);
    slopeTwo = clamp(slopeTwo, -0.28, 0.42);
    slopeThree = clamp(slopeThree, -0.42, 0.28);
    slopeFour = clamp(slopeFour, -0.50, 0.05);

    float hueOne = 0.04 + smoothRandom(lightTime * 0.045, 131.2) * 0.12;
    float hueTwo = -0.05 + smoothRandom(lightTime * 0.039, 143.7) * 0.12;
    float hueThree = 0.07 + smoothRandom(lightTime * 0.043, 157.1) * 0.12;
    float hueFour = -0.03 + smoothRandom(lightTime * 0.041, 169.8) * 0.12;

    // The dominance handoff is itself looped. Integer harmonic timing variation
    // prevents a mechanical sweep without introducing a discontinuity.
    float dominanceLoop = lightTime * 0.62;
    float dominanceAngle = dominanceLoop
        + sin(dominanceLoop * 2.0 + 0.80) * 0.18;
    float bundleWeightOne = rayBundleDominance(dominanceAngle, 0.0);
    float bundleWeightThree = rayBundleDominance(dominanceAngle, 1.5707963);
    float bundleWeightTwo = rayBundleDominance(dominanceAngle, 3.1415927);
    float bundleWeightFour = rayBundleDominance(dominanceAngle, 4.7123890);

    float4 bundleOne = spectralRayBundle(
        unitPosition, sourceOne, slopeOne, lightTime, 0.10, hueOne
    ) * bundleWeightOne;
    float4 bundleTwo = spectralRayBundle(
        unitPosition, sourceTwo, slopeTwo, lightTime, 1.70, hueTwo
    ) * bundleWeightTwo;
    float4 bundleThree = spectralRayBundle(
        unitPosition, sourceThree, slopeThree, lightTime, 3.30, hueThree
    ) * bundleWeightThree;
    float4 bundleFour = spectralRayBundle(
        unitPosition, sourceFour, slopeFour, lightTime, 4.90, hueFour
    ) * bundleWeightFour;

    float3 spectralLight = bundleOne.rgb + bundleTwo.rgb
        + bundleThree.rgb + bundleFour.rgb;
    float rayEnergy = bundleOne.a + bundleTwo.a + bundleThree.a + bundleFour.a;
    float3 spectralColor = spectralLight / max(rayEnergy, 0.001);
    float rayAlpha = min(
        rayEnergy * mix(0.028, 0.042, darkMode),
        mix(0.18, 0.27, darkMode)
    );

    float sourceGlow = spectralSourceGlow(unitPosition, sourceOne)
        * bundleWeightOne;
    sourceGlow += spectralSourceGlow(unitPosition, sourceTwo)
        * bundleWeightTwo;
    sourceGlow += spectralSourceGlow(unitPosition, sourceThree)
        * bundleWeightThree;
    sourceGlow += spectralSourceGlow(unitPosition, sourceFour)
        * bundleWeightFour;
    sourceGlow *= 0.46;
    float sourceAlpha = sourceGlow * mix(0.052, 0.085, darkMode);

    float dust = dustLayer(position, time * motionAmount, 34.0, 5.3, 0.76);
    dust += dustLayer(position, time * motionAmount, 57.0, 19.7, 0.70) * 0.72;
    float illuminatedVolume = smoothstep(0.05, 0.44, rayEnergy + sourceGlow * 1.6);
    float dustAlpha = dust * illuminatedVolume
        * (1.0 - smoothstep(0.46, 1.0, unitPosition.y))
        * mix(0.055, 0.09, darkMode);

    float3 dustColor = mix(float3(1.0), spectralColor, 0.22);

    // Composite in depth order: spectral light, smoke, then suspended dust.
    // This lets dense smoke naturally veil the rays instead of adding equally
    // bright color on top of them.
    float rayLayerAlpha = clamp(rayAlpha + sourceAlpha, 0.0, 1.0);
    float3 rayLayerColor = spectralColor * rayAlpha;
    rayLayerColor += float3(1.0, 0.985, 0.96) * sourceAlpha;

    float smokeTransmission = 1.0 - alpha;
    float smokeAndRayAlpha = alpha + rayLayerAlpha * smokeTransmission;
    float3 smokeAndRayColor = accent * alpha;
    smokeAndRayColor += rayLayerColor * smokeTransmission;

    float combinedAlpha = dustAlpha + smokeAndRayAlpha * (1.0 - dustAlpha);
    float3 premultipliedColor = dustColor * dustAlpha;
    premultipliedColor += smokeAndRayColor * (1.0 - dustAlpha);

    float cappedAlpha = min(combinedAlpha, 0.42);
    premultipliedColor *= cappedAlpha / max(combinedAlpha, 0.001);
    combinedAlpha = cappedAlpha;

    // SwiftUI composites shader colors as premultiplied alpha. Returning only
    // the animated light field keeps the palette background visible beneath it.
    return half4(half3(premultipliedColor), half(combinedAlpha));
}
