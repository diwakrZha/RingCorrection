im=edfread('refHST0000.edf')';

mask=frelon4m_mask;
j=roifill(im,mask);

%roix=[500:600];
%roiy=[1:100];
roix=1:size(mask,2);
roiy=1:size(mask,1);
if 0
  figure(1)
  hold off
  clims=stretchlim2(im(roiy,roix),0.02);
  h(1)=imshow(im(roiy,roix),clims);
  axis on
  hold on


  cmask=cat(3,mask(roiy,roix),zeros(length(roiy),length(roix),2));
  h(2)=image(cmask);
  set(h(2),'alphadata',0.1)
end

figure(2)
hold off
imshow(j(roiy,roix),clims,'initialmagnification',400),axis on
hold on
h(3)=image(cmask)
set(h(3),'alphadata',0.3)
shg
zoom on
figure(3)
imtool(j(roiy,roix),[])
%close all



% fix the image by linear interpolation
% for each bad pixel, find shortest line to two good pixels
% then interpolate between

[rows,cols]=find(mask);

  
