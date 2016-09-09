function meshview(filename,scannumber)
% MESHVIEW.M A simple viewer for SPEC mesh scans
% Usage:
% meshview(filename,scannumber)
% Example:
% meshview('mesh_example.spec',101)  (a sample data file - try it!)
% This will display a 3D surface and allow the user to select which of the
% counters they would like to plot.  The reading of the spec file is done
% with MESHREAD.M
%
% Greg Johnson
% June 2006

% read the data, and the labels for the counters
[xgrid,ygrid,data,labels]=meshread(filename,scannumber);

% make a simple GUI
figure(1)
clf

h_ax=axes('position',[0.1,0.1,0.6,0.8]); % draw some axes
% now make a listbox with the names of the counters in it
h_lb=uicontrol('style','listbox',...
  'units','normalized','position',[0.75 0.1 .22 0.8],...
  'string',labels,'callback',@sfUpdatePlot);

% update the plot for the first time
sfUpdatePlot


  function sfUpdatePlot(varargin)
    % everytime the listbox is clicked, this sub-function is called
    n=get(h_lb,'value'); % findout which label was clicked
    imagesc(xgrid(1,:),ygrid(:,1),data{n})  % plot that data
    axis xy
    title(labels{n},'interpreter','none') % title the plot without using LaTEX labels
    xlabel(labels{1},'interpreter','none')
    ylabel(labels{2},'interpreter','none')
  end
end

