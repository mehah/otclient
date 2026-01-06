uniform float u_Time;        // Czas animacji
uniform sampler2D u_Tex0;    // Tekstura bazowa
varying vec2 v_TexCoord;     // Współrzędne tekstury

void main()
{
  vec4 col = texture2D(u_Tex0, v_TexCoord); // Pobierz kolor tekstury

  // Oblicz intensywność błysku: szybszy fade-out
  float flash = max(0.0, 1.0 - mod(u_Time * 0.8, 1.5)); // Szybsze fade-out i cykle

  col.rgb += flash;                         // Dodaj błysk do wszystkich kanałów kolorów

  // Ustaw końcowy kolor
  gl_FragColor = col;
}
