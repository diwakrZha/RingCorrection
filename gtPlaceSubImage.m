function im_big=gtPlaceSubImage(im_small,im_big,topleftx,toplefty)
% GTPLACESUBIMAGE Place a small image within a larger one
% Usage:
%     imbig=gtPlaceSubImage(imsmall,imbig,topleftx,toplefty)
%     imsmall is the image to place
%     imbig is the image to place it into
%     topleftx/y is the location of the top left corner of the placement
% 
%  The final image is the same size as imbig, no matter where the imsmall
%  is placed

% Greg Johnson, September 2006

sz_big=size(im_big);
sz_small=size(im_small);
im_big(toplefty:toplefty+sz_small(1)-1,topleftx:topleftx+sz_small(2)-1)=im_small;
im_big=im_big(1:sz_big(1),1:sz_big(2));
