%2D Gaussian fitting 
%Author: Diwaker Jha
%Last revision: 08.01.2013

function [sf]=Gaussian2D(accum_short,bg,a1,x0,y0)
[h,w] = size(accum_short);
[X,Y] = meshgrid(1:h,1:w);
X = X(:); Y=Y(:); Z = accum_short(:);
%a1=5464;x0=134;y0=140;

% 2D gaussian fit object
gauss2 = fittype( @(bg,a1, sigmax, sigmay, x0,y0, x, y) bg+a1*exp(-(x-x0).^2/(2*sigmax^2)-(y-y0).^2/(2*sigmay^2)),...
'independent', {'x', 'y'},'dependent', 'z' );

% multivariate gaussian fit
%multiGauss2 = fittype( @(bg,a1, Sigma, x0,y0, x, y) mvnpdf([X(:) Y(:)],mu,Sigma);
%
%a1 = max(accum_short(:)); % height, determine from image. may want to subtract background
sigmax = 5; % guess width
sigmay = 5; % guess width

% compute fit
sf = fit([X,Y],double(Z),gauss2,'StartPoint',[bg,a1, sigmax, sigmay, x0,y0]);
%figure(6); clf; plot(sf,[X,Y],Z);
end
