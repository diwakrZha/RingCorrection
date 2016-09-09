function [fnameroot,fnameformatstring,fnameextension]=utilStripExtensionandFormat(full_fname)
% removes, if necessary, the .edf extension of a file name
  if strcmpi(full_fname(end-3:end),'.edf')
      fname=full_fname(1:end-4);
  else
    fname=full_fname;
  end
  [fnameroot,fnameformatstring]=sfStripFormatting(fname);
  fnameextension='.edf';
end
  

function [root,fmt]=sfStripFormatting(fname)
% removes, if it can, any formatting at the end of the fname (%04d, for example)

ndx=find(fname=='%');
if ndx
  root=fname(1:ndx-1);
  fmt=fname(ndx:end);
else
  root=fname;
  fmt='';
end
end
