function modify_stitching(offsetu,offsetv)


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
xml_doc=xml_builder.build([pwd filesep 'stitching.xml']); % needs full path
xml_root=xml_doc.getRootElement;


xml_stitching=xml_root.getChild('stitching');


xml_tiles=xml_stitching.getChild('tiles');
xml_alltiles=xml_tiles.getChildren;

itr=xml_alltiles.iterator;
n=1;
while(itr.hasNext)
  tmp=itr.next;
  % remove any existing offsets
  tmp.getChild('position').removeChild('offsetu');
  tmp.getChild('position').removeChild('offsetv');
  
  new_offsetu=Element('offsetu');
  new_offsetu.setText(num2str(offsetu(n)));
  new_offsetv=Element('offsetv');
  new_offsetv.setText(num2str(offsetv(n)));
  tmp.getChild('position').addContent(new_offsetu);
  tmp.getChild('position').addContent(new_offsetv);
  
  n=n+1;
end

% now write the xml file
fos=java.io.FileOutputStream('stitching.xml'); % create output file
oos=java.io.ObjectOutputStream(fos);
outputter=XMLOutputter(Format.getPrettyFormat); % ensure the output is pretty
outputter.output(xml_root,oos); % write it out
oos.close;
fos.close;
