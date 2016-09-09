function rename2HST(scanname,nproj,ndark)

pixsize=1.6
name=sprintf('DARK_%s__%04d.edf',scanname,0);
info=edf_info(name);
d=zeros(ndark+1,info.dim_2,info.dim_1);

disp('summing flat field');
for i=0:ndark
  d(i+1,:,:)=edf_read(sprintf('DARK_%s__%04d.edf',scanname,i));
end
d=squeeze(median(d));
edf_write(d,'dark.edf','uint16');  

disp('filtering reference images');
f=zeros(ndark+1,info.dim_2,info.dim_1);
for i=0:ndark
  f(i+1,:,:)=edf_read(sprintf('FLAT_%s__000_%04d.edf',scanname,i));
end
f=squeeze(median(f));
name=sprintf('refHST%04d.edf',nproj);
edf_write(f,'refHST0000.edf','uint16');
edf_write(f,name,'uint16');

disp('creating symbolic links');
for i=0:nproj
  command=sprintf('ln -s %s__000_%04d.edf %s%04d.edf',scanname,i,scanname,i);
  unix(command);
end  


name=sprintf('%s.info',scanname);
fid=fopen(name,'w');
fprintf(fid,'TOMO_N=\t%d\n',nproj);
fprintf(fid,'REF_ON=\t%d\n',nproj);
fprintf(fid,'REF_N=\t%d\n',ndark);
fprintf(fid,'DARK_N=\t%d\n',ndark);
fprintf(fid,'Optic used=\t%f\n',pixsize);
fclose(fid);
end