#!/usr/bin/env python3

from math import sin, pi
from colorsys import hls_to_rgb

NUMBER_OF_COLORS = 64
MAX_COLOR_VALUE = 31
LIGHTNESSES = [0.5, 0.8, 0.9]


def get_color(hue, lightness):
    (r, g, b) = hls_to_rgb(hue, lightness, 1.0)
    return (int(r * MAX_COLOR_VALUE) << 10) | (int(g * MAX_COLOR_VALUE) << 5) | int(b * MAX_COLOR_VALUE)


colors = [get_color(i / NUMBER_OF_COLORS, value)
          for i in range(0, NUMBER_OF_COLORS) for value in LIGHTNESSES]

print(f"DW {','.join(str(color) for color in colors)}")
