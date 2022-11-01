uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main()
{
  vec4 col = texture2D(u_Tex0, v_TexCoord);
  float d = u_Time * 1.25;
  col.x += (1.0 + sin(d * 2.0));
  gl_FragColor = col;
}
