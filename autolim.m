function [cmaprange]=autolim(varargin)
% AUTOLIM.M
% Uses stretchlim (from Image Processing Toolbox) but rescales to limits of
% data first.  Returns a range pair suitable for use in imshow or imagesc.
%
% May 2006, Greg Johnson

im=double(varargin{1});  % data must be cast to double before manipulation
if nargin==2
  percentile=varargin{2};
else
  percentile=0.02;  % 2 percent by default
end
im=im(:);
% find range of data
minim=min(im);
maxim=max(im);

% scale image to range [0..1]
im=(im-minim)./(maxim-minim);


slim=stretchlim(im,percentile)';
cmaprange=(slim.*(maxim-minim))+minim;
