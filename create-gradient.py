#!/usr/bin/env python3

from math import sin, pi
from colorsys import hsv_to_rgb

NUMBER_OF_COLORS = 64
MAX_COLOR_VALUE = 31


def get_color(hue):
    (r, g, b) = hsv_to_rgb(hue, 1.0, 1.0)
    return (int(r * MAX_COLOR_VALUE) << 10) | (int(g * MAX_COLOR_VALUE) << 5) | int(b * MAX_COLOR_VALUE)


colors = [get_color(i / NUMBER_OF_COLORS) for i in range(0, NUMBER_OF_COLORS)]

print(f"DW {','.join(str(color) for color in colors)}")
