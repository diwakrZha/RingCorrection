function filetype=pfHSTDecideFiletype(fname)
if isfield(fname,'raw')
  % going with the 8 bit file
  filetype='uint8';
%  disp('Reading 8 bit file');
  if ~exist(fname.raw,'file') & ~exist(fname.info,'file')
    fprintf('Either %s or %s does not exist!',fname.raw,fname.info)
    return
  end
elseif isfield(fname,'xml')
  % going with the 32 bit file - should really check this!
  filetype='float32';
 % disp('Reading 32 bit file');
  if ~exist(fname.xml,'file') && ~exist(fname.vol,'file')
    fprintf('Either %s or %s does not exist!',fname.vol,fname.xml)
    return
  end
else
  disp('File does not appear to exist!')
  filetype=[];
  return
end

end
