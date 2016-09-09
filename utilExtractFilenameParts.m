function parts=utilExtractFilenameParts(fname)
% UTILEXTRACTFILENAMEPARTS.M
% Given a filename, extracts the prefix, index, and extension
% Greg Johnson, May 2006
%
% Bugs: only deals with files having four or five digits in the number
% see fileparts for a more general purpose tool

% used to have . after \w*).

pattern='(?<prefix>\w*)(?<index>\d{4,5}+).(?<extension>\w*)';
parts=regexp(fname,pattern,'names');
try
  parts.index=str2num(parts.index);
catch
end
