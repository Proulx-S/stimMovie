<!-- summary: Complex-log transform for eccentricity-scaled visual noise matching cortical magnification -->

# Eccentricity-Scaled Noise

*Moved from the retired pkm wiki (`methods/eccentricity-scaled-noise.md`), 2026-11-04 (bass review D-a). File paths re-checked against this repo.*

## What it is

A visual noise stimulus where spatial frequency scales with eccentricity: high SF near the fovea, low SF in the periphery. This mirrors cortical magnification — each unit of visual cortex sees roughly the same density of noise patches regardless of eccentricity.

## How it works

The complex-log transform maps visual-field position (x, y) in degrees to log-polar space:

```
W = log(x + i·y)
logR = real(W)   % log(eccentricity)
θ    = imag(W)   % polar angle ∈ (−π, π]
```

A square noise grid (N×N) is indexed by `(logR, θ)`. Because the transform compresses the periphery, noise patches in the periphery cover more visual angle — they appear coarser. The fovea gets fine patches.

**Seam elimination.** Without care, θ = +π and θ = −π (both at the left horizontal axis) map to different columns, producing a visible radial seam. Fixed by:

```matlab
colIdx = mod(floor((θ + π) / (2π) * N), N) + 1
```

This wraps both angles to the same column.

**Zero luminance bias.** Assigning noise independently per patch risks net luminance drift. Instead: enumerate all visible patches, randomly permute them, assign exactly N/2 to white and N/2 to black each frame.

## Implementation

- `makeLogPolarMap.m` — precomputes pixel→patch lookup table (run once per movie)
- `renderNoiseFrame.m` — draws one frame using the lookup table (~7 ms at 1920×1080)
- Adapted from colleague's `makeNoisePattern.m` (stimulus_motor_visual toolbox)

## Parameters

| Parameter | Meaning |
|---|---|
| `fieldHalfDeg` | half-width of visual field in degrees |
| `noiseN` | side length of cortical noise grid (e.g., 512) |
| `fixBlankRadDeg` | radius of blank centre disc hiding the log singularity |
| `contrast` | Michelson contrast of the noise (0–1) |

## See also

- [LCH Colorspace for Stimuli](lch-colorspace-for-stimuli.md)
- [stimMovieForEprime project](stimMovie-overview.md)
