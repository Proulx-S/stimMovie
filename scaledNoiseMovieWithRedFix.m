function p = scaledNoiseMovieWithRedFix(p, nON, nOFF)
% SCALEDNOISEMOVIEWITHREDFIX  Eccentricity-scaled noise movie with red LCH fixation dot.
%
% Called with no argument: returns default parameter struct and prints it.
% Called with p struct: renders all requested movies.
%
% Usage:
%   p = scaledNoiseMovieWithRedFix()             % inspect / copy defaults
%   scaledNoiseMovieWithRedFix(p, nON, nOFF)     % render nON + nOFF movies
%
% Output files are written to p.output.folder and named after this function:
%   scaledNoiseMovieWithRedFix_on_NN.avi   (full contrast)
%   scaledNoiseMovieWithRedFix_off_NN.avi  (contrast=0, noise invisible)
% Each movie has its own independent noise sequence and fixation dot schedule.
% If the folder already exists a new one is created with a datetime suffix.
%
% Parameter subfields:  p.monitor  p.spatial  p.temporal  p.fixDot  p.output

if nargin == 0
    p = defaultParams();
    printParams(p);
    return;
end

if nargin < 2; nON  = 1; end
if nargin < 3; nOFF = 0; end
nTotal = nON + nOFF;

fprintf('=== scaledNoiseMovieWithRedFix ===\n');
fprintf('  Screen  : %d x %d px @ %d Hz monitor\n', ...
    p.monitor.screenW, p.monitor.screenH, p.monitor.Hz);
fprintf('  Duration: %d s  |  Flicker: %d Hz  |  Frames: %d\n', ...
    p.temporal.durationS, p.temporal.updateHz, ...
    p.temporal.durationS * p.temporal.updateHz);
fprintf('  Movies  : %d ON + %d OFF = %d total\n', nON, nOFF, nTotal);

pix2deg = p.spatial.fieldHalfDeg / (p.monitor.screenW / 2);

% ── shared setup (computed once for all movies) ───────────────────────────
fprintf('Computing log-polar map...\n');
map = makeLogPolarMap(p.monitor.screenW, p.monitor.screenH, ...
    p.spatial.fieldHalfDeg, p.spatial.noiseN, p.spatial.fixBlankRadDeg);

fY_bg   = (50 + 16) / 116;
Y_bg    = fY_bg ^ 3;
bg_srgb = 1.055 * Y_bg^(1/2.4) - 0.055;
bgGray  = uint8(round(bg_srgb * 255));   % ≈ 119 (L*=50)

halfRange = round(p.spatial.contrast * min(double(bgGray), 255 - double(bgGray)));
lo = uint8(double(bgGray) - halfRange);
hi = uint8(double(bgGray) + halfRange);

cx = (p.monitor.screenW + 1) / 2;
cy = (p.monitor.screenH + 1) / 2;
[Xg, Yg] = meshgrid(1:p.monitor.screenW, 1:p.monitor.screenH);
d2        = (Xg - cx).^2 + (Yg - cy).^2;
dotMask   = d2 <= (round(p.fixDot.radDeg      / pix2deg))^2;
outerMask = d2 <= (round(p.fixDot.outerRadDeg / pix2deg))^2;

fprintf('Computing fixation dot colours in LCH space...\n');
fixDotL = 50;
Cmax    = lchMaxChroma(fixDotL, p.fixDot.hueDeg);
fprintf('  LCH: L=%.0f, H=%.0f deg, C_max=%.1f\n', fixDotL, p.fixDot.hueDeg, Cmax);

satHigh = 1.0;
satLow  = 1.0 - p.fixDot.contrast;
dotColorHigh = uint8(round(lch2srgb(fixDotL, satHigh * Cmax, p.fixDot.hueDeg) * 255));
dotColorLow  = uint8(round(lch2srgb(fixDotL, satLow  * Cmax, p.fixDot.hueDeg) * 255));
outerColor   = bgGray;

fprintf('  High: RGB=[%d %d %d]  Low: RGB=[%d %d %d]\n', ...
    dotColorHigh, dotColorLow);

% ── resolve output folder (create; if already exists append datetime) ─────
outFolder = p.output.folder;
if exist(outFolder, 'dir')
    outFolder = [outFolder '_' datestr(now, 'yyyymmdd_HHMMSS')];
    fprintf('Output folder exists — writing to: %s\n', outFolder);
end
mkdir(outFolder);
fstem = 'scaledNoiseMovieWithRedFix';

% ── test frames (one noise frame, low + high dot state) ───────────────────
fprintf('Saving test frames...\n');
gray_test = renderNoiseFrame(map, lo, hi, bgGray);
for state = 0:1
    rgb_test = cat(3, gray_test, gray_test, gray_test);
    for ch = 1:3
        layer = rgb_test(:,:,ch);  layer(outerMask) = outerColor;  rgb_test(:,:,ch) = layer;
    end
    if state == 0;  dc = dotColorLow;   sfx = 'low';
    else;           dc = dotColorHigh;  sfx = 'high';
    end
    for ch = 1:3
        layer = rgb_test(:,:,ch);  layer(dotMask) = dc(ch);  rgb_test(:,:,ch) = layer;
    end
    tfPath = fullfile(outFolder, sprintf('%s_%s.png', fstem, sfx));
    imwrite(rgb_test, tfPath);
    fprintf('  %s\n', tfPath);
