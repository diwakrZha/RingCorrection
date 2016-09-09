function sequence_remove_rings(filename,threshold)
% no error checking yet!!
try
  HSTVolReader(filename,'functionhandle',@remove_rings,'functionarguments',threshold)
catch
  rethrow(lasterror)
end