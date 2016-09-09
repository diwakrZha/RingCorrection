function [imcorr,ring_im,im2,inv_pyra,medpolar] = dj_remove_rings_v2(im, thres,angSample,showresults)
% [imcorr,ring_im,im2,medpolar,mask] = remove_rings_17102006(im, tol)
%
% Remove ring artefacts from image.
%
% Input:
%   im          - image to be corrected for rings, must be 2 dimensional with center
%                 of rotation at the center of the image
%   thres       - threshold value (1 dimensional, scalar) used for
%                 presegmentation of the image OR segmentation mask with the same size
%                 as im with labels 0..N for each component in the image
%
% Output:
%   ring_im     - image containing rings of the image
%   im2         - image containing the presegmented image. Mostly for debugging
%   medpolar    - median filtered image. Used for input to vertical artefact
%                 correction
%   mask        - thresholded image from the presegmentation.
%
% 17/10/2006
% Allan Lyckegaard, Department of Material Research (AFM),
% Risoe National Laboratory, Denmark. www.riseo.dk/afm
%
% Thanks to:
% Erik M. Lauridsen, AFM - Risoe, Denmark, www.riseo.dk/afm
% Greg Johnson, ESRF, France, and University of Manchester, UK, www.man.ac.uk
% Paul Tafforeau, ESRF, France, www.esrf.fr

% Modified 5/1/2007 Greg Johnson
% returns the corrected image, not just the rings
% handles non-square images

% Modified 26.02.2013 Diwaker Jha
% Speed up, enhanced background correction
% handles non centred rings
%% inits
disp('Removing rings: ')
% square image if it is not, and store the size for later cropping
[size_orig_rows,size_orig_columns]=size(im);
%imorig=im;

if size_orig_rows>size_orig_columns  % more rows that columns
  topleftx=(size_orig_rows-size_orig_columns)/2;toplefty=1;
  im=gtPlaceSubImage(im,zeros(size_orig_rows),topleftx,toplefty);
elseif size_orig_rows<size_orig_columns
  topleftx=1;toplefty=(size_orig_columns-size_orig_rows)/2;
  im=gtPlaceSubImage(im,zeros(size_orig_columns),topleftx,toplefty);
else
  topleftx=1;toplefty=1;
end

% timings
t_rr = zeros(1,9);

% rows numbers for filtering/pyramid scaling
frows =  round(size(im,1)/sqrt(2));
srows =  floor(frows/3);

% angular resolution
theta = 360*angSample;

% filter setup
blur_len = 150; % 150??
fusion_len = 30; % 30 ??
h_blur = fspecial('gaussian',[1 blur_len], blur_len/6);
h_fusion = fspecial('gaussian',[1 fusion_len], fusion_len/6);

disp('-')

%% remove absorption info of the sample and background if it is not zero
[im2 mask]= presegmentation (im, thres);
%bg=(ones(size_orig_rows,size_orig_columns)) *median(im(:));
%outIm = ((im > bg + thres) | (im < bg - thres));
%im2=outIm;
assignin('base','preseg',im2);
disp('--')

%% convert from Cartesian to polar coordinates
%polar = polartrans(im2, round(sqrt(sum(size(im2).^2))/2), theta); %/2
polar=polartrans(im2, round(sqrt(sum(size(im2).^2))/2), theta);
assignin('base','impolar',polar);
disp('---')
%imshow(polar,[]);
%colormap ('gray');
%axis 'square';

%% removal of phase contrast, smaller details in image etc.
medpolar = medfilt2(polar,[1 200],'symmetric');

%% correction of low frequency content in image
lowfreq = zeros(size(medpolar));
lowfreq(1:frows,:) = imresize(medfilt2(imresize(medpolar(1:frows,:),0.25),[8 8],'symmetric'),[frows,theta]);
medpolar = medpolar-lowfreq;
disp('----')

%% split into upper/lower part: 0-180 deg. / 180-360 deg.
upper_pol = medpolar(:,1:end/2);
lower_pol = medpolar(:,end/2+1:end);

%% pyramid tranformation of upper/lower part
pyra_up = upper_pol;
pyra_lo = lower_pol;
scale = linspace(0.2,1,srows);
[pyra_up(1:srows,:),pmask] = pyramid_transform(upper_pol(1:srows,:),scale);
pyra_lo(1:srows,:) = pyramid_transform(lower_pol(1:srows,:),scale);
disp('-----')

%% horizontal linear motion blur
blur_up = pyra_up;
blur_lo = pyra_lo;
blur_up(1:frows,:) = imfilter(pyra_up(1:frows,:),h_blur,'symmetric');
blur_lo(1:frows,:) = imfilter(pyra_lo(1:frows,:),h_blur,'symmetric');

disp('------')

%% inverse pyramid transformation
inv_pyra_up = blur_up;
inv_pyra_lo = blur_lo; 
inv_pyra_up(1:srows,:) = invpyramid_transform(blur_up(1:srows,:),pmask);
inv_pyra_lo(1:srows,:) = invpyramid_transform(blur_lo(1:srows,:),pmask);
disp('-------')

%% assemble upper/lower part again and blur
inv_pyra = [inv_pyra_up, inv_pyra_lo];
inv_pyra(1:frows,:) = imfilter(inv_pyra(1:frows,:),h_fusion,'circular');
inv_pyra(isnan(inv_pyra))=0;
%assignin('base','inv_pyra',inv_pyra);
%% correction of low frequency content in image
lowfreq = zeros(size(inv_pyra));
lowfreq(1:frows,:) = imresize(medfilt2(imresize(inv_pyra(1:frows,:),0.25),[8 8],'symmetric'),[frows,theta]);
inv_pyra = inv_pyra-lowfreq;

%% polar into cartesian coordinates
% this will give us the ring artifacts
ring_im = invpolar2(inv_pyra,size(im,1));
assignin('base','ring_im',ring_im);
imcorr=im-ring_im;
ring_im=ring_im(toplefty:toplefty+size_orig_rows-1,topleftx:topleftx+size_orig_columns-1);
imcorr=imcorr(toplefty:toplefty+size_orig_rows-1,topleftx:topleftx+size_orig_columns-1);
disp('---------')
end