

function iclean=spikes(ispiked,limit,varargin);

if nargin>2
	out=varargin{1};
else
	out=0;
end



[n m]=size(ispiked);

iav=medfilt2(ispiked);
dirt=abs(ispiked-iav)>limit;
dirt([1 n],[1 m])=zeros(2);
if out
	disp(sprintf('%d pixels changed in the image',sum(sum(dirt))))
end



iclean=(dirt).*iav+(1-dirt).*ispiked;

