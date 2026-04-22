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
p.output.folder = fullfile('~/RemoteServer/takoyakiLocal/stim', '/scaledNoiseMovieWithRedFix/stim');
p.temporal.durationS = 120; % seconds

nRunON  = 50;
nRunOFF = 50;
scaledNoiseMovieWithRedFix(p, nRunON, nRunOFF);
