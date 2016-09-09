function pfXMLSetup
% this function is used by (at least) HSTVolReader and HST_info
% need to add to java classpath the jdom.jar file which should be in the
% same directory as this function.
p=mfilename('fullpath');  % where is this function kept?
[pathstr,name,ext,versn]=fileparts(p);
%check the jdom.jar file is in the right place
if ~exist([pathstr filesep 'jdom.jar'],'file')
  disp('I need jdom.jar to be in the same directory as me!')
  return
end
javaaddpath([pathstr filesep 'jdom.jar'])

import org.jdom.*
import org.jdom.input.*
