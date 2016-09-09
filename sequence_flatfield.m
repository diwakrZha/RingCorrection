function sequence_flatfield(first,last,workingdirectory,varargin)
% SEQUENCE_FLATFIELD.M
% A utility to flatfield correct all images in a directory using the
% reference and dark images found.
%
% Usage: sequence_flatfield
%          -> will try to automatically determine the radiographs in the
%          directory and correct them.
%
% February 2006
% Greg Johnson
%
% Modified November 2006 GJ & HP
% Special naming case for stitched tiles (*UxVy_)
% to put the 'flat_' BEFORE the UxVy so that the stitch naming
% convention is preserved.
%
% Modified December 2006 GJ
% Adding support for 'broken' scans, where a restart with 'fasttomo
% scanname refgroup' was used, and also scans where the monochromator was
% realigned during the scan.


if isdeployed  % if code is compiled
  if exist('first','var')
    first=str2num(first);
    last=str2num(last);
  end
end

params.takelog=false;
params.waitforfiles=true;


params=parse_pv_pairs(params,varargin);

if params.takelog
  disp('Running log version')
else
  disp('Running normal version (use ''takelog'',true as parameters for log output)')
end
% find directory name (which is prefix for all radiographs)
if exist('workingdirectory','var')
  cd(workingdirectory)
end
tmp=pwd;

dname=tmp(find(tmp==filesep,1,'last')+1:end);
% if dname has UxVy_ in it, it is a STITCH scan, so we must have a special
% case
pattern='U(?<U>\d+)V(?<V>\d+)_';
tmp=regexp(dname,pattern,'names');
if ~isempty(tmp) % looks like a stitch to me
  stitched_scan=true;
  outputpath=sprintf('../%sflat_%s',dname(1:end-5),dname(end-4:end));
  doxml=true;
else
  stitched_scan=false;
  outputpath=sprintf('../%sflat_',dname);
end

