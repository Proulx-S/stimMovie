% doIt.m — entry point for stimMovieForEprime.
% Each stimulus function returns its defaults when called with no argument
% and prints them to the terminal. Override specific fields here, then run.

clear; close all;

%% ── paths ────────────────────────────────────────────────────────────────
thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

%% ════════════════════════════════════════════════════════════════════════
%  scaledNoiseMovieWithRedFix
%% ════════════════════════════════════════════════════════════════════════
p = scaledNoiseMovieWithRedFix();          % get defaults (also prints them)

% ── overrides ─────────────────────────────────────────────────────────────
p.output.folder = fullfile(thisDir, 'noise_stimulus_1min');

nRunON  = 2;
nRunOFF = 2;
scaledNoiseMovieWithRedFix(p, nRunON, nRunOFF);
