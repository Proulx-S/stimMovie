% doIt.m — entry point for stimMovieForEprime.
% Each stimulus function returns its defaults when called with no argument
% and prints them to the terminal. Override specific fields here, then run.

clear; close all;
% figure('MenuBar', 'none', 'ToolBar', 'none');

%% ── paths ────────────────────────────────────────────────────────────────
thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

%% ════════════════════════════════════════════════════════════════════════
%  scaledNoiseMovieWithRedFix
%% ════════════════════════════════════════════════════════════════════════
p = scaledNoiseMovieWithRedFix();          % get defaults (also prints them)

% ── overrides ─────────────────────────────────────────────────────────────
p.output.folder = fullfile('/local/users/Proulx-S/stim', 'scaledNoiseMovieWithRedFix/stim');
% p.output.folder = fullfile('~/RemoteServer/takoyakiLocal/stim', 'scaledNoiseMovieWithRedFix/stim');
p.temporal.durationS =  120; % seconds
p.output.quality     =   70; % JPEG quality for Motion JPEG AVI (0–100)
p.fixDot.contrast    = 0.75; % step reduction in color contrast (chroma) of the red fixation dot (0–1)
p.fixDot.L           =   40;   % LCH lightness of fixation dot  (L*) (0–100)

nRunON  = 30;
nRunOFF = 30;
scaledNoiseMovieWithRedFix(p, nRunON, nRunOFF);