%check state of reference images (refHST*)
%  if length(dir('refHST*'))==0
%    fprintf('Need some corrected reference images.  Please use\n')
%    fprintf('''sequence_median_refs'' to generate some!\n');
%    return
%  end

if ~exist(outputpath,'dir')
   disp(['Creating output directory: ' outputpath])
   mkdir(outputpath)
end  
 
fname_xml=[dname '.xml'];
if ~exist(fname_xml,'file')
  fprintf('This directory should contain an XML file (%s) as well as the images!!\n',fname_xml)
  return
elseif exist('doxml','var') && doxml==true
  % load the xml, modify the name and write it to the new directory
  xml=stitch_xml_load(fname_xml);
  xml.acquisition
  xml.acquisition.scanName=sprintf('%sflat_%s',dname(1:end-5),dname(end-4:end));
  fname_xml_flat=sprintf('%s/%sflat_%s.xml',outputpath,dname(1:end-5),dname(end-4:end));
  xml_save(fname_xml_flat,xml,'off');
  disp('created new xml file');
end

acq=query_xml(fname_xml,'acquisition');

% read dark image
if exist('dark.edf','file')
  % dark image has already been divided and can be used as-is
  im_dark=edf_read('dark.edf');
elseif exist('darkend0000.edf','file')
  % dark image is a summed one - we can use and write the dark.edf while we
  % are at it...
  fprintf('Generating dark.edf\n')
  im_dark=edf_read('darkend0000.edf')./acq.nDarks;
  edf_write(im_dark,'dark.edf','uint16');
else
  disp('No dark files!')
  return
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% initialise with first reference available
tmpd=dir('refHST*.edf');  % assume order is numerical

% *** TO DO - fix this code so that it works with refNext even if not
% starting on a reference boundary...

if ~isempty(tmpd)
  if exist('first','var')  % user specified a first image to start with
    % find the reference JUST before the first image requested to process
    tname={tmpd.name};
    tmpinfo=utilExtractFilenameParts(tname);
    indices=[];
    for n=1:length(tmpinfo)
      indices=[indices str2num(tmpinfo{n}.index)];
    end
    
    firstref=indices(find(indices<first,1,'last'));

  else
    tmpinfo=utilExtractFilenameParts(tmpd(1).name);
    firstref=tmpinfo.index;
    if firstref==0  % in the case of the first image,
      first=0;
    else
      first=firstref-1;
    end
  end
  
else  % cannot find any references at the moment
  firstref=0;
  first=0;
end

fprintf('Reading previous reference image (refHST%04d.edf)\n',firstref)
im_refNext=sfWaitToRead(sprintf('refHST%04d.edf',firstref))-im_dark;
im_refPrevious=im_refNext;
clear meanN
im_sum=zeros(size(im_refNext));
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if ~exist(outputpath,'dir')
  disp(['Creating output directory: ' outputpath])
  mkdir(outputpath)
end
if ~exist('last','var')  % user did not specify a last image to process
  last=acq.nRadio;
end
  
for n=first:last % loop over all files in range
  if ~stitched_scan  % normal files
    fname_imC=sprintf('%s/%sflat_%04d.edf',outputpath,dname,n);
  else  % this is a stitch, do it differently
    fname_imC=sprintf('%s/%sflat_%s%04d.edf',outputpath,dname(1:end-5),dname(end-4:end),n);
  end
  if exist(fname_imC,'file')
    fprintf('Flatfield file already exists (%s) - skipping\n',fname_imC)
    continue
  end

  if n~=acq.nRadio % stupid check to avoid problems with the last file (1500 usually)
    if mod(n,acq.RefSpacing)==0
      % time to read some new reference images
      % if this is a normal scan, the references are ONLY at the
      % acq.RefSpacing intervals.  But if there is a reference called n+1,
      % it means that it should be used instead
      normalRefNumber=(floor(n/acq.RefSpacing)+1)*acq.RefSpacing;
      fname_nextref=sprintf('refHST%04d.edf',normalRefNumber);
      fname_prevrefcheck=sprintf('refHST%04d.edf',normalRefNumber+1-acq.RefSpacing);

      if ~exist(fname_prevrefcheck,'file')
        % looks like this is a normal reference transition - do the usual
        % thing
        im_refPrevious=im_refNext;
      else
        % a reference with number n+1 exists - so we need to change the
        % im_refPrevious to a new file
        fprintf('Reading a special previous reference: %s\n',fname_prevrefcheck);
        im_refPrevious=sfWaitToRead(fname_prevrefcheck)-im_dark;
      end
      fprintf('\nReading next reference image (%s)\n',fname_nextref)
      im_refNext=sfWaitToRead(fname_nextref)-im_dark;

    end
  end

  % what ratio between the two references?
  fraction=mod(n,acq.RefSpacing)/acq.RefSpacing;
  if fraction>1 % for images beyond the last ref, use 100% of the last ref
    fraction=1;
  end

  fprintf('Correcting image %d... ',n);
  im=sfWaitToRead(sprintf('%s%04d.edf',dname,n))-im_dark;
  im_refN=(im_refNext.*(fraction))+(im_refPrevious.*(1-fraction));

  im_corrected=im./(im_refN+eps);  % the epsilon is to avoid division by zero warnings for special zero refs

  im_sum=im_sum+im_corrected;
  meanN(n+1)=mean(im(:));
  %  imagesc(im_corrected,[0 1]),axis image,drawnow
  if params.takelog==true
    fprintf('Writing log of result (%s)\r',fname_imC);
    edf_write(log(im_corrected),fname_imC,'float32');
  else
    fprintf('Writing result (%s)\r',fname_imC);
    edf_write(im_corrected,fname_imC,'float32');
  end
  %    plot(meanN,'.'),title('Mean of corrected image'),drawnow
end
im_mean=im_sum./acq.nRadio;
edf_write(im_mean,sprintf('mean%sflat.edf',dname),'float32');
fprintf('\n')

end

function im=sfWaitToRead(fname)
if ~exist(fname,'file')
  fprintf('Waiting for %s...(use ''sequence_median_refs'')',fname);
  while ~exist(fname,'file')
    pause(2)
  end
  fprintf('Found it!\n');
end
im=edf_read(fname);
end
