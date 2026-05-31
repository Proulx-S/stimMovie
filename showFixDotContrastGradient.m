function outPng = showFixDotContrastGradient(Lcolor, Lgray, style, outPng)
% SHOWFIXDOTCONTRASTGRADIENT  Visualise the red fixation-dot step vs p.fixDot.contrast.
%
% Renders a left-to-right gradient of p.fixDot.contrast (0..1). The detection
% task's step is the difference between two stimulus states at each contrast:
%   high state (constant) = full chroma     : satHigh * Cmax
%   low  state (varies)   = (1 - contrast)  : satLow  * Cmax
% Both coloured states share lightness Lcolor and hue 40 deg (red); only
% saturation/chroma changes, matching the isoluminant design in
% scaledNoiseMovieWithRedFix.m.
%
% The neutral C=0 reference stripes/frame have their OWN lightness, Lgray,
% fully independent of Lcolor -- so Lcolor controls ONLY the coloured stripes
% and Lgray controls ONLY the gray. Set them apart to introduce a deliberate
% luminance contrast between stimulus and reference.
%
% Cmax (max in-gamut chroma) depends on Lcolor: it peaks near L=53 (the sRGB
% red corner) and falls off either side, so the step shrinks as Lcolor moves
% away.
%
% Two styles:
%   'plain'  - low state (top) over high state (bottom), one C=0 gray separator.
%   'strips' - both states combed into NSTRIP horizontal bands separated by
%              full-thickness neutral C=0 gray reference stripes, the two states
%              abutting directly (no separator between them), the whole wrapped
%              in a C=0 gray frame.
%
% Usage:
%   showFixDotContrastGradient                       % Lcolor=50, Lgray=50, strips
%   showFixDotContrastGradient(40)                   % coloured L=40, gray L=50
%   showFixDotContrastGradient(40, 70)               % coloured L=40, gray L=70
%   showFixDotContrastGradient(50, 50, 'plain')      % plain two-band version
%   showFixDotContrastGradient(50, 50, 'strips', '') % display, do not save
%
% Inputs (all optional, positional):
%   Lcolor   lightness of the coloured stripes   [0..100], default 50
%   Lgray    lightness of the neutral C=0 gray    [0..100], default 50
%   style    'plain' | 'strips',                            default 'strips'
%   outPng   output path; [] = default name, '' = no save, else explicit path
%
% Default output name (when outPng is []), in the project folder:
%   fixDotContrastGradient[_strips]_L<NN>.png            when Lgray == Lcolor
%   fixDotContrastGradient[_strips]_Lc<NN>_Lg<NN>.png    when they differ
% Returns the path written ('' if nothing saved).
%
% Note: the visible step is perceptually compressive in contrast (CIEDE2000
% high-chroma weighting), so equal contrast spacing is NOT equal perceptual
% spacing -- space levels finer at the low-contrast (hard) end for staircases.

if nargin < 1 || isempty(Lcolor); Lcolor = 50;       end
if nargin < 2 || isempty(Lgray);  Lgray  = 50;       end
if nargin < 3 || isempty(style);  style  = 'strips'; end
if nargin < 4;                     outPng = [];       end   % [] -> name, '' -> no save

H = 40;                                  % LCH hue, red
GRAY = 90; STIM = 90; NSTRIP = 4;        % stripe geometry (px / count)

thisDir = fileparts(mfilename('fullpath'));
addpath(thisDir);

Cmax = lchMaxChroma(Lcolor, H, 0.01);
W = 1200;
c0   = lch2srgb(Lgray,  0,    H);        % C=0 neutral reference at Lgray
high = lch2srgb(Lcolor, Cmax, H);        % constant high state at Lcolor

% low-state row: chroma = (1-contrast)*Cmax across columns, at Lcolor
lowRow = zeros(W,3);
for x = 1:W
    lowRow(x,:) = lch2srgb(Lcolor, (1-(x-1)/(W-1))*Cmax, H);
end

