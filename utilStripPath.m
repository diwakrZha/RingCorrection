function fnameout=utilStripPath(fnamein)
% UTILSTRIPPATH.M
% given a file with path, return just the file name. 
% Use this before calling on utilExtractFilenameParts.m  
% or utilStripExtensionandFormat.m
%
% Henry Proudhon, November 2006

fnameout=fnamein(find(fnamein==filesep,1,'last')+1:end);

end