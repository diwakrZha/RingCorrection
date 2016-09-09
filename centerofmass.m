% PURPOSE: find c of m of distribution
function [cmx,cmy,smx,smy,imcm] = centerofmass(m)
imcm=m-median(m(:));
%imcm=m;
X_hist=sum(imcm,1); 
Y_hist=sum(imcm,2); 
[M,N]=size(imcm);

X=1:N; Y=1:M; 

centX=sum(X.*X_hist)/sum(X_hist); 
centY=sum(Y'.*Y_hist)/sum(Y_hist);


[sizey,sizex] = size(imcm);


vx = sum(imcm);
vy = sum(imcm');

vx = vx.*(vx>0);
vy = vy.*(vy>0);

x = 1:sizex;
y = 1:sizey;

cmx = sum(vx.*x)/sum(vx);
cmy = sum(vy.*y)/sum(vy);

smx = sqrt(sum(vx.*(abs(x-cmx).^2))/sum(vx));
smy = sqrt(sum(vy.*(abs(y-cmy).^2))/sum(vy));