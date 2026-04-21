function statePerFrame = makeFixDotSchedule(durationS, fps, tMinS, tMaxS)
% MAKEFIXDOTSCHEDULE  Pre-generate per-frame fixation-dot state (0=low, 1=high).
%
% Two saturation levels alternate; the time spent in each state is drawn
% independently from Uniform[tMinS, tMaxS] — adapted from the unifrnd ISI
% in RetinoStimulator_VSBlock_NOISE.m (colleagues' toolbox).
%
% Inputs:
%   durationS  - total movie duration (s)
%   fps        - movie frame rate (Hz)
%   tMinS      - minimum time in each state (s)
%   tMaxS      - maximum time in each state (s)
%
% Output:
%   statePerFrame - [1 x nFrames] array of 0 (low) or 1 (high)

nFrames = round(durationS * fps);

changeTimes  = 0;   % first "change" at t=0: initial state
stateAtChange = 0;  % start in low state

t     = 0;
state = 0;
while t < durationS
    t     = t + unifrnd(tMinS, tMaxS);
    state = 1 - state;            % toggle between 0 and 1
    changeTimes(end+1)   = t;     %#ok<AGROW>
    stateAtChange(end+1) = state; %#ok<AGROW>
end

statePerFrame = zeros(1, nFrames);
for f = 1:nFrames
    t_f = (f - 1) / fps;
    idx = find(changeTimes <= t_f, 1, 'last');
    statePerFrame(f) = stateAtChange(idx);
end
end
