uniform float u_Time;
uniform sampler2D u_Tex0;
varying vec2 v_TexCoord;

void main()
{

  vec4 col = texture2D(u_Tex0, v_TexCoord);

  col.r = 0.0;
  col.g = 0.0;
  col.b = 0.0;

  gl_FragColor = col;
}
