function [fname,fpath]=pfGetHSTFilenames(full_fname)

% check for file existence
if ~any(strcmp(full_fname(end-2:end),{'xml','raw','vol'}))
%  disp('No valid extension (vol,raw,xml) supplied')
  full_fname(end+1)='.';  % append a pseudo extension
end
[fpath,filename,fext]=fileparts(full_fname);

% fileparts doesn't work if the filename is supplied

if ~isempty(fpath)
%    disp('Path supplied')
  fpath=[fpath filesep];
else
%  disp('NO path supplied');
  fpath=[pwd filesep];
end


% *** replace this with (sub?) function to strip extensions
switch fext
  case '.xml'  % user has specified the .xml file
    % is it a vol.xml or a raw.xml?
    if strcmp(filename(end-2:end),'vol')
      fname.vol=[fpath filename];
      fname.xml=[fpath filename fext];
      
      [tmp,fname.prefix]=fileparts(fname.vol);

    elseif strcmp(filename(end-2:end),'raw')
      fname.raw=[fpath filename];
      fname.info=[fpath filename '.info'];
      [tmp,fname.prefix]=fileparts(fname.raw);
    end

  case '.vol'  % user has specified the .vol file
    fname.vol=[fpath filename fext];
    fname.xml=[fpath filename fext '.xml'];
    [tmp,fname.prefix]=fileparts(fname.vol);

  case '.raw'
    fname.raw=[fpath filename fext];
    fname.info=[fpath filename fext '.info'];
    [tmp,fname.prefix]=fileparts(fname.raw);

  case '.'  % user supplied without extension
%    disp('No extension supplied');
    if exist([fpath filename '.vol'],'file')
      % 32 bit
      fname.vol=[fpath filename '.vol'];
      fname.xml=[fpath filename '.vol.xml'];
    elseif exist([fpath filename '.raw'],'file')
      fname.raw=[fpath filename '.raw'];
      fname.info=[fpath filename '.info'];
    else
      error('No file found')
    end
    [tmp,fname.prefix]=fileparts(full_fname);
  otherwise
    error('Sorry- not understood')
    
end
