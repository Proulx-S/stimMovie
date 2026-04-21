function Cmax = lchMaxChroma(L, H_deg, tol)
% LCHMAXCHROMA  Binary-search for the maximum LCH chroma within sRGB gamut.
%
% Usage:
%   Cmax = lchMaxChroma(L, H_deg)
%   Cmax = lchMaxChroma(L, H_deg, tol)   % tolerance in chroma units (default 0.1)

if nargin < 3 || isempty(tol); tol = 0.1; end

Clo = 0;   % always in gamut (no chroma = grey)
Chi = 250; % safely above any sRGB gamut limit

while Chi - Clo > tol
    Cmid = (Clo + Chi) / 2;
    [~, rgb_raw] = lch2srgb(L, Cmid, H_deg);   % check pre-clamp values
    if all(rgb_raw >= 0) && all(rgb_raw <= 1)
        Clo = Cmid;
    else
        Chi = Cmid;
    end
end

Cmax = Clo;
end
