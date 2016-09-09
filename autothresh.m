function threshold=autothresh(im)
% AUTOTHRESH.M
% Uses graythresh (Otsu's method) (from Image Processing Toolbox) but rescales to limits of
% data first.  Returns a value suitable for the ring correction code
%
% January 2007, Greg Johnson

im=double(im);  % data must be cast to double before manipulation
im=im(:);
% find range of data
minim=min(im);
maxim=max(im);

% scale image to range [0..1]
threshold=graythresh(im)*(maxim-minim) + minim;

