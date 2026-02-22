//
//  ContentView.swift
//  macfrag
//
//  Created by Arturo  Villalobos on 2/21/26.
//

import SwiftUI

struct ContentView: View {
    @State private var shaderText: AttributedString = AttributedString(defaultMSL)
    @State private var buildLog: String = ""


    // Adapter: AttributedString → String for the Metal compiler
    private var shaderSourceString: Binding<String> {
        Binding(
            get: { String(shaderText.characters) },
            set: { _ in }   // <- read-only
        )
    }

    var body: some View {
        HSplitView {
            VStack(spacing: 0) {
                MSLCodeEditor(text: $shaderText)

                // Optional: show build log under editor
                if !buildLog.isEmpty {
                    Divider()
                    ScrollView {
                        Text(buildLog)
                            .font(.system(.caption, design: .monospaced))
                            .textSelection(.enabled)
                            .padding(8)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .frame(height: 180)
                }
            }
            .frame(minWidth: 420)

            MetalShaderPreview(source: shaderSourceString, log: $buildLog)
                .frame(minWidth: 420)
        }
        .frame(minWidth: 980, minHeight: 600)
    }
}

private let defaultMSL = """
#include <metal_stdlib>
using namespace metal;

struct Varyings {
    float4 position [[position]];
    float2 uv;
};

struct Uniforms {
    float2 resolution;
    float  time;
    float  pad;
};

vertex Varyings vertex_main(uint vid [[vertex_id]]) {
    float2 pos;
    if (vid == 0)      pos = float2(-1.0, -1.0);
    else if (vid == 1) pos = float2( 3.0, -1.0);
    else               pos = float2(-1.0,  3.0);

    Varyings out;
    out.position = float4(pos, 0.0, 1.0);
    out.uv = 0.5 * (pos + 1.0);
    return out;
}

// ---- Helpers (avoid redefining stdlib names like fract/step/mix) ----

inline float2 mod(float2 x, float y) { return x - y * floor(x / y); }
inline float3 mod(float3 x, float y) { return x - y * floor(x / y); }
inline float4 mod(float4 x, float y) { return x - y * floor(x / y); }

// ---- 3D noise ----

float4 permute(float4 x) { return mod(((x * 34.0) + 1.0) * x, 289.0); }
float4 taylorInvSqrt(float4 r) { return 1.79284291400159 - 0.85373472095314 * r; }
float3 fade(float3 t) { return t * t * t * (t * (t * 6.0 - 15.0) + 10.0); }

float noise2(float3 P) {
    float3 Pi0 = floor(P);
    float3 Pi1 = Pi0 + float3(1.0);
    Pi0 = mod(Pi0, 289.0);
    Pi1 = mod(Pi1, 289.0);
    float3 Pf0 = fract(P);
    float3 Pf1 = Pf0 - float3(1.0);

    float4 ix  = float4(Pi0.x, Pi1.x, Pi0.x, Pi1.x);
    float4 iy  = float4(Pi0.y, Pi0.y, Pi1.y, Pi1.y);
    float4 iz0 = float4(Pi0.z);
    float4 iz1 = float4(Pi1.z);

    float4 ixy  = permute(permute(ix) + iy);
    float4 ixy0 = permute(ixy + iz0);
    float4 ixy1 = permute(ixy + iz1);

    float4 gx0 = ixy0 / 7.0;
    float4 gy0 = fract(floor(gx0) / 7.0) - 0.5;
    gx0 = fract(gx0);
    float4 gz0 = float4(0.5) - abs(gx0) - abs(gy0);
    float4 sz0 = step(gz0, float4(0.0));
    gx0 -= sz0 * (step(0.0, gx0) - 0.5);
    gy0 -= sz0 * (step(0.0, gy0) - 0.5);

    float4 gx1 = ixy1 / 7.0;
    float4 gy1 = fract(floor(gx1) / 7.0) - 0.5;
    gx1 = fract(gx1);
    float4 gz1 = float4(0.5) - abs(gx1) - abs(gy1);
    float4 sz1 = step(gz1, float4(0.0));
    gx1 -= sz1 * (step(0.0, gx1) - 0.5);
    gy1 -= sz1 * (step(0.0, gy1) - 0.5);

    float3 g000 = float3(gx0.x, gy0.x, gz0.x);
    float3 g100 = float3(gx0.y, gy0.y, gz0.y);
    float3 g010 = float3(gx0.z, gy0.z, gz0.z);
    float3 g110 = float3(gx0.w, gy0.w, gz0.w);
    float3 g001 = float3(gx1.x, gy1.x, gz1.x);
    float3 g101 = float3(gx1.y, gy1.y, gz1.y);
    float3 g011 = float3(gx1.z, gy1.z, gz1.z);
    float3 g111 = float3(gx1.w, gy1.w, gz1.w);

    float4 norm0 = taylorInvSqrt(float4(dot(g000, g000), dot(g010, g010), dot(g100, g100), dot(g110, g110)));
    g000 *= norm0.x; g010 *= norm0.y; g100 *= norm0.z; g110 *= norm0.w;

    float4 norm1 = taylorInvSqrt(float4(dot(g001, g001), dot(g011, g011), dot(g101, g101), dot(g111, g111)));
    g001 *= norm1.x; g011 *= norm1.y; g101 *= norm1.z; g111 *= norm1.w;

    float n000 = dot(g000, Pf0);
    float n100 = dot(g100, float3(Pf1.x, Pf0.y, Pf0.z));
    float n010 = dot(g010, float3(Pf0.x, Pf1.y, Pf0.z));
    float n110 = dot(g110, float3(Pf1.x, Pf1.y, Pf0.z));
    float n001 = dot(g001, float3(Pf0.x, Pf0.y, Pf1.z));
    float n101 = dot(g101, float3(Pf1.x, Pf0.y, Pf1.z));
    float n011 = dot(g011, float3(Pf0.x, Pf1.y, Pf1.z));
    float n111 = dot(g111, Pf1);

    float3 fade_xyz = fade(Pf0);
    float4 n_z  = mix(float4(n000, n100, n010, n110), float4(n001, n101, n011, n111), fade_xyz.z);
    float2 n_yz = mix(n_z.xy, n_z.zw, fade_xyz.y);
    float  n_xyz = mix(n_yz.x, n_yz.y, fade_xyz.x);

    return 2.2 * n_xyz;
}

// ---- Palette / FBM ----

float3 palette(float t) {
    float3 a = float3(0.5);
    float3 b = float3(0.5);
    float3 c = float3(1.0);
    float3 d = float3(0.236, 0.416, 0.557);
    // GLSL: a + b*cos(6.28318*(c*t + d))
    return a + b * cos(6.28318 * (c * t + d));
}

float random2(float2 st) {
    return fract(sin(dot(st, float2(12.9898, 78.233))) * 43758.5453123);
}

float noise(float2 st) {
    float2 i = floor(st);
    float2 f = fract(st);

    float a = random2(i);
    float b = random2(i + float2(1.0, 0.0));
    float c = random2(i + float2(0.0, 1.0));
    float d = random2(i + float2(1.0, 1.0));

    float2 u = f * f * (3.0 - 2.0 * f);

    return mix(a, b, u.x) +
           (c - a) * u.y * (1.0 - u.x) +
           (d - b) * u.x * u.y;
}

float fbm(float2 st) {
    float value = 0.0;
    float amplitude = 0.5;
    for (int i = 0; i < 5; i++) {
        value += amplitude * noise(st);
        st *= 2.0;
        amplitude *= 0.5;
    }
    return value;
}

float patternfbm(float2 p, float u_time) {
    float2 q = float2(
        fbm(p + float2(0.0, 0.0)),
        fbm(p + float2(5.2, 1.3))
    );

    float2 r = float2(
        fbm(p + 4.0 * q + float2(1.7, 9.2)),
        fbm(p + 4.0 * q + float2(8.3, 2.8))
    );

    return fbm(p + 4.0 * r + u_time);
}

float mapRange(float value, float min1, float max1, float min2, float max2) {
    return min2 + (value - min1) * (max2 - min2) / (max1 - min1);
}

fragment float4 fragment_main(Varyings in [[stage_in]],
                              constant Uniforms& u [[buffer(0)]]) {
    float2 uv = in.uv;

    uv = 2.0 * (uv - 0.5);
    uv.x *= u.resolution.x / u.resolution.y;

    float displacement = patternfbm(uv * 3.0, u.time);

    float t = mapRange(displacement, 0.08, 0.4, 0.3, 0.9);
    float3 col = palette(t);

    return float4(col, 1.0);
}
"""

#Preview {
    ContentView()
}
