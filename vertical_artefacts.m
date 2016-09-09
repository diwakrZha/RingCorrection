function vert = vertical_artefacts(medpolar,rings);
% vert = vertical_artefacts(medpolar,rings);
%
% Correct image for vertical artifacts. STILL EXPERIMENTAL!
%
% Input:
%   medpolar     - median filtered image outputtet from remove_rings().
%   rings        - ring image outputtet from remove_rings().
%
% Output:
%   vert        - vertical artefact image
%
% 17/10/2006
% Allan Lyckegaard, Department of Material Research (AFM),
% Risoe National Laboratory, Denmark. www.riseo.dk/afm
%
% Thanks to:
% Erik M. Lauridsen, AFM - Risoe, Denmark, www.riseo.dk/afm
% Greg Johnson, ESRF, France, and University of Manchester, UK, www.man.ac.uk
% Paul Tafforeau, ESRF, France, www.esrf.fr

h_vert = ones(10,1)/10; %gaussian ??

medcart = invpolar2(medpolar,size(rings,1));

if mod(size(rings,1),2)==0 % if even
    vert = [imfilter(medcart(1:end/2,:)-rings(1:end/2,:),h_vert,'symmetric'); ...
    imfilter(medcart(end/2+1:end,:)-rings(end/2+1:end,:),h_vert,'symmetric')];
else % odd
    up = imfilter(medcart(1:end/2+0.5,:)-rings(1:end/2+0.5,:),h_vert,'symmetric');
    lo = imfilter(medcart(end/2+0.5:end,:)-rings(end/2+0.5:end,:),h_vert,'symmetric');
    vert = [up(1:end-1,:), (up(end,:)+lo(1,:))/2; lo(2:end,:)];
end