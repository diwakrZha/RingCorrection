function sequence_rename(oldprefix,newprefix)
% SEQUENCE_RENAME.M
% Renames a group of EDF files
% Usage:
% sequence_rename(oldprefix,newprefix)
% Example:
% sequence_rename('myverylongfilename','shorter_')
% All files like myverylongfilename0124.edf would be renamed
% shorter_0124.edf
%
% Greg Johnson, May 2006

d=dir([oldprefix '*.edf']);

for n=1:length(d)
  old=utilExtractFilenameParts(d(n).name);
  new=sprintf('%s%s.%s',newprefix,old.index,old.extension);
  cmd=sprintf('mv %s %s',d(n).name,new);
  fprintf('%d: %s\r',n,cmd)
  system(cmd);
end
  
fprintf('\n')
