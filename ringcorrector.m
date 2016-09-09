function ringcorrection(varargin)

% permit the user to pass in all the parameters necessary.  If they don't,
% present a GUI for them to try a few things, then tell them how to run it
% in a batch mode

% take the ringexample.edf file as well

if nargin~=0
  % need to verify parameters
  parameters=[];
  sfStartJob(parameters)
else
  % display GUI and let user interactively try some stuff
  close all
  clear all
  app=[];
  % setup figure
  sfInitialise
  sfSetupFigure
  sfInitialiseImages
  % now we are in main event loop, waiting for user to click on buttons
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfInitialise
    disp('sfInitialise')
    edf_setup_imformats;  % adds edf to file formats that imread can parse
    app.data.decimate=8;
    app.gui.liveupdate=false; % don't do update until asked
    app.data.savefile=false;
    app.data.savesuffix='_corr';
    app.data.slicendx=1;  % start with first (or only) slice
    app.data.slicemax=2;
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfSetupFigure
    disp('sfSetupFigure')
    % create the figure and modify toolbars etc
    app.gui.figuresize=[900 400];
    app.handles.figures.gui = figure('units','pixels','position',[10 10 app.gui.figuresize]);
    set(app.handles.figures.gui,'menubar','none','numbertitle','off','name','Ring Corrector','visible','off');

    % then create the three uipanels

    % Column 2 is fixed at 100 pixels.
    % All other columns are super stretchy around 100 pixels.
    col_ks = [ 0  1   0   ];
    col_ds = [ 100 200 100] ;

    % only a single row, can flex with figure size
    row_ks = [ 0 ];
    row_ds = [ 100 ];

    % Initialize the layout
    layout = xtargets_springgridlayout(app.handles.figures.gui, row_ks, row_ds, col_ks, col_ds);

    % Get a constraint structure.
    constraint = layout.create_constraint();

    % LH image panel
    constraint.col = 1;
    constraint.row = 1;
    app.handles.panels.im_orig = uipanel('title', 'Original image', 'units', 'pixels');
    layout.add(app.handles.panels.im_orig, constraint);

    % Parameters panel
    constraint.col = 2;
    constraint.row = 1;
    app.handles.panels.parameters = uipanel('title','Parameters', 'units', 'pixels');
    layout.add(app.handles.panels.parameters, constraint);

    % RH image panel
    constraint.col = 3;
    constraint.row = 1;
    app.handles.panels.im_corr = uipanel('title', 'Corrected image', 'units', 'pixels');
    layout.add(app.handles.panels.im_corr, constraint);

    sfSetupParameterPanel;

  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfToggleLiveUpdate(hObject,evendata)
    app.gui.liveupdate=not(app.gui.liveupdate);
    if app.gui.liveupdate==true
      set(app.handles.uicontrols.go,'enable','off')
      sfGo
    else
      set(app.handles.uicontrols.go,'enable','on');
    end
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfSetupParameterPanel
    disp('sfSetupParameterPanel')
    % now setup the contents of the parameters panel

    % then create the three uipanels

    % Column 2 is fixed at 100 pixels.
    % All other columns are super stretchy around 100 pixels.
    col_ks = [ 0 0 ];
    col_ds = [ 50 50 ] ;

    nrows=8;
    row_ks = zeros(1,nrows);
    row_ds = repmat(100,1,nrows);

    % Initialize the layout
    layout2 = xtargets_springgridlayout(app.handles.panels.parameters, row_ks, row_ds, col_ks, col_ds);

    % Get a constraint structure.
    constraint = layout2.create_constraint();
    constraint.padding=[5 5 5 5];

    constraint.fillx=false;
    constraint.alignx='right';
    constraint.filly=false;
    constraint.aligny='centre';

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % filename
    constraint.col = 1;
    constraint.row = 1;
    app.handles.uicontrols.filebutton = uicontrol('style','pushbutton','string','File...','callback',@sfSetFilename);
    layout2.add(app.handles.uicontrols.filebutton, constraint);

    constraint.col=constraint.col+1;
    constraint.alignx='left';
    constraint.fillx=true;
    app.handles.uicontrols.filename=uicontrol('style','edit','string','filename','callback',@sfSetFilename);
    layout2.add(app.handles.uicontrols.filename, constraint);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % slice selector
    constraint.col = 1;
    constraint.row = constraint.row+1;
    app.handles.uicontrols.sliceselectorlabel = uicontrol('style','text','string',sprintf('Slice %d',app.data.slicendx));
    layout2.add(app.handles.uicontrols.sliceselectorlabel, constraint);

    constraint.col=constraint.col+1;
    constraint.alignx='left';
    constraint.fillx=true;
    app.handles.uicontrols.sliceselector=uicontrol('style','slider','string','Slice',...
      'Min',1,'Max',app.data.slicemax,'value',1,'callback',@sfSetSliceIndex);
    layout2.add(app.handles.uicontrols.sliceselector, constraint);


    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % save suffix
    constraint.row = constraint.row+1;  % next row
    constraint.col = 1;
    constraint.alignx='right';

    app.handles.uicontrols.savefilesuffixlabel=uicontrol('style','text','string','Save suffix');
    layout2.add(app.handles.uicontrols.savefilesuffixlabel, constraint);

    constraint.col = constraint.col+1;
    constraint.fillx=false;
    constraint.alignx='left';
    
    app.handles.uicontrols.savefilesuffixstring = uicontrol('style','edit','string',app.data.savesuffix,'callback',@sfSetSaveSuffix);
    layout2.add(app.handles.uicontrols.savefilesuffixstring, constraint);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % toggle saving
    constraint.row = constraint.row+1;
    constraint.col = 1;
    constraint.alignx='right';

    app.handles.uicontrols.savefiletogglelabel = uicontrol('style','text','string','Save file');
    layout2.add(app.handles.uicontrols.savefiletogglelabel, constraint);

    constraint.col = constraint.col+1;
    constraint.fillx=false;
    constraint.alignx='left';
    app.handles.uicontrols.savefiletoggle = uicontrol('style','checkbox','value',app.data.savefile,'callback',@sfToggleSavefile);
    layout2.add(app.handles.uicontrols.savefiletoggle, constraint);

    
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % threshold
    constraint.row = constraint.row+1
    constraint.col = 1;
    constraint.alignx='right';

    app.handles.uicontrols.autothreshold = uicontrol('style','pushbutton','string','Auto-threshold','callback',@sfAutoThreshold);
    layout2.add(app.handles.uicontrols.autothreshold, constraint);

    constraint.col = constraint.col+1;
    constraint.alignx='left';
    app.handles.uicontrols.thresholdvalue = uicontrol('style','edit','callback',@sfAutoThreshold);
    layout2.add(app.handles.uicontrols.thresholdvalue, constraint);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % decimation
    constraint.row = constraint.row+1;
    constraint.col = 1;
    constraint.alignx='right';

    app.handles.uicontrols.downsamplelabel = uicontrol('style','text','string','Decimation');
    layout2.add(app.handles.uicontrols.downsamplelabel, constraint);

    constraint.col = constraint.col+1;
    constraint.fillx=false;
    constraint.alignx='left';
    app.handles.uicontrols.downsamplepopup = uicontrol('style','popup','string','1|2|4|8|16','callback',@sfSetDecimation);
    switch(app.data.decimate)
      case 1
        ndx=1;
      case 2
        ndx=2;
      case 4
        ndx=3;
      case 8
        ndx=4;
      case 16
        ndx=5;
    end
    set(app.handles.uicontrols.downsamplepopup,'value',ndx)
    layout2.add(app.handles.uicontrols.downsamplepopup, constraint);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % GO!
    constraint.row = constraint.row+1;
    constraint.col = 1;
    constraint.alignx='right';

    app.handles.uicontrols.liveupdatelabel = uicontrol('style','text','string','Live update');
    layout2.add(app.handles.uicontrols.liveupdatelabel, constraint);

    constraint.col = constraint.col+1;
    constraint.fillx=false;
    constraint.alignx='left';
    app.handles.uicontrols.liveupdatetoggle = uicontrol('style','checkbox','value',app.gui.liveupdate,'callback',@sfToggleLiveUpdate);
    layout2.add(app.handles.uicontrols.liveupdatetoggle, constraint);

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    % ROW 1
    constraint.row=constraint.row+1;
    constraint.col=1;
    constraint.colspan=2;
    constraint.rowspan=1;
    constraint.alignx='centre';
    constrint.fillx=true;
    app.handles.uicontrols.go=uicontrol('style','pushbutton','string','Go!','callback',@sfGo);
    layout2.add(app.handles.uicontrols.go,constraint);

    set(app.handles.figures.gui,'visible','on');

  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfToggleSavefile(hObject,eventdata)
    app.data.savefile=not(app.data.savefile);
  end
      
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfSetFilename(hObject,eventdata)
    disp('sfSetFilename')
    switch hObject
      case app.handles.uicontrols.filebutton
        % open a file chooser
        [tmp_fname,tmp_path]=uigetfile('*.*','Pick a file');
        if isequal(tmp_fname,0) || isequal(tmp_path,0)
          disp('User pressed cancel')
          return
        else
          app.data.fname_orig=fullfile(tmp_path,tmp_fname);
          % what type of file is it?
          [tmp,tmp,extension,tmp]=fileparts(app.data.fname_orig);
          app.data.ftype=extension(2:end);  % remove the .
          set(app.handles.uicontrols.filename,'string',tmp_fname)
          sfLoadImage;
          if app.gui.liveupdate==true
            sfGo
          end
        end
      case app.handles.uicontrols.filename
        disp('Sorry - not implemented yet')
    end
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfSetSliceIndex(hObject,eventdata)
    disp('sfSetSliceIndex')
    switch hObject
      case app.handles.uicontrols.sliceselector
        % get the slider value, update the label, and update the display
        ndx=round(get(app.handles.uicontrols.sliceselector,'value'));
        set(app.handles.uicontrols.sliceselectorlabel,'string',sprintf('Slice %d',ndx));
        app.data.slicendx=ndx;
        sfLoadImage
        if app.gui.liveupdate==true
          sfGo
        end
      otherwise
        disp('Sorry - not implemented yet')
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfGo(hObject,eventdata)
    disp('sfGo')
    sfCorrectRings
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfInitialiseImages
    disp('sfInitialiseImages')
    macrohome=utilGetOnlyPath(mfilename('fullpath'));
    app.data.fname_orig=[macrohome '/ringexample.edf'];
    app.data.ftype='edf';
    set(app.handles.uicontrols.filename,'string',app.data.fname_orig)
    sfLoadImage

    sfCorrectRings
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfUpdateOriginalImage
    disp('sfUpdateOriginalImage')
    app.data.im_deci=app.data.im_orig(1:app.data.decimate:end,1:app.data.decimate:end);
    app.handles.axes.im_orig=axes('parent',app.handles.panels.im_orig);
    app.handles.images.im_orig=imagesc(app.data.im_deci,'parent',app.handles.axes.im_orig);
    colormap(app.data.cmap);
    axis image
    disp('*************')
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfUpdateCorrectedImage
    disp('sfUpdateCorrectedImage')
    % corrected image example
    if ~isfield(app.handles.axes,'im_corr')  % if axes have not been created
      app.handles.axes.im_corr=axes('parent',app.handles.panels.im_corr);

    end
    if ~isfield(app.handles.images,'im_corr') % if image has not been create
      disp('A new image')
      app.handles.images.im_corr=imagesc(app.data.im_corr,'parent',app.handles.axes.im_corr);
    else
      disp('Just an update')
      set(app.handles.images.im_corr,'cdata',app.data.im_corr);
    end
    disp(' ');disp(' ')
    axis image


  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfLoadImage(fname)  % is fname needed as parameter??
    disp('sfLoadImage')
    % progress indicator here? ***
      drawnow % ensure the file chooser closes before we start loading a BIG file

    if ~isempty(imformats(app.data.ftype))  % ftype is recognised by imformats
      % edf,tif,jpg, etc  assume only single slice available
      app.data.im_orig=double(imread(app.data.fname_orig));
      set(app.handles.uicontrols.sliceselectorlabel,'enable','off')
      set(app.handles.uicontrols.sliceselector,'enable','off');
    elseif any(strcmpi(app.data.ftype,{'vol','info','raw','xml'}))
      % HST volume (32 or 8 bit)
      app.data.im_orig=HSTVolReader(app.data.fname_orig,'all','all',1);      
      
      set(app.handles.uicontrols.sliceselectorlabel,'enable','on')
      set(app.handles.uicontrols.sliceselector,'enable','on');
      % and modify slider parameters
      app.data.slicemax=10;  % *** need to get this from file!!
      set(app.handles.uicontrols.sliceselector,'max',app.data.slicemax)
    end

    app.data.im_deci=app.data.im_orig(1:app.data.decimate:end,1:app.data.decimate:end);
    app.data.cmap=gray;
    sfAutoThreshold
    sfUpdateOriginalImage
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfSetDecimation(hObject,eventdata)
    switch get(hObject,'value')
      case 1
        app.data.decimate=1;
      case 2
        app.data.decimate=2;
      case 3
        app.data.decimate=4;
      case 4
        app.data.decimate=8;
      case 5
        app.data.decimate=16;
    end

    sfUpdateOriginalImage
    if app.gui.liveupdate==true
      sfGo
    end
  end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfAutoThreshold(hObject,eventdata)
    disp('sfAutoThreshold')
    % this might have been called programmatically, so check that hObject
    % exists before looking at its value
    if ~exist('hObject','var') || hObject==app.handles.uicontrols.autothreshold % automatic button pressed
      disp('sfAutoThreshold - automatic')
      app.data.threshold=graythresh(app.data.im_deci)*max(app.data.im_deci(:));  % this should probably take min into account
      set(app.handles.uicontrols.thresholdvalue,'string',num2str(app.data.threshold));
    else % must have been text field that was edited
      disp('sfAutoThreshold - manual')
      app.data.threshold=str2num(get(app.handles.uicontrols.thresholdvalue,'string'));
    end

    if app.gui.liveupdate==true
      sfGo
    end

  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfCorrectRings
    disp('sfCorrectRings')
 
    % for some bizarre reason, couldn't get the timer to work in another
    % subfunction.  So it clutters up this one, instead... :(
    
    % store original bg colour
    c=get(app.handles.uicontrols.go,'backgroundcolor');
    t = timer('TimerFcn',@sfBusy, 'Period', 0.5,'executionmode','fixeddelay');
    start(t);

    %    app.data.im_corr=app.data.im_orig>app.data.threshold;
    app.data.im_corr=app.data.im_deci-remove_rings(app.data.im_deci,app.data.threshold);
    if app.data.savefile
      sfSaveFile
    end
    stop(t)
    set(app.handles.uicontrols.go,'backgroundcolor',c)

    sfUpdateCorrectedImage
    
  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfSaveFile
    disp('sfSaveFile')
    [prefix,ndx,extension]=utilStripExtensionandFormat(app.data.fname_orig);
    fname_save=[prefix app.data.savesuffix ndx extension]
    imwrite(app.data.im_corr,fname_save);  % will only work for 2D images!!

  end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  function sfBusy(varargin)
    c=get(app.handles.uicontrols.go,'backgroundcolor');
    set(app.handles.uicontrols.go,'backgroundcolor',[ 1 abs(1-c(2:3))]);
    drawnow
%    datestr(now)
  end
end
