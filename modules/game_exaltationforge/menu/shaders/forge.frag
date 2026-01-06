uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main(void)
{
    vec4 texColor = texture2D(u_Tex0, v_TexCoord);

    // cykl wolnego migotania
    float slow = sin(mod(u_Time, 0.6) * 3.14159);
    if(slow > 0.99) slow = 1.0;

    // cykl szybkiego migotania
    float fast = sin(mod(u_Time, 0.1) * 3.14159);
    if(fast > 0.99) fast = 1.0;

    // wybieramy większą wartość – wolne/szybkie migotanie
    float intensity = max(slow, fast);

    // końcowy flash – jeśli u_Time > X, dajemy pełną biel
    if(u_Time > 5.0) intensity = 1.0;

    vec3 flash = mix(texColor.rgb, vec3(1.0), intensity);
    gl_FragColor = vec4(flash, texColor.a);
}
