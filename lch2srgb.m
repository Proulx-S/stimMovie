function [rgb, rgb_raw] = lch2srgb(L, C, H_deg)
% LCH2SRGB  Convert CIELCh (LCH) to sRGB.
%
% Pipeline: LCH → CIELAB → CIEXYZ (D65) → linear sRGB → gamma-corrected sRGB
% Same colour path used by colormap_bivariateBlackToSpectral / the
% Colorspace-Transformations toolbox, implemented here without external deps.
%
% Usage:
%   rgb          = lch2srgb(L, C, H_deg)          % clamped to [0,1]
%   [rgb, rgb_raw] = lch2srgb(L, C, H_deg)        % rgb_raw is pre-clamp (for gamut checks)
%
% Inputs:
%   L      - CIELCh lightness    [0, 100]
%   C      - CIELCh chroma       [0, ~200]
%   H_deg  - CIELCh hue angle    [0, 360] degrees
%
% Outputs:
%   rgb      - [3 x 1] sRGB values in [0, 1], clamped to gamut
%   rgb_raw  - [3 x 1] sRGB values before clamping (use for gamut boundary checks)

% ── LCH → CIELAB ─────────────────────────────────────────────────────────
H_rad = H_deg * pi / 180;
a     =  C * cos(H_rad);
b_lab =  C * sin(H_rad);

% ── CIELAB → CIEXYZ (D65 reference white) ────────────────────────────────
Xn = 0.95047;  Yn = 1.0;  Zn = 1.08883;
d  = 6 / 29;   % 0.20690...

fy = (L + 16) / 116;
fx = a / 500 + fy;
fz = fy - b_lab / 200;

f2t = @(f) f.^3 .* (f > d) + (3*d^2*(f - 4/29)) .* (f <= d);

X = Xn * f2t(fx);
Y = Yn * f2t(fy);
Z = Zn * f2t(fz);

% ── CIEXYZ → linear sRGB (IEC 61966-2-1, D65) ────────────────────────────
M = [ 3.2404542, -1.5371385, -0.4985314;
     -0.9692660,  1.8760108,  0.0415560;
      0.0556434, -0.2040259,  1.0572252];

rgb_lin = M * [X; Y; Z];

% ── linear sRGB → gamma-corrected sRGB ───────────────────────────────────
v   = rgb_lin;
rgb = (v <= 0.0031308) .* (12.92 .* v) + ...
      (v >  0.0031308) .* (1.055 .* v .^ (1/2.4) - 0.055);

rgb_raw = rgb;               % pre-clamp, for gamut boundary detection
rgb = max(0, min(1, rgb));   % clamp to [0, 1]
end
