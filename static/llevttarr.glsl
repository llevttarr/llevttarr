#version 430

in vec2 fragCoord;
out vec4 fragColor;

uniform int iFrame;
uniform float iTime;
uniform float iTimeDelta;
uniform float iAspect;
uniform vec4 iMouse;
uniform vec3 iResolution;
uniform sampler2D iSDFTexture;
uniform vec2 iSDFResolution;
uniform int iHasSDF;

vec3 palette(float t/*, vec3 a, vec3 b, vec3 c, vec3 d*/ ) {
    vec3 a = vec3(0.610, 0.498, 0.650);
    vec3 b = vec3(0.450, 0.578, 0.406);
    vec3 c = vec3(0.525, 0.493, 0.614);
    vec3 d = vec3(2.836, 2.410, 3.423);
    return a + b*cos( 6.28318*(c*t+d) );
}
float sdfCoverage(vec2 fragCoord) {
    vec2 uv = fragCoord / iResolution.xy;
    float scale = max(iResolution.x / iSDFResolution.x,iResolution.y / iSDFResolution.y);
    vec2 scaledTexSize = iSDFResolution * scale;
    vec2 sdfUV = (uv - 0.5) * (iResolution.xy / scaledTexSize) + 0.5;
    return texture(iSDFTexture, sdfUV).r;
}
float hash(vec2 p) {
    p = fract(p * vec2(6767.545, 6969.26));
    p+=dot(p, p +44.32);
    return fract(p.x * p.y);
}
float noise(vec2 p) {
    vec2 i = floor(p);
    vec2 f = fract(p);
    float a = hash(i);
    float b = hash(i+vec2(1.0, 0.0));
    float c = hash(i+ vec2(0.0, 1.0));
    float e = hash(i+ vec2(1.0, 1.0));
    vec2 u = f*f*(3.0 - 2.0* f);
    return mix(a, b, u.x)+(c-a)* u.y*(1.0 - u.x) + (e - b) * u.x * u.y;
}
float iter(vec2 p) {
    float value =.0;
    float amp = 0.1;
    for (int i = 0; i < 12; i++) {
        value += amp * noise(p);
        p *= 2.0;
        amp *= 0.5;
    }
    return value;
}
mat2 rot(float a) {
    return mat2(-cos(a),-sin(a),sin(a),-cos(a));
}
void main() {
    vec2 uv = gl_FragCoord.xy / iResolution.xy;
    float d = sdfCoverage(gl_FragCoord.xy);
    vec2 p = (uv - 0.5) * vec2(iAspect, 1.0);
    float dP = length(p);
    vec2 prot = rot(iTime* 0.3 - log(dP+.1) * 1.5) * p;
    vec2 randUV= rot(iTime*0.15) * prot;
    float n = 542.0*abs(sin(iTime * 0.5))*iter(randUV*6.0+iTime * 0.1);

    float pulse = sin(iTime*.8)*.1 +2.5;
    float tR = mix(.3, .0,pulse);

    float dist = abs(d -tR - n *.08);
    float rim = 1.0/(0.03 + dist);
    float glow = 1.0- exp(-rim*.15);
    vec3 col = vec3(glow)*palette(glow);
    fragColor = vec4(col, 1.0);
}