<!-- summary: fMRI visual stimulation movies with eccentricity-scaled noise and red fixation dot, compatible with ePrime3 -->

# stimMovieForEprime

*Moved from the retired pkm wiki (`projects/stim-movie-for-eprime.md`), 2026-11-04 (bass review D-a). Defaults and file list re-checked against this repo.*

## Purpose

Generate pre-rendered movie files for visual fMRI stimulation. Movies are played back via ePrime3 during scanning. The stimulus is designed to drive visual cortex broadly while isolating attention via the fixation dot task.

## Stimulus design

**Noise**: Eccentricity-scaled binary noise that flickers at 8 Hz. Spatial frequency is highest at the fovea and decreases toward the periphery, mimicking cortical magnification. Background luminance is L*=50 (sRGB ≈ 119).

**Fixation dot**: A small red circle (LCH: L=50, H=40°) that alternates between two saturation levels (high = max chroma, low = 1−contrast) at random intervals drawn from Uniform(3, 10) s. The dot is surrounded by a grey ring that blanks the log singularity at the centre. Participants monitor the dot for saturation changes (detection task).

**ON vs OFF movies**: ON movies contain the noise stimulus at full contrast. OFF (control) movies are identical in structure but with noise contrast = 0 (flat grey background). Both have an active fixation dot with an independent random saturation schedule.

## File organisation

```
stimMovie/
  doIt.m                          ← entry point; set output folder and nON/nOFF here
  scaledNoiseMovieWithRedFix.m    ← main stimulus function (also saves test frame PNGs)
  makeFixDotSchedule.m            ← random binary schedule for fixation dot
  makeLogPolarMap.m               ← precomputes log-polar pixel→patch lookup
  renderNoiseFrame.m              ← renders one frame from the lookup table
  lch2srgb.m                      ← LCH → sRGB conversion
  lchMaxChroma.m                  ← gamut boundary search
```

All dependencies are self-contained in the project folder.

## Output

Files are written to a user-specified folder (`p.output.folder`). If the folder exists, a datetime-suffixed copy is created. Files are named `scaledNoiseMovieWithRedFix_on_NN.avi` and `scaledNoiseMovieWithRedFix_off_NN.avi`. Format: Motion JPEG AVI (ePrime3-compatible via Windows DirectShow).

## Key parameters (defaults)

| Field | Default | Meaning |
|---|---|---|
| `monitor.screenW/H` | 1920×1080 | screen resolution |
| `spatial.fieldHalfDeg` | 12° | half-width of visual field |
| `spatial.contrast` | 1.0 | noise Michelson contrast |
| `temporal.durationS` | 60 s | movie duration |
| `temporal.updateHz` | 8 Hz | noise flicker rate |
| `fixDot.hueDeg` | 40° | LCH hue (red) |
| `fixDot.contrast` | 0.5 | low-state saturation = 1−contrast |
| `fixDot.radDeg` | 0.15° | inner dot radius |
| `fixDot.outerRadDeg` | 0.15° | outer grey ring radius |

These are the function's own defaults (`p = scaledNoiseMovieWithRedFix()`). `doIt.m` overrides
some of them (checked 2026-11-04): `temporal.durationS = 120`, `fixDot.contrast = 0.75`,
`fixDot.L = 40`, `output.quality = 70`, and 30 ON plus 30 OFF runs.

## Render performance

~7 s per 60-second movie at 1920×1080, 8 Hz, on a Mac (Apple Silicon). The log-polar map is computed once and reused across all movies.

## See also

- [Eccentricity-Scaled Noise](eccentricity-scaled-noise.md)
- [LCH Colorspace for Stimuli](lch-colorspace-for-stimuli.md)
