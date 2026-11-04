<!-- summary: LCH colorspace pipeline for perceptually uniform stimulus colors, including gamut boundary search -->

# LCH Colorspace for Stimuli

*Moved from the retired pkm wiki (`methods/lch-colorspace-for-stimuli.md`), 2026-11-04 (bass review D-a). File paths re-checked against this repo.*

## Why LCH

LCH (Lightness, Chroma, Hue) is the cylindrical form of CIELAB. Equal steps in L, C, or H produce equal perceived differences regardless of the direction. This makes it the right colorspace for:

- Defining stimulus contrast in perceptual units (not sRGB values)
- Setting fixation dot color changes that are equidistant in appearance
- Controlling luminance independently of color (by fixing L)

## Conversion pipeline

```
LCH → LAB → XYZ (D65) → linear sRGB → gamma sRGB
```

Key steps:
1. `a = C·cos(H)`, `b = C·sin(H)` → LAB
2. `f(t) = t^(1/3)` if `t > (6/29)^3`, else `(29/6)^2 · t/3 + 4/29` → XYZ via `L*, a*, b*`
3. Multiply XYZ by the D65 → linear sRGB matrix (standard 3×3)
4. Gamma companding: `1.055 · x^(1/2.4) − 0.055` for `x > 0.0031308`

## Gamut boundary

At fixed L and H, not all Chroma values are in-gamut. To find the maximum Chroma before any sRGB channel clips:

- Binary search over C, testing pre-clamp RGB values (not post-clamp)
- Condition: `all(rgb_raw ≥ 0) && all(rgb_raw ≤ 1)`
- Pre-clamp values must be exposed by the conversion function (`rgb_raw` second output)

For L=50, H=40° (red): C_max ≈ 99.6, sRGB ≈ [239, 0, 0].

## Background luminance

L* = 50 is the perceptual midpoint (halfway between 0 = black and 100 = white). The corresponding sRGB value:

```matlab
fY = (50 + 16) / 116;
Y  = fY^3;
bgGray = round((1.055 * Y^(1/2.4) - 0.055) * 255)  % ≈ 119
```

Setting the fixation dot to the same L* = 50 means it is isoluminant with the background — changes in the dot are purely chromatic.

## Fixation dot contrast convention

- `satHigh = 1.0` (max chroma at C_max)
- `satLow  = 1.0 − contrast`
- A contrast of 0.5 gives low state at C = 0.5·C_max; contrast of 1.0 gives low state at C = 0 (achromatic)

## Implementation

- `lch2srgb.m` — full pipeline, returns `[rgb, rgb_raw]`
- `lchMaxChroma.m` — binary search using `rgb_raw`

## See also

- [Eccentricity-Scaled Noise](eccentricity-scaled-noise.md)
- [stimMovieForEprime project](stimMovie-overview.md)
