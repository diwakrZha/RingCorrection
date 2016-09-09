function [im2,mask]= presegmentation (im, thres)
% if thres hold is a scaler
if numel(thres)==1
    % resize mask (faster computation) -> fill the holes inside the mask 
    % -> resize back to original size
    % for Maria's image, the rings are deep and close to the center
    %level = 0.03%graythresh(im)+0.0078
    %level = graythresh(im)
    %mask = im2bw(im,level);
    
    %revive it in case the image is too large.
    mask = imresize(imfill(imresize(im,0.25)>thres,'holes'),size(im));
    
    %mask = imresize(imfill(imresize(im,0.25)>thres,'holes'),[size(im)]);
    
    if sum(mask(:)) == 0
      disp('Threshold is too high...(might be outside sample)')
      imcorr=ones(size(im))*mean(im(:));
      return
    end
    size(mask);
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
%figure;
%imagesc(im2);colormap(gray);
%figure;
%imagesc(mask);colormap(gray);
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