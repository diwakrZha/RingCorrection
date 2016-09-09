function [im,varargout]=roi_read(filename,GT_bb)
% EDF_READ.M Reads images and 3D volumes from .edf files
% Usage:
% data=edf_read(filename);
% 
%  Designed to be used from imread (see edf_setup_imread.m for how this is done automatically).
% Greg Johnson & Wolfgang Ludwig
% June 2006
if nargin==0
  [fname,pname]=uigetfile('*.edf','Select an EDF file');
  filename=fullfile(pname,fname);
end
if ~exist(filename,'file')
  disp('File does not exist!')
  im=[];
  return
end
info=edf_info(filename);
fid=fopen(filename,'r',info.byteorder);
if fid==-1
  sprintf('Could not open %s\n',filename);
  return
end
fseek(fid,info.headerlength,'bof');
if ~isfield(info,'dim_3') % this should be simplified...
  info.dim_3=1;
end

switch info.datatype
    case {'uint8','int8'}
			nbytes=1;
		case {'uint16','int16'}
			nbytes=2;
    case {'uint32','int32','float32'}
			nbytes=4;
		case 'float64'
			nbytes=8;
end
	



pr_str=sprintf('%d*%s',GT_bb(3),info.datatype);
skip=nbytes*(info.dim_1-GT_bb(3));
fseek(fid,nbytes*(info.dim_1*(GT_bb(2)-1)+GT_bb(1)-1),0);
im=fread(fid,[GT_bb(3),GT_bb(4)],pr_str,skip);
im=im';

if nargout==2
  varargout{1}=[];
end
end
