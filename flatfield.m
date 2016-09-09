function im_corrected=flatfield(fname,varargin)
% UPDATE HELP!
% SEQUENCE_FLATFIELD.M
% A utility to flatfield correct all images in a directory using the
% reference and dark images found.
%
% Usage: sequence_flatfield
%          -> will try to automatically determine the radiographs in the
%          directory and correct them.
%        sequence_flatfield('parallel')
%          -> will initiate the jobs to be taken by any matlab process on
%          NICE running the script 'serve' - as the same user.
%
% February 2006
% Greg Johnson

params.debug=false;
params=parse_pv_pairs(params,varargin);

tmp=utilExtractFilenameParts(fname);
scanname=tmp.prefix;
ndx=str2double(tmp.index);

fname_xml=[scanname '.xml'];
if ~exist(fname_xml,'file')
  fprintf('This directory should contain an XML file (%s) as well as the images!!\n',fname_xml)
  return
end

acq=query_xml(fname_xml,'acquisition');

% read dark image
if exist('dark.edf','file')
    % dark image has already been divided and can be used as-is
    im_dark=edf_read('dark.edf');
elseif exist('darkend0000.edf','file')
    % dark image is a summed one - we can use and write 
    % the dark.edf while we are at it...
    if params.debug
        fprintf('Generating dark.edf\n')
    end
    im_dark=edf_read('darkend0000.edf')./acq.nDarks;
    edf_write(im_dark,'dark.edf','uint16');
else
    if params.debug
        disp('no dark files located')
        disp('creating temp dark file')
    end
    tmp=edf_info(fname);
    im_dark=zeros(tmp.dim_2,tmp.dim_1);
end

% what ratio between the two references?
fraction=mod(ndx,acq.RefSpacing)/acq.RefSpacing;

% read previous reference
fname_prevref=sprintf('refHST%04d.edf',...
  (floor(ndx/acq.RefSpacing))*acq.RefSpacing);
if params.debug
    fprintf('Reading previous reference image (%s)\n',fname_prevref);
end
im_refPrevious=edf_read(fname_prevref)-im_dark;

if fraction>0    
    % read next reference
    fname_nextref=sprintf('refHST%04d.edf',...
      (floor(ndx/acq.RefSpacing)+1)*acq.RefSpacing);
    if params.debug
        fprintf('Reading next reference image (%s)\n',fname_nextref);
    end
    im_refNext=edf_read(fname_nextref)-im_dark;
    im_ref=(im_refNext.*(fraction))+(im_refPrevious.*(1-fraction));
else
    % HP: no need for next ref if fraction==0 (ie edf number=ref number)
    im_ref=im_refPrevious;
end

if params.debug
    fprintf('Correcting image %d... \n',ndx);
end
im=edf_read(fname)-im_dark;
im_corrected=im./im_ref;
if params.debug
    disp('flatfield: done');
end

end
