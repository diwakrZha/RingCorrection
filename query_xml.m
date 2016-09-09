function results=query_xml(fname,branch)

xml=xml_load(fname);
xml=sfCleanupXML(xml);
if nargin==2
  if isfield(xml,branch)
    results=getfield(xml,branch);
  else
    fprintf('That branch of the XML file does not exist')
    return
  end
else
  results=xml;
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function xml=sfCleanupXML(xml)
% some of the tomodb naming conventions are quite strange - convert them
% to something more understandable here.  Also perform conversion to
% numbers...
if isfield(xml,'acquisition')
  
  if isfield(xml.acquisition,'pixelSize')
    xml.acquisition=sfRenameElement(xml.acquisition,'pixelSize','pixelsize',true);
  end
  
  if isfield(xml.acquisition,'tomo_N')
    xml.acquisition=sfRenameElement(xml.acquisition,'tomo_N','nRadio',true);
  end
  if isfield(xml.acquisition,'ref_On')
    xml.acquisition=sfRenameElement(xml.acquisition,'ref_On','RefSpacing',true);
  end
  if isfield(xml.acquisition,'ref_N')
    xml.acquisition=sfRenameElement(xml.acquisition,'ref_N','nRefs',true);
  end
  if isfield(xml.acquisition,'dark_N')
    xml.acquisition=sfRenameElement(xml.acquisition,'dark_N','nDarks',true);
  end
  if isfield(xml.acquisition.projectionSize,'DIM_1')
    xml.acquisition.size1=str2num(xml.acquisition.projectionSize.DIM_1);
    xml.acquisition.size2=str2num(xml.acquisition.projectionSize.DIM_2);
    xml.acquisition=rmfield(xml.acquisition,'projectionSize');
  end

  if isfield(xml.acquisition,'machineCurrentStart')
    xml.acquisition.machineCurrentStart=...
      str2num(xml.acquisition.machineCurrentStart);
  end
  if isfield(xml.acquisition,'machineCurrentStop')
    xml.acquisition.machineCurrentStop=...
      str2num(xml.acquisition.machineCurrentStop);
  end
  if isfield(xml.acquisition,'distance')
    xml.acquisition.distance=str2num(xml.acquisition.distance);
  end
  if isfield(xml.acquisition,'ccdtime')
    xml.acquisition.ccdtime=str2num(xml.acquisition.ccdtime);
  end
  if isfield(xml.acquisition,'scanDuration')
    xml.acquisition.scanDuration=str2num(xml.acquisition.scanDuration);
  end
 if isfield(xml.acquisition,'y_Step')
    xml.acquisition.y_Step=str2num(xml.acquisition.y_Step);
  end
 if isfield(xml.acquisition,'cameraFibers')
    xml.acquisition.cameraFibers=str2num(xml.acquisition.cameraFibers);
  end
  
  if isfield(xml.acquisition,'cameraBinning')
    pattern='H=(\d), V=(\d)';
    tmp=regexp(xml.acquisition.cameraBinning,pattern,'tokens');
    xml.acquisition.binningH=str2num(char(tmp{1}(1)));
    xml.acquisition.binningV=str2num(char(tmp{1}(2)));
    xml.acquisition=rmfield(xml.acquisition,'cameraBinning');
  end
  
  if isfield(xml.acquisition,'listMotors') 
    if length(xml.acquisition.listMotors)>0
      xml.acquisition.motors=[];
      for n=1:length(xml.acquisition.listMotors)
        xml.acquisition.motors=setfield(xml.acquisition.motors,...
          xml.acquisition.listMotors(n).motor.motorName,...
          str2num(xml.acquisition.listMotors(n).motor.motorPosition));
      end
    end
    xml.acquisition=rmfield(xml.acquisition,'listMotors');
  end
end
if isfield(xml,'stitching')
  fprintf('Help - ask greg what to do!')
end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function results=sfGetStitching(xml_root)
% THIS FUNCTION IS OBSOLETE!!
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



function xmlbranch=sfRenameElement(xmlbranch,oldelement,newelement,isnumeric)
if isnumeric
  xmlbranch=setfield(xmlbranch,newelement,str2num(getfield(xmlbranch,oldelement)));
else
  xmlbranch=setfield(xmlbranch,newelement,getfield(xmlbranch,oldelement));
end
xmlbranch=rmfield(xmlbranch,oldelement);

end




