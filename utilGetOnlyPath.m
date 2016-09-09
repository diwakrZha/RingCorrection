function fnameout=utilGetOnlyPath(fnamein)
% UTILGETONLYPATH.M
% given a file with path, return just the path. 
% 
% Greg Johnson, November 2006

fnameout=fnamein(1:find(fnamein==filesep,1,'last')-1);

end
