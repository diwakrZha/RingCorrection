function [padim,mask] = padim(im,centre)
% padim = padim(im,centre);
%
% Pad a cropped reconstructed image so the centre of rotation is in the center of
% the image.
%
% Input:
%   im           - cropped image
%   centre       - centre of rotation in cropped image, [row col]
%                  if centre is between four pixels add [0.5 0.5]
%
% Output:
%   padim        - padded image with centre of rotation in the centre
%
% 17/10/2006
% Allan Lyckegaard, Department of Material Research (AFM),
% Risoe National Laboratory, Denmark. www.riseo.dk/afm
%
% Thanks to:
% Erik M. Lauridsen, AFM - Risoe, Denmark, www.riseo.dk/afm
% Greg Johnson, ESRF, France, and University of Manchester, UK, www.man.ac.uk
% Paul Tafforeau, ESRF, France, www.esrf.fr

dim = size(im);

if round(centre)==centre % centre is on a pixel, ie. odd padim size
    centre = centre-0.5;
    maxr = max(dim(1)-centre(1),centre(1));
    maxc = max(dim(2)-centre(2),centre(2));
    maxrad = ceil(sqrt(maxr^2 + maxc^2));
    
    padim = zeros(2*maxrad+1);
    mask = zeros(2*maxrad+1);
    rows = (1:dim(1))-centre(1) + maxrad + 0.5;
    cols = (1:dim(2))-centre(2) + maxrad + 0.5;
    padim(rows, cols) = im;
    mask(rows, cols) = 1;
else % centre is in the middle of 4 pixels
    centre = centre-0.5;
    maxr = max(dim(1)-centre(1),centre(1));
    maxc = max(dim(2)-centre(2),centre(2));
    maxrad = ceil(sqrt(maxr^2 + maxc^2));
    
    padim = zeros(2*maxrad);
    mask = zeros(2*maxrad);
    rows = (1:dim(1))-centre(1) + maxrad;
    cols = (1:dim(2))-centre(2) + maxrad;
    padim(rows, cols) = im;
    mask(rows, cols) = 1;
end