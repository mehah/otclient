/*
 * Copyright (c) 2010-2022 OTClient <https://github.com/edubart/otclient>
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

#include "outfit.h"

Color Outfit::getColor(int color)
{
    if (color >= HSI_H_STEPS * HSI_SI_VALUES)
        color = 0;

    float loc1 = 0;
    float loc2 = 0;
    float loc3 = 0;
    if (color % HSI_H_STEPS != 0) {
        loc1 = color % HSI_H_STEPS * 1.0 / 18.0;
        loc2 = 1;
        loc3 = 1;

        switch (color / HSI_H_STEPS) {
            case 0:
                loc2 = 0.25;
                loc3 = 1.00;
                break;
            case 1:
                loc2 = 0.25;
                loc3 = 0.75;
                break;
            case 2:
                loc2 = 0.50;
                loc3 = 0.75;
                break;
            case 3:
                loc2 = 0.667;
                loc3 = 0.75;
                break;
            case 4:
                loc2 = 1.00;
                loc3 = 1.00;
                break;
            case 5:
                loc2 = 1.00;
                loc3 = 0.75;
                break;
            case 6:
                loc2 = 1.00;
                loc3 = 0.50;
                break;
        }
    } else {
        loc1 = 0;
        loc2 = 0;
        loc3 = 1 - static_cast<float>(color) / static_cast<float>(HSI_H_STEPS) / static_cast<float>(HSI_SI_VALUES);
    }

    if (loc3 == 0)
        return Color::alpha;

    if (loc2 == 0) {
        const int loc7 = static_cast<int>(loc3 * 255);
        return Color(loc7, loc7, loc7);
    }

    float red = 0;
    float green = 0;
    float blue = 0;

    if (loc1 < 1.0 / 6.0) {
        red = loc3;
        blue = loc3 * (1 - loc2);
        green = blue + (loc3 - blue) * 6 * loc1;
    } else if (loc1 < 2.0 / 6.0) {
        green = loc3;
        blue = loc3 * (1 - loc2);
        red = green - (loc3 - blue) * (6 * loc1 - 1);
    } else if (loc1 < 3.0 / 6.0) {
        green = loc3;
        red = loc3 * (1 - loc2);
        blue = red + (loc3 - red) * (6 * loc1 - 2);
    } else if (loc1 < 4.0 / 6.0) {
        blue = loc3;
        red = loc3 * (1 - loc2);
        green = blue - (loc3 - red) * (6 * loc1 - 3);
    } else if (loc1 < 5.0 / 6.0) {
        blue = loc3;
        green = loc3 * (1 - loc2);
        red = green + (loc3 - green) * (6 * loc1 - 4);
    } else {
        red = loc3;
        green = loc3 * (1 - loc2);
        blue = red - (loc3 - green) * (6 * loc1 - 5);
    }
    return Color(static_cast<int>(red * 255), static_cast<int>(green * 255), static_cast<int>(blue * 255));
}

void Outfit::resetClothes()
{
    setHead(0);
    setBody(0);
    setLegs(0);
    setFeet(0);
    setMount(0);
}

void Outfit::setHead(uint8_t head) {
    if (m_head == head)
        return;

    m_head = head;
    m_headColor = getColor(head);
}
void Outfit::setBody(uint8_t body) {
    if (m_body == body)
        return;

    m_body = body;
    m_bodyColor = getColor(body);
}
void Outfit::setLegs(uint8_t legs) {
    if (m_legs == legs)
        return;

    m_legs = legs;
    m_legsColor = getColor(legs);
}
void Outfit::setFeet(uint8_t feet) {
    if (m_feet == feet)
        return;

    m_feet = feet;
    m_feetColor = getColor(feet);
}