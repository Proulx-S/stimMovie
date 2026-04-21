function frame = renderNoiseFrame(map, lo, hi, bgGray)
% RENDERNOISEFRAME  Generate one eccentricity-scaled binary noise frame.
%
% Exactly half of the visible log-polar patches are set to hi (white) and
% half to lo (black), chosen by random permutation each call.
% This guarantees zero luminance bias and eliminates the systematic seam
% at the negative-x axis that appears with fully independent per-cell noise.
%
% Usage:
%   frame = renderNoiseFrame(map, lo, hi, bgGray)
%
% Inputs:
%   map     - struct returned by makeLogPolarMap
%   lo      - dark  pixel value (uint8, e.g. 0)
%   hi      - bright pixel value (uint8, e.g. 255)
%   bgGray  - background / fixation-region value (uint8, e.g. 119 for L*=50)

% ---- assign exactly N/2 white, N/2 black to the visible patches ---------
perm     = randperm(map.nPatches);
noiseGrid = repmat(lo, map.noiseN, map.noiseN);
noiseGrid(map.validPatchIds(perm(1 : map.nPatches/2))) = hi;

% ---- warp to screen via precomputed indices -----------------------------
frame = reshape(noiseGrid(map.linIdx), map.screenH, map.screenW);

% ---- fill singularity and blank centre disc with background gray ---------
frame(~map.validMask) = bgGray;
frame(map.blankMask)  = bgGray;
end
