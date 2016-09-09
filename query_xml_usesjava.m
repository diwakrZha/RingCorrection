function [results,varargout]=query_xml(fname,branch)

xml_root=sfOpenFile(fname);
if isempty(xml_root)
  disp('Quitting...')
  results=[];
  return
end

switch branch
  case 'acquisition'
    results=sfGetAcquisition(xml_root);
  case 'reconstruction'
    results=sfGetReconstruction(xml_root);
  case 'stitching'
    results=sfGetStitching(xml_root);
  otherwise
    disp('Don''t know how to handle this!')
    help(mfilename)
    return
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xml_root=sfOpenFile(fname)
% setup use of jdom.jar (which parses the xml files for us

% need to add to java classpath the jdom.jar file which should be in the
% same directory as this function.
p=mfilename('fullpath');  % where is this function kept?
[pathstr,tmp,tmp,tmp]=fileparts(p);
%check the jdom.jar file is in the right place
if ~exist([pathstr filesep 'jdom.jar'],'file')
  disp(sprintf('I need jdom.jar to be in the same directory as me! (%s)',pathstr))
  return
end
javaaddpath([pathstr filesep 'jdom.jar'])

import org.jdom.*
import org.jdom.input.*
import org.jdom.output.*

xml_builder=org.jdom.input.SAXBuilder;
try
  xml_doc=xml_builder.build([pwd filesep fname]); % needs full path
catch
  disp(['Could not find ' pwd filesep fname])
  xml_root=[];
  return
end
xml_root=xml_doc.getRootElement;

end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function results=sfGetAcquisition(xml_root)
xml_acquisition = xml_root.getChild('acquisition');

% pixel size?
results.pixelsize=str2num(xml_acquisition.getChild('pixelSize').getTextTrim);
% how many radiographs altogether?
results.nRadio = str2num(xml_acquisition.getChild('tomo_N').getTextTrim);

% the Refs occur every RefSpacing radiographs
results.RefSpacing=str2num(xml_acquisition.getChild('ref_On').getTextTrim);

% nRefs need to be medianed
results.nRefs=str2num(xml_acquisition.getChild('ref_N').getTextTrim);

% darkend0000.edf has nDarks summed in it
results.nDarks=str2num(xml_acquisition.getChild('dark_N').getTextTrim);

%image size
xml_size=xml_acquisition.getChild('projectionSize');
results.size1=str2num(xml_size.getChild('DIM_1').getTextTrim);
results.size2=str2num(xml_size.getChild('DIM_2').getTextTrim);

% pmy position (useful for stitching)
xml_listmotors=xml_acquisition.getChild('listMotors');
% iterate through all motors until we find pmy and sz
itr=xml_listmotors.getChildren.iterator;
while(itr.hasNext && ~(isfield(results,'pmy_position') && isfield(results,'sz_position')))
  tmp=itr.next;
  xml_motorname=char(tmp.getChild('motorName').getTextTrim);
  if strcmp(xml_motorname,'pmy')
    results.pmy_position=str2num(tmp.getChild('motorPosition').getTextTrim);
  end
  if strcmp(xml_motorname,'sz')
    results.sz_position=str2num(tmp.getChild('motorPosition').getTextTrim);
  end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function results=sfGetReconstruction(xml_root)
disp('Not doing anything useful yet - sorry!')
return
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function results=sfGetStitching(xml_root)
xml_stitching=xml_root.getChild('stitching');
try
  results.outputname=char(xml_stitching.getChild('name').getTextTrim);
catch
  disp('No stitching element found in file')
  results=[];
  return
end
xml_tiles=xml_stitching.getChild('tiles');
xml_alltiles=xml_tiles.getChildren;

itr=xml_alltiles.iterator;
n=1;
while(itr.hasNext)
  tmp=itr.next;
  try
    tile(n).directory=char(tmp.getChild('directory').getTextTrim);
    tile(n).flatname=char(tmp.getChild('flatname').getTextTrim);
    tile(n).posU=str2num(tmp.getChild('position').getChild('u').getTextTrim);
    tile(n).posV=str2num(tmp.getChild('position').getChild('v').getTextTrim);
    q=tmp.getChild('position').getChild('offsetu');
    if ~isempty(q)
      tile(n).offsetU=str2num(q.getTextTrim);
    end
    
    q=tmp.getChild('position').getChild('offsetv');
    if ~isempty(q)
      tile(n).offsetV=str2num(q.getTextTrim);
    end
    % try to insert tile in appropriate element of a cell array
   tmp_matrix{tile(n).posV,tile(n).posU}=tile(n);
  catch
    disp('XML file does not contain all required elements')
    lasterr
  end
  n=n+1;
end
results.tiles=tmp_matrix;

end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
