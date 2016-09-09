function clims=pfSetColourLimits(vol,clims,varargin)
% pfSetColourLimits Histogram based colour limits calculator
% Usage:
% clims=pfSetColourLimits(im,0);
%       clims will be be set to max and min of the image.
%
% clims=pfSetColourLimits(im,2);
%       clims will be set to the 2nd and 98th percentile
%
% clims=pfSetColourLimits(im,3,'verbose',true)
%       clims will be set to the 3rd and 97th percentile and a message will
%       be displayed to tell you what happened
%
% clims=pfSetColourLimits(im,[2 80])
%       clims will be set to the 2nd and 80th (non-symmetric!) percentiles
%
% The image could also be a 3D image (volume).

% Greg Johnson, November 2006

app.verbose=false;
app=parse_pv_pairs(app,varargin);
switch length(clims)
  case 0
    if app.verbose
      disp('Using 2% colour limits');
    end
    clims=autolim(vol,0.02);
  case 1
    if clims==0
      if app.verbose
        fprintf('Using full range of data\n');
      end
      clims=[min(vol(:)) max(vol(:))];
    else
      if app.verbose
        fprintf('Calculating %2.1f%% colour limits...\n',clims)
      end
      clims=autolim(vol,clims/100);
    end
  case 2
    if app.verbose
      fprintf('Using %2.1f and %2.1f percentile colour limits...\n',clims);
    end
    clims=autolim(vol,clims/100);
end
