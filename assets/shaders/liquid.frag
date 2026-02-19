// assets/shaders/liquid.frag
#version 460 core
precision highp float;

#include <flutter/runtime_effect.glsl>

uniform vec2 uSize;      // canvas size
uniform float uTime;     // seconds

// base colors (you can tune)
uniform vec4 c1;
uniform vec4 c2;
uniform vec4 c3;
uniform vec4 c4;

// metaballs settings
uniform float intensity; // 0..1
uniform float softness;  // 0..1

out vec4 fragColor;

float metaball(vec2 p, vec2 center, float r) {
  float d = length(p - center);
  // field function
  return (r * r) / (d * d + 1e-3);
}

vec2 drift(vec2 base, float a, float b, float t) {
  return base + vec2(sin(t*a), cos(t*b)) * 0.10;
}

void main() {
  vec2 uv = FlutterFragCoord().xy / uSize;
  vec2 p = uv;

  float t = uTime;

  // centers (non-loopy: multiple frequencies)
  vec2 cA = drift(vec2(0.25, 0.35), 0.21, 0.17, t) + vec2(sin(t*0.11), cos(t*0.07))*0.05;
  vec2 cB = drift(vec2(0.70, 0.40), 0.19, 0.23, t) + vec2(cos(t*0.09), sin(t*0.12))*0.05;
  vec2 cC = drift(vec2(0.45, 0.70), 0.16, 0.20, t) + vec2(sin(t*0.08), cos(t*0.10))*0.05;
  vec2 cD = drift(vec2(0.80, 0.75), 0.14, 0.18, t) + vec2(cos(t*0.06), sin(t*0.09))*0.05;

  float f =
      metaball(p, cA, 0.24) +
      metaball(p, cB, 0.22) +
      metaball(p, cC, 0.25) +
      metaball(p, cD, 0.20);

  // convert field -> alpha
  float edge = mix(1.0, 2.0, softness);
  float a = smoothstep(edge, edge + 1.2, f) * intensity;

  // color blend by “which metaball dominates”
  float w1 = metaball(p, cA, 0.24);
  float w2 = metaball(p, cB, 0.22);
  float w3 = metaball(p, cC, 0.25);
  float w4 = metaball(p, cD, 0.20);
  float sum = w1+w2+w3+w4 + 1e-4;

  vec4 col =
      (c1*w1 + c2*w2 + c3*w3 + c4*w4) / sum;

  // subtle glow
  float glow = smoothstep(edge+0.4, edge+1.6, f) * 0.35 * intensity;

  fragColor = vec4(col.rgb + glow, a);
}
