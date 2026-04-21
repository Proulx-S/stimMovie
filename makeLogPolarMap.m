function map = makeLogPolarMap(screenW, screenH, fieldHalfDeg, noiseN, fixBlankRadDeg)
% MAKELOGPOLARMAP  Precompute log-polar lookup indices for eccentricity-scaled noise.
%
% The complex-log transform maps visual-field position (x,y) -> log(x+iy),
% giving higher spatial frequency near the fixation point and lower SF in
% the periphery (matching cortical magnification).
%
% Adapted from makeNoisePattern.m (stimulus_motor_visual toolbox).
%
% Usage:
%   map = makeLogPolarMap(screenW, screenH, fieldHalfDeg, noiseN, fixBlankRadDeg)
%
% Inputs:
%   screenW         - output frame width  (pixels)
%   screenH         - output frame height (pixels)
%   fieldHalfDeg    - half-width of visual field in degrees (from center to edge)
%   noiseN          - side length of the square cortical noise grid (e.g. 512)
%   fixBlankRadDeg  - radius of the blank centre disc in degrees (hides log singularity)
%
% Output:
%   map  - struct with precomputed lookup fields (used by renderNoiseFrame)

% ---- build visual-field coordinate grids (in degrees) -------------------
cx = (screenW + 1) / 2;
cy = (screenH + 1) / 2;
pix2deg = fieldHalfDeg / (screenW / 2);

[Xpix, Ypix] = meshgrid(1:screenW, 1:screenH);
X_deg = (Xpix - cx) * pix2deg;
Y_deg = (Ypix - cy) * pix2deg;

% ---- complex log transform ----------------------------------------------
W    = log(X_deg + 1i * Y_deg);
logR = real(W);   % log(eccentricity)
thet = imag(W);   % polar angle from atan2, in (-pi, pi]

% ---- valid-pixel mask (excludes the singularity at origin) --------------
validMask = ~(isnan(logR) | isinf(logR));

% ---- map logR to row index [1..noiseN] using floor ----------------------
minLogR = log(0.5 * pix2deg);
maxLogR = log(sqrt((screenW/2)^2 + (screenH/2)^2) * pix2deg);

rowIdx = floor((logR - minLogR) / (maxLogR - minLogR) * noiseN) + 1;
rowIdx = max(1, min(noiseN, rowIdx));
rowIdx(~validMask) = 1;

% ---- map theta to col index [1..noiseN] using floor + mod ---------------
% mod wrapping ensures thet=+pi and thet=-pi both land in col 1,
% eliminating the systematic seam at the negative-x horizontal axis.
colIdx = mod(floor((thet + pi) / (2*pi) * noiseN), noiseN) + 1;
colIdx(~validMask) = 1;

% ---- linear index into noiseN x noiseN noise grid -----------------------
linIdx = sub2ind([noiseN, noiseN], rowIdx, colIdx);

% ---- blank-centre mask (hides log singularity, filled with bgGray) ------
blankRadPix = round(fixBlankRadDeg / pix2deg);
blankMask   = (Xpix - cx).^2 + (Ypix - cy).^2 <= blankRadPix^2;

% ---- visible patch IDs (unique cells that map to real display pixels) ---
% Used by renderNoiseFrame to assign exactly N/2 white + N/2 black patches.
visibleMask   = validMask & ~blankMask;
validPatchIds = unique(linIdx(visibleMask))';   % row vector
nPatches      = length(validPatchIds);
if mod(nPatches, 2) ~= 0                        % ensure even count
    nPatches      = nPatches - 1;
    validPatchIds = validPatchIds(1:nPatches);
end

% ---- store everything ---------------------------------------------------
map.linIdx        = linIdx;
map.validMask     = validMask;
map.blankMask     = blankMask;
map.validPatchIds = validPatchIds;
map.nPatches      = nPatches;
map.screenW       = screenW;
map.screenH       = screenH;
map.noiseN        = noiseN;
map.fieldHalfDeg  = fieldHalfDeg;
map.pix2deg       = pix2deg;
end