switch style
    case 'plain'
        band = 200; gap = 40;
        img = zeros(2*band+gap, W, 3);
        for ch = 1:3
            img(band+gap+1:end,:,ch) = repmat(lowRow(:,ch)', band, 1);  % top = low
            img(1:band,:,ch)         = high(ch);                         % bottom = high
            img(band+1:band+gap,:,ch)= c0(ch);                           % C=0 separator
        end
        gradFrac = 0.82; highFrac = 0.18;
        stem = 'fixDotContrastGradient';

    case 'strips'
        seg = {};
        seg(end+1,:) = {'C0',GRAY};
        for k=1:NSTRIP; seg(end+1,:)={'grad',STIM}; if k<NSTRIP; seg(end+1,:)={'C0',GRAY}; end; end %#ok<AGROW>
        for k=1:NSTRIP; seg(end+1,:)={'high',STIM}; if k<NSTRIP; seg(end+1,:)={'C0',GRAY}; end; end %#ok<AGROW>
        seg(end+1,:) = {'C0',GRAY};
        Htot = sum(cell2mat(seg(:,2)));
        content = zeros(Htot, W, 3);
        r = 1; gradCtr = zeros(1,NSTRIP); highCtr = zeros(1,NSTRIP); ig = 0; ih = 0;
        for s = 1:size(seg,1)
            h = seg{s,2}; rows = r:r+h-1;
            switch seg{s,1}
                case 'C0';   for ch=1:3; content(rows,:,ch)=c0(ch);   end
                case 'high'; for ch=1:3; content(rows,:,ch)=high(ch); end
                             ih = ih+1; highCtr(ih)=mean(rows);
                case 'grad'; for ch=1:3; content(rows,:,ch)=repmat(lowRow(:,ch)',h,1); end
                             ig = ig+1; gradCtr(ig)=mean(rows);
            end
            r = r + h;
        end
        side = zeros(Htot, STIM, 3);             % vertical gray frame
        for ch=1:3; side(:,:,ch)=c0(ch); end
        img = [side, content, side];
        gradFrac = mean(gradCtr)/Htot; highFrac = mean(highCtr)/Htot;
        stem = 'fixDotContrastGradient_strips';

    otherwise
        error('style must be ''plain'' or ''strips'' (got ''%s'')', style);
end

% contrast tick positions, normalised to full image width (gradient region only)
Wtot = size(img,2); off = (Wtot - W)/2;          % left frame width (0 for plain)
ticks = 0:0.1:1;
xpos  = (off + ticks*(W-1) + 0.5) / Wtot;

f = figure('Color','w','Position',[0 0 1340 620]);
ax = axes('Parent',f,'Position',[0.13 0.16 0.84 0.72]);
image(ax,'XData',[0 1],'YData',[0 1],'CData',img);
set(ax,'YDir','reverse'); xlim(ax,[0 1]); ylim(ax,[0 1]);
set(ax,'YTick',[],'XTick',xpos,'XTickLabel',compose('%.1f',ticks),'FontSize',11);
xlabel(ax,'p.fixDot.contrast','FontSize',13);
if Lgray == Lcolor; Lstr = sprintf('L=%d', Lcolor);
else;               Lstr = sprintf('L_{color}=%d, L_{gray}=%d', Lcolor, Lgray); end
ttl = 'Red fixation dot step'; if strcmp(style,'strips'); ttl=[ttl ' with C=0 reference frame']; end
title(ax,sprintf(['%s  (%s, hue=%d' char(176) ', C_{max}=%.0f)'],ttl,Lstr,H,Cmax),'FontSize',12);
text(ax,-0.015, gradFrac, 'low state (gradient)','Rotation',90, ...
     'HorizontalAlignment','center','FontSize',11);
text(ax,-0.015, highFrac, 'high state','Rotation',90, ...
     'HorizontalAlignment','center','FontSize',11);

% resolve output path: [] (numeric default) -> build name; '' (char) -> no save
if isnumeric(outPng)
    if Lgray == Lcolor; outPng = sprintf('%s_L%02d.png', stem, Lcolor);
    else;               outPng = sprintf('%s_Lc%02d_Lg%02d.png', stem, Lcolor, Lgray); end
end
if ~isempty(outPng)
    if ~(any(outPng=='/') || any(outPng=='\')); outPng = fullfile(thisDir, outPng); end
    exportgraphics(f, outPng, 'Resolution', 150);
    fprintf('Saved %s  (Lcolor=%d, Lgray=%d, style=%s, Cmax=%.1f)\n', ...
            outPng, Lcolor, Lgray, style, Cmax);
else
    outPng = '';
end
end
