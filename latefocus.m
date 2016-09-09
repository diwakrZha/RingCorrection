im=zeros(1024,1024,31);
darkname='alagL1_0003.edf';
% 119 or 142
start=128;
for n=1:31
  fname=sprintf('alagL1_%04d.edf',start+((n-1)*2)+1);
  refname=sprintf('alagL1_%04d.edf',start+((n-1)*2));
  im(:,:,n)=flat(fname,refname,darkname);
end

%%
for m=1:n-1
  
  imagesc(im(:,:,m),[0 1])
  title(num2str(m))
  pause(0.8)
end  
