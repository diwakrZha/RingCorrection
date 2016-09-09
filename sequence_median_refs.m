function sequence_median_refs
% MEDIAN_REFS
% Simple function to generate median image for each set of reference images
% in a scan.  Works on reference files found in current directory, and only
% overwrites if explicitly told to.

% find scan name (same as directory name)
%[tmp,dname,tmp,tmp]=fileparts(pwd);
tmp=pwd;
dname=tmp(find(tmp==filesep,1,'last')+1:end);

fname_xml=[dname '.xml']; 
if ~exist(fname_xml,'file')
  disp(sprintf('Directory with images must also contain the xml file (%s)!!',fname_xml))
  return
end

acq=query_xml(fname_xml,'acquisition');
for n=0:acq.RefSpacing:acq.nRadio
  fname_refC=sprintf('refHST%04d.edf',n);
  if exist(fname_refC,'file')
    fprintf('%s already exists - skipping\n',fname_refC);
    continue
  end
  fprintf('Reading references at %d\n',n);
  ref=zeros(acq.nRefs,acq.size2,acq.size1);

  for m=0:acq.nRefs-1
    fprintf('Reading image %d of %d\r',m+1,acq.nRefs)
    fname_ref=sprintf('ref%04d_%04d.edf',m,n);
    if ~exist(fname_ref,'file')
      fprintf('Waiting for %s...',fname_ref)
      while ~exist(fname_ref,'file')
        pause(2)
      end
      fprintf('Found it!\n')
    end
    ref(m+1,:,:)=edf_read(fname_ref); 
  end
  fprintf('Now performing median...\n')
  refC=squeeze(median(ref));
  edf_write(refC,fname_refC,'uint16');

end
