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

    float luminance = 0.012;
    luminance += softField * 0.095;
    luminance += ribbon * (0.055 + vignette * 0.055);
    luminance += grain * 0.035;
    luminance *= 0.62 + vignette * 0.38;
    luminance = clamp(luminance, 0.006, 0.24);

    float3 accent = float3(accentColor.rgb);
    float3 darkNeutral = float3(luminance);
    float3 darkTinted = accent * luminance * 1.35;
    float3 darkColor = mix(darkNeutral, darkTinted, 0.64);

    float lightness = 0.985;
    lightness -= softField * 0.055;
    lightness -= ribbon * (0.025 + vignette * 0.025);
    lightness += grain * 0.012;
    lightness = clamp(lightness, 0.86, 0.995);

    float lightTintAmount = 0.10 + softField * 0.08 + ribbon * 0.04;
    float3 lightColor = mix(float3(lightness), accent, lightTintAmount);
    float3 color = mix(lightColor, darkColor, darkMode);

    return half4(half3(color), 1.0h);
}
