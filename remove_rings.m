function [imcorr,ring_im,im2,medpolar,mask] = remove_rings(im, thres,showresults);
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
tic
%% inits

% square image if it is not, and store the size for later cropping
[size_orig_rows,size_orig_columns]=size(im);
imorig=im;
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
t = zeros(1,9);

% rows numbers for filtering/pyramid scaling
frows =  round(size(im,1)/sqrt(2));
srows =  floor(frows/3);

% angular resolution
theta = 360*4;

% filter setup
blur_len = 100; % 150??
fusion_len = 50; % 30 ??
h_blur = fspecial('gaussian',[1 blur_len], blur_len/6);
h_fusion = fspecial('gaussian',[1 fusion_len], fusion_len/6);

t(1) = toc; tic;
disp('PART 1')
%% remove absorption info of the sample and background if it is not zero
% if thres hold is a scaler
if prod(size(thres))==1
    % resize mask (faster computation) -> fill the holes inside the mask 
    % -> resize back to original size
    mask = imresize(imfill(imresize(im,0.25)>thres,'holes'),[size(im)]);
    
    if sum(mask(:)) == 0
      disp('Threshold is too high...(might be outside sample)')
      imcorr=ones(size(imorig))*mean(imorig(:));
      return
    end
    size(mask)
    % find std. dev. and mean inside the mask (sample)
    sd = std(im(mask));
    mm = mean(im(mask));
    
    % remove outliers and find mean of the inliers
    mv = mean(im(im>(mm-2*sd) & im<(mm+2*sd)));
    im2 = im-mask*mv;
    
    % find std. dev. and mean outside the mask (background)    
    sd = std(im(not(mask)));
    mm = mean(im(not(mask)));
    
    % remove outliers and find mean of the inliers
    mv = mean(im(im>(mm-2*sd) & im<(mm+2*sd)));
    im2 = im2-not(mask)*mv;

% if thres is a labelled mask
elseif size(thres)==size(im)
    mask = thres;
    im2 = im;
    % run through each label and remove the corresponding mean of the label
    for i=0:max(thres(:))
        mm = mean(im(mask==i));
        im2 = im2 -(mask==i)*mm;
    end
else
    error('Check thres size');
end
t(2) = toc; tic;
disp('PART 2')
%% convert from Cartesian to polar coordinates
polar = polartrans(im2, round(sqrt(sum(size(im2).^2))/2), theta); %/2
t(3) = toc; tic;
disp('PART 3')
%% removal of phase contrast, smaller details in image etc.
medpolar = medfilt2(polar,[1 49],'symmetric');

%% correction of low frequency content in image
%lowfreq = zeros(size(medpolar));
%lowfreq(1:frows,:) = imresize(medfilt2(imresize(medpolar(1:frows,:),0.25),[15 15],'symmetric'),[frows,theta]);
%medpolar = medpolar-lowfreq;

t(4) = toc; tic;
disp('PART 4')
%% split into upper/lower part: 0-180 deg. / 180-360 deg.
upper_pol = medpolar(:,1:end/2);
lower_pol = medpolar(:,end/2+1:end);

%% pyramid tranformation of upper/lower part
pyra_up = upper_pol;
pyra_lo = lower_pol;
scale = linspace(0.2,1,srows);
[pyra_up(1:srows,:),pmask] = pyramid_transform(upper_pol(1:srows,:),scale);
pyra_lo(1:srows,:) = pyramid_transform(lower_pol(1:srows,:),scale);
t(5) = toc; tic;
disp('PART 5')
%% horizontal linear motion blur
blur_up = pyra_up;
blur_lo = pyra_lo;
blur_up(1:frows,:) = imfilter(pyra_up(1:frows,:),h_blur,'symmetric');
blur_lo(1:frows,:) = imfilter(pyra_lo(1:frows,:),h_blur,'symmetric');
t(6) = toc; tic;
disp('PART 6')
%% inverse pyramid transformationtoc
inv_pyra_up = blur_up;
inv_pyra_lo = blur_lo;
inv_pyra_up(1:srows,:) = invpyramid_transform(blur_up(1:srows,:),pmask);
inv_pyra_lo(1:srows,:) = invpyramid_transform(blur_lo(1:srows,:),pmask);
t(7) = toc; tic;
disp('PART 7')
%% assemble upper/lower part again and blur
inv_pyra = [inv_pyra_up, inv_pyra_lo];
inv_pyra(1:frows,:) = imfilter(inv_pyra(1:frows,:),h_fusion,'circular');
t(8) = toc; tic;
disp('PART 8')
%% correction of low frequency content in image
%lowfreq = zeros(size(inv_pyra));
%lowfreq(1:frows,:) = imresize(medfilt2(imresize(inv_pyra(1:frows,:),0.25),[15 15],'symmetric'),[frows,theta]);
%inv_pyra = inv_pyra-lowfreq;

%% polar into cartesian coordinates
% this will give us the ring artifacts
ring_im = invpolar2(inv_pyra,size(im,1));
imcorr=im-ring_im;

ring_im=ring_im(toplefty:toplefty+size_orig_rows-1,topleftx:topleftx+size_orig_columns-1);
imcorr=imcorr(toplefty:toplefty+size_orig_rows-1,topleftx:topleftx+size_orig_columns-1);

t(9) = toc;
disp('PART 9')
%% display time stamps
%disp(['Init:                ',num2str(t(1))])
%disp(['Presegmentation:     ',num2str(t(2))])
%disp(['Polar trans:         ',num2str(t(3))])
%disp(['1D medfilt:          ',num2str(t(4))])
%disp(['Pyramid trans:       ',num2str(t(5))])
%disp(['Horiz blur:          ',num2str(t(6))])
%disp(['Inv. pyramid trans:  ',num2str(t(7))])
%disp(['Fusion:              ',num2str(t(8))])
%disp(['Inv. polar trans:    ',num2str(t(9))])
%disp(['-----------------------------------'])
%disp(['Total:               ',num2str(sum(t))])

%%
if ~exist('showresults','var')
figure(1)
clf
subplot(1,2,1)
imshow(imorig,[])
subplot(1,2,2)
imshow(imcorr,[]);
drawnow
end