end

% ── render loop ───────────────────────────────────────────────────────────
for m = 1:nTotal

    if m <= nON
        label = 'on';
        idx   = m;
        lo_m  = lo;
        hi_m  = hi;
    else
        label = 'off';
        idx   = m - nON;
        lo_m  = bgGray;   % contrast = 0: noise invisible
        hi_m  = bgGray;
    end

    outFile = fullfile(outFolder, sprintf('%s_%s_%02d.avi', fstem, label, idx));
    fprintf('\n--- Movie %d/%d : %s ---\n', m, nTotal, outFile);

    statePerFrame = makeFixDotSchedule(p.temporal.durationS, p.temporal.updateHz, ...
        p.fixDot.changeMinS, p.fixDot.changeMaxS);

    vw = VideoWriter(outFile, 'Motion JPEG AVI');
    vw.FrameRate = p.temporal.updateHz;
    vw.Quality   = p.output.quality;
    open(vw);

    nFrames = p.temporal.durationS * p.temporal.updateHz;
    fprintf('Rendering %d frames...\n', nFrames);
    tStart = tic;

    for f = 1:nFrames
        if mod(f, 80) == 0
            elapsed = toc(tStart);
            eta     = elapsed / f * (nFrames - f);
            fprintf('  Frame %d / %d  (%.0f s elapsed, ~%.0f s remaining)\n', ...
                f, nFrames, elapsed, eta);
        end

        gray = renderNoiseFrame(map, lo_m, hi_m, bgGray);
        rgb  = cat(3, gray, gray, gray);

        for ch = 1:3
            layer = rgb(:,:,ch);  layer(outerMask) = outerColor;  rgb(:,:,ch) = layer;
        end
        dotColor = dotColorLow + uint8(statePerFrame(f)) * (dotColorHigh - dotColorLow);
        for ch = 1:3
            layer = rgb(:,:,ch);  layer(dotMask) = dotColor(ch);  rgb(:,:,ch) = layer;
        end

        writeVideo(vw, rgb);
    end

    close(vw);
    fprintf('Done in %.1f s.\n', toc(tStart));
end

fprintf('\nAll %d movie(s) saved to: %s\n', nTotal, outFolder);
end

% ═════════════════════════════════════════════════════════════════════════
function p = defaultParams()
thisDir = fileparts(mfilename('fullpath'));

p.monitor.screenW = 1920;   % screen width          (pixels)
p.monitor.screenH = 1080;   % screen height         (pixels)
p.monitor.Hz      = 60;     % display refresh rate  (Hz, informational only)

p.fixDot.hueDeg      = 40;                         % LCH hue angle, 40 for red  (degrees)
p.fixDot.contrast    = 0.5;                        % low-state saturation = 1 - contrast
p.fixDot.radDeg      = 0.15;                       % inner (coloured) dot radius (degrees)
p.fixDot.outerRadDeg = 0.15;   % outer (grey) ring radius    (degrees)
p.fixDot.changeMinS  = 3;                          % min duration of each state  (seconds)
p.fixDot.changeMaxS  = 10;                         % max duration of each state  (seconds)

p.spatial.fieldHalfDeg   = 12;    % visual field half-width          (degrees)
p.spatial.noiseN         = 512;   % cortical noise grid resolution   (pixels)
p.spatial.contrast       = 1.0;   % noise Michelson contrast         (0–1)
p.spatial.fixBlankRadDeg = p.fixDot.outerRadDeg;  % blank centre-disc radius         (degrees)

p.temporal.durationS = 60;   % total movie duration   (seconds)
p.temporal.updateHz  = 8;    % noise flicker rate     (Hz)

p.output.folder        = fullfile(thisDir, 'scaledNoiseMovieWithRedFix');  % output folder
p.output.quality       = 95;   % JPEG quality for Motion JPEG AVI (0–100)
end

% ═════════════════════════════════════════════════════════════════════════
function printParams(p)
fprintf('=== scaledNoiseMovieWithRedFix — default parameters ===\n');
groups = fieldnames(p);
for g = 1:numel(groups)
    gname = groups{g};
    fprintf('  %s\n', gname);
    sub = p.(gname);
    sfields = fieldnames(sub);
    for s = 1:numel(sfields)
        fname = sfields{s};
        val   = sub.(fname);
        if ischar(val)
            fprintf('    %-20s = ''%s''\n', fname, val);
        else
            fprintf('    %-20s = %g\n', fname, val);
        end
    end
end
fprintf('\n');
end
