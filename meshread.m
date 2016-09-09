% modified by GJ to permit reading of a single scan (by number)
function [xgrid,ygrid,data,labels] = meshread(filename,scannumber)
% [xgrid,ygrid,data,labels] = meshread(filename,scannumber)
% HELP NEEDS FINISHING!
fid = fopen(filename);
% find the scan and check it is a 'mesh' type    
while ~feof(fid)
  str=fgetl(fid);
  if length(str)>2 && strcmp(str(1:2),'#S')
    [scanfound,remainder]=strtok(str(4:end),' ');
    if str2num(scanfound)==scannumber
      [meshfound,remainder]=strtok(remainder,' ');
      if strcmp(meshfound,'mesh')
        fprintf('Found mesh %d\n',scannumber)
        [tmp,remainder]=strtok(remainder);% junk
        [tmp,remainder]=strtok(remainder);xstart=str2num(tmp);
        [tmp,remainder]=strtok(remainder);xend=str2num(tmp);
        [tmp,remainder]=strtok(remainder);xnumber=str2num(tmp)+1;
        [tmp,remainder]=strtok(remainder);% junk
        [tmp,remainder]=strtok(remainder);ystart=str2num(tmp);
        [tmp,remainder]=strtok(remainder);yend=str2num(tmp);
        [tmp,remainder]=strtok(remainder);ynumber=str2num(tmp)+1;
        break
      end
    end
  end
end
if feof(fid)
  disp('Nothing found - sorry')
  return
end

[xgrid,ygrid]=meshgrid(...
  linspace(xstart,xend,xnumber),...
  linspace(ystart,yend,ynumber));


% find the data itself (always starts after the #L line)

while ~feof(fid)
  str=fgetl(fid);
  if length(str)>2 && strcmp(str(1:2),'#N')
    counters_num=str2num(str(3:end));
    str=fgetl(fid); % reads #L line and throws away
    % parse the labels
    n=1;
    [junk,str]=strtok(str);  % strip #L
    while ~isempty(str)
      
     [labels{n},str]=strtok(str);
     n=n+1;
    end
    break
  end
end
if feof(fid)
  disp('Nothing found - sorry')
  return
end
% now read the data...

n=1;
% initialise to zeros
for n=1:counters_num
  data{n}=zeros(ynumber,xnumber);
end
try
  for y=1:ynumber
    for x=1:xnumber
      tmpstr=fgetl(fid);
      tmp=str2num(tmpstr);
      
      for n=1:counters_num
        data{n}(y,x)=tmp(n);
      end
    end
  end
catch
  fprintf('Mesh ended at %d,%d\n',x,y);
  fprintf('Last partial line may not have been read!\n');
end

end


