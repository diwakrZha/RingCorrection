function [pyraim,pmask] = pyramid_transform(pim,scale)
% [pyraim,pmask] = pyramid_transform(pim,scale)
%
% Perform a pyramid transformation of an image.
%
% Input:
%   pim          - image to be pyramid transformed.
%   scale        - vector with scaling values for the transformation
%
% Output:
%   pyraim      - image containing pyramid transformation of the image
%   pmask       - binary mask showing the transformation.
%
% 17/10/2006
% Allan Lyckegaard, Department of Material Research (AFM),
% Risoe National Laboratory, Denmark. www.riseo.dk/afm
%
% Thanks to:
% Erik M. Lauridsen, AFM - Risoe, Denmark, www.riseo.dk/afm
% Greg Johnson, ESRF, France, and University of Manchester, UK, www.man.ac.uk
% Paul Tafforeau, ESRF, France, www.esrf.fr


% pim has radius along dim(1)
dim = size(pim);
pyraim = repmat(mean(pim,2),[1 dim(2)]);
pmask = false(dim);

if not(isequal(dim(1),length(scale)))
    error('size(pim,1) must be the same as length(scale)');
end

if mod(dim(2),2)==0
    % even size
    for r=1:dim(1)
        width = max(2*round(dim(2)*scale(r)/2),2); % make shure it has width>0
        pyraim(r,end/2+1+[-width/2:width/2-1]) = imresize(pim(r,:),[1 width]);
        pmask(r,end/2+1+[-width/2:width/2-1]) = ones(1,width);
    end
else
    % odd size
    for r=1:dim(1)
        width = max(2*floor(dim(2)*scale(r)/2)+1,1); % make shure it has width>0
        pyraim(r,end/2+[-width/2+1:width/2]) = imresize(pim(r,:),[1 width]);
        pmask(r,end/2+[-width/2+1:width/2]) = true(1,width)
    end
end