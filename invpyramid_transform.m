function pim = invpyramid_transform(pyraim,pmask)
% pim = invpyramid_transform(pyraim,pmask)
%
% Perform an inverse pyramid transformation of an image.
%
% Input:
%   pyraim      - image containing a previously pyramid transformed image
%   pamsk       - binary mask showing the transformation.
% Output:
%   pim          - inverse pyramid transformed image.
%
% 17/10/2006
% Allan Lyckegaard, Department of Material Research (AFM),
% Risoe National Laboratory, Denmark. www.riseo.dk/afm
%
% Thanks to:
% Erik M. Lauridsen, AFM - Risoe, Denmark, www.riseo.dk/afm
% Greg Johnson, ESRF, France, and University of Manchester, UK, www.man.ac.uk
% Paul Tafforeau, ESRF, France, www.esrf.fr

% pyraim has radius along dim(1)

if not(size(pyraim)==size(pmask))
    error('size(pyraim) must be the same as size(pmask)');
end

dim = size(pyraim);

pim = zeros(dim);
nvec = 1:dim(2);

for r=1:dim(1)
    cols = pmask(r,:).*nvec;
    pim(r,:) = imresize(pyraim(r,min(cols(pmask(r,:))):max(cols(pmask(r,:)))),[1 dim(2)]);
end