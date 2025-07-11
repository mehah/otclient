/*
 * Copyright (c) 2010-2025 OTClient <https://github.com/edubart/otclient>
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

#pragma once

static constexpr std::string_view glslMainVertexShader = "\n\
    highp vec4 calculatePosition();\n\
    void main() {\n\
        gl_Position = calculatePosition();\n\
    }\n",

    glslMainWithTexCoordsVertexShader = "\n\
    attribute highp vec2 a_TexCoord;\n\
    uniform highp mat3 u_TextureMatrix;\n\
    varying highp vec2 v_TexCoord;\n\
    highp vec4 calculatePosition();\n\
    void main()\n\
    {\n\
        gl_Position = calculatePosition();\n\
        v_TexCoord = (u_TextureMatrix * vec3(a_TexCoord,1.0)).xy;\n\
    }\n",

    glslPositionOnlyVertexShader = "\n\
    attribute highp vec2 a_Vertex;\n\
    uniform highp mat3 u_TransformMatrix;\n\
    uniform highp mat3 u_ProjectionMatrix;\n\
    highp vec4 calculatePosition() {\n\
        return vec4(u_ProjectionMatrix * u_TransformMatrix * vec3(a_Vertex.xy, 1.0), 1.0);\n\
    }\n",

    glslMainFragmentShader = "\n\
    uniform lowp float u_Opacity;\n\
    lowp vec4 calculatePixel();\n\
    void main()\n\
    {\n\
        gl_FragColor = calculatePixel();\n\
        gl_FragColor.a *= u_Opacity;\n\
    }\n",

    glslTextureSrcFragmentShader = "\n\
    varying mediump vec2 v_TexCoord;\n\
    uniform lowp vec4 u_Color;\n\
    uniform sampler2D u_Tex0;\n\
    lowp vec4 calculatePixel() {\n\
        return texture2D(u_Tex0, v_TexCoord) * u_Color;\n\
    }\n",

    glslSolidColorFragmentShader = "\n\
    uniform lowp vec4 u_Color;\n\
    lowp vec4 calculatePixel() {\n\
        return u_Color;\n\
    }\n",

    glslReplaceColorFragmentShader = "\n\
    uniform vec4 u_Color;\n\
    varying vec2 v_TexCoord;\n\
    uniform sampler2D u_Tex0;\n\
    vec4 calculatePixel() {\n\
        if(texture2D(u_Tex0, v_TexCoord).a > 0.01)\n\
            return u_Color;\n\
        return vec4(0,0,0,0);\n\
    }\n",

    lineVertexShader = "\n\
    attribute vec2 a_Vertex;\n\
    uniform mat3 u_TransformMatrix;\n\
    uniform mat3 u_ProjectionMatrix;\n\
    void main()\n\
    {\n\
        gl_Position = vec4((u_ProjectionMatrix * u_TransformMatrix * vec3(a_Vertex.xy, 1.0)).xy, 1.0, 1.0);\n\
    }\n",

    lineFragmentShader = "\n\
    uniform vec4 u_Color;\n\
    void main()\n\
    {\n\
        gl_FragColor = u_Color;\n\
    }\n";
