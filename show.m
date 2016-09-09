function show(varargin)
% SHOW.M
% A tool for viewing images.
%
% SHOW will display an image on screen, but is aware of other images in the
% same directory.  To navigate to these images, use the left and right
% arrow keys to move one at a time, and shift-arrows to move 10 at a time.
% To modify the appearance of the image, use the up and down arrows.
% Contrast is adjusted with the un-modified key press, and brightness when
% 'shift' is used in combination.
%
% Usage:
%   show
%     Called in the simplest form, SHOW will try to guess what to do.  It
%     will look through the current directory for all the images it can
%     find, and try to display them.  Useful in the general case of an ID19
%     tomography scan, where there are many (1500 or more) radiographs in
%     the ESRF .edf format.
%   show(parameter,value)
%     There are lots of ways to modify the behaviour of SHOW.  A few
%     examples are probably the best way of demonstrating:
%
% TO BE CONTINUED...
% THINGS TO ADD
% uicontrol view of EDF parameters
% colourlimit update in windows
%%

app=[];  % declare app so that all nested subfunctions deal with this instance
sfInitialiseApplication(varargin)

sfInitialiseData
sfInitialiseFigure
%sfDisplayParameters;

sfUpdateFigure;


%%
  function sfInitialiseApplication(arguments)
    warning('off','Images:initSize:adjustingMag');
    warning('off','MATLAB:divideByZero')
    
    [tmp,dname,tmp,tmp]=fileparts(pwd);
    app.prefix=dname;
    app.extension='edf';
    app.currentimage=1;
    app.numlength=4;
    app.clims=[];
    app.roi=[];
    app.flatfield='none';
    app.flatfielddark=[];
    app.flatfieldref=[];
    app.handles.fig=figure;
    
    app.debug=false;
    app.im_dolog=false;

    app.firsttime=true;
    app.filechange='';

    if ~isempty(arguments)
      % if the user passed in some parameters, use them
      app=parse_pv_pairs(app,arguments);
    end
    app.fmtstring=sprintf('%%s%%0%dd.%%s',app.numlength);
    
    if strcmpi(app.flatfield,'auto')
      sfAutomaticFlatfield;
    end
    
  end


%%
  function sfInitialiseData
    
    sfFindNumberofImages;
    app.currentimage=app.fileindices(1);
    app.currentfile=sprintf(app.fmtstring,app.prefix,app.currentimage,app.extension);
    app.im=edf_read(app.currentfile);
    % if user did not specify clims, create some
    app.clims=pfSetColourLimits(app.im,app.clims,'verbose',true);
            
  end

%%
  function sfInitialiseFigure
    set(app.handles.fig,'keypressfcn',@sfKeyPress);
    set(app.handles.fig,'numbertitle','off','menubar','none');
    set(app.handles.fig,'CloseRequestFcn',@sfQuit);

    figure(app.handles.fig)
    % create axes and image
    app.handles.im=imshow(app.im,app.clims);
    app.handles.ax=gca;
    if app.debug
      app.handles.scrollpanel=imscrollpanel(app.handles.fig,app.handles.im);
      app.handles.overview=imoverview(app.handles.im);
      app.handles.magbox=immagbox(app.handles.overview,app.handles.im);
      app.handles.contrast=imcontrast(app.handles.ax);
      %          set(app.handles.contrast,'visible','off')
      
      app.api.scrollpanel=iptgetapi(app.handles.scrollpanel);
      app.api.overview=iptgetapi(app.handles.overview);
      app.api.magbox=iptgetapi(app.handles.magbox);
      %          app.api.contrast=iptgetapi(app.handles.contrast);
      
      app.api.scrollpanel.setMagnification(app.api.scrollpanel.findFitMag());
      figure(app.handles.fig)  %put focus back on main window
    end
    app.handles.displayrange=imdisplayrange;
    % tweak refresh settings for fastest performance
    if 0
      set(app.handles.ax,'drawmode','fast')
      set(app.handles.im,'erasemode','none')
    end
    % make axes tight around image
    %        set(app.handles.ax,'xlim',[1 size(app.im,2)],'ylim',[1 size(app.im,1)])
    
    colormap(gray)
  end



%%  sfUpdateFigure
  function sfUpdateFigure(varargin)
    if nargin==0 % image content has changed in some fashion
      %      if isfield(app,'im') && length(app.im)>1024
      %        set(gcf,'name','Loading...','numbertitle','off');
      %        drawnow
      %      end
      app.currentfile=sprintf(app.fmtstring,app.prefix,app.currentimage,app.extension);
      app.nextfile=sprintf(app.fmtstring,app.prefix,sfWrap(app.currentimage+1,app.numberofimages),app.extension);
      app.prevfile=sprintf(app.fmtstring,app.prefix,sfWrap(app.currentimage-1,app.numberofimages),app.extension);
      
      if 1
        if exist(app.currentfile,'file')
          if 1
            
            if app.firsttime
              app.firsttime=false;
            elseif strcmpi(app.filechange,'positive')
              disp('Using next image')
              app.im_prev=app.im_original;
              app.im=app.im_next;
            elseif strcmpi(app.filechange,'negative')
              disp('Using previous image')
              app.im_next=app.im_original;
              app.im=app.im_prev;
            end
          else
            % test slowdown here
            app.im=edf_read(app.currentfile);
          end
          if ~isempty(app.roi)
            app.im=app.im(app.roi(1):app.roi(2),app.roi(3):app.roi(4));
          end
          app.im_original=app.im;  % make a copy if we have just changed the image
          % it doesn't take memory until one of the two is changed ('copy on
          % write')

        else
          fprintf('File %s does not exist!\n',app.currentfile);
        end
      else
        app.im=rand(1024);
      end
      if strcmpi(app.flatfield,'auto')
        fname_nextref=sprintf('refHST%04d.edf',...
          (floor(app.currentimage/app.acq.RefSpacing)+1)*app.acq.RefSpacing);
        fname_prevref=sprintf('refHST%04d.edf',...
          (floor(app.currentimage/app.acq.RefSpacing))*app.acq.RefSpacing);
        
        im_refNext=edf_read(fname_nextref)-app.im_dark;
        im_refPrev=edf_read(fname_prevref)-app.im_dark;
        
        % what ratio between the two references?
        fraction=mod(app.currentimage,app.acq.RefSpacing)/app.acq.RefSpacing;
        app.im_ref=(im_refNext.*(fraction))+(im_refPrev.*(1-fraction));
        app.im=(app.im_original-app.im_dark)./app.im_ref; % use the original for flatfield

        app.clims=[0 1];

      elseif strcmpi(app.flatfield,'manual')
        if isempty(app.flatfieldref) %|| isempty(app.flatfielddark)
          disp('Please specify the reference (and dark files, if you have one) on the command line')
          disp('[flatfieldref],[flatfielddark])')
          app.flatfield='none';
        else
          if exist(app.flatfielddark,'file')
          app.im_dark=edf_read(app.flatfielddark);
          else
            disp('Could not find dark file - using zeros')
            tmp=edf_info(app.flatfieldref);
            app.im_dark=zeros(tmp.dim_2,tmp.dim_1);
          end
          app.im_ref=edf_read(app.flatfieldref)-app.im_dark;
          app.im=(app.im_original-app.im_dark)./(app.im_ref); % use the original for flatfield
        end
      end
      if app.im_dolog==true
        app.im=real(log(app.im_original));
      end
      if any(isnan(app.im(:)))
        disp('Data has NaNs')
      end
      if any(isinf(app.im(:)))
        disp('Data has Infs')
      end

      set(app.handles.im,'cdata',app.im);
      set(app.handles.ax,'clim',app.clims);
      
      
    elseif strcmp(varargin{1},'clims') % COLORLIMITS HAVE CHANGED
      set(app.handles.ax,'clim',app.clims);
    end

    set(app.handles.fig,...
      'name',[num2str(app.currentimage) ': ' app.currentfile]);
    if app.debug
      set(imhandles(app.handles.overview),'cdata',app.im)
    end

    drawnow
    

    % preload next/previous file to save time...
    switch app.filechange
      case 'positive'  % Reading next file
        app.im_next=edf_read(app.nextfile);
      case 'negative' % Reading previous file
        app.im_prev=edf_read(app.prevfile);
      otherwise % Starting? Reading next file
        app.im_next=edf_read(app.nextfile);
    end
  end

%%  sfKeyPress
  function sfKeyPress(varargin)
    % varargin{2} contains the event details
    c=varargin{2};

    switch c.Key
      % CURSOR KEYS - COLOURMAP CHANGES
      %%%%%%%%%%%%%%%%%%%%%
      case 'uparrow'
        if strcmp(c.Modifier,'shift')
          disp('Increasing brightness')
          app.clims=app.clims-max(app.clims)*0.05;
        else
          disp('Increasing contrast')
           app.clims=(app.clims-mean(app.clims))*0.95 + mean(app.clims);
        end
        sfUpdateFigure('clims');
      case 'downarrow'
        if strcmp(c.Modifier,'shift')
          disp('Decreasing brightness')
          app.clims=app.clims+max(app.clims)*0.05;
        else
          disp('Decreasing contrast')
          app.clims=(app.clims-mean(app.clims))*1.05 + mean(app.clims);        
        end
        sfUpdateFigure('clims');
      case 'rightarrow'
        app.filechange='positive';
        if strcmp(c.Modifier,'shift')
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage+10,app.numberofimages);
        elseif strcmp(c.Modifier,'control')
          disp('Sequence')
          tic
          for n=1:20
            app.previousimage=app.currentimage;
            app.currentimage=sfWrap(app.currentimage+1,app.numberofimages);
            sfUpdateFigure
            pause(1)
          end
          toc
        else
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage+1,app.numberofimages);
        end
        sfUpdateFigure;
      case 'leftarrow'
        app.filechange='negative';
        if strcmp(c.Modifier,'shift')
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage-10,app.numberofimages);
        else
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage-1,app.numberofimages);
        end
        sfUpdateFigure;

        % OTHER KEYS
        %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
      case 'l'
        % take log of data
        if app.im_dolog==true
          app.im_dolog=false;
          sfStatus('Disabling log of image data');
        else
          app.im_dolog=true;
          sfStatus('Enabling log of image data');
        end
        sfUpdateFigure
      case 'm'
        % make a movie, and store it to disk
        moviefname='movie.avi';
        mov=avifile(moviefname);
        sfStatus('Creating movie')
        for n=1:app.numberofimages %        for app.currentimage=1:app.numberofimages
          app.currentimage=n;
          sfUpdateFigure
          mov=addframe(mov,getframe(gca));
        end
        mov=close(mov);
        sfStatus(['Movie saved to ' moviefname])

      case 'return'
        % write image to workspace 'im' variable
        disp('Variable ''im'' now contains image');
        assignin('base','im',app.im);

      case 'k'
        % stop for debugging
        sfStatus('Stopped for debugging - type ''return'' to continue')
        keyboard

        % COLOURMAP CHANGES
      case 'c'
        disp('Resetting colormap')
        app.clims=autolim(app.im,0.02);
        fprintf('%f %f',app.clims)
        sfUpdateFigure

      case 'q' % QUIT
        sfQuit
    end
  end

%%
  function sfAutomaticFlatfield
    if strcmpi(app.flatfield,'auto')
      sfStatus('Automatic flatfield*************')
      fname=[app.prefix '.xml'];
      if exist(fname,'file')
        disp('Using XML file')
        app.acq=query_xml(fname,'acquisition');
        disp('Dark file is hardcoded - fix this');
        app.im_dark=edf_read('darkend0000.edf')./app.acq.nDarks;
      else
        disp('Cannot find XML file - should set reference file manually');
        help(mfilename)
        app.flatfield='no';
      end
    end
  end
%%
  function sfStatus(msg)
    % could be changed to put status in GUI instead
    disp(msg)
  end
%%
  function sfQuit(varargin)
    disp('Quitting')
    set(app.handles.fig,'KeyPressFcn',[]);
    shh = get(0,'ShowHiddenHandles');
    set(0,'ShowHiddenHandles','on');
    currFig = get(0,'CurrentFigure');
    set(0,'ShowHiddenHandles',shh);
    delete(currFig);

  end
%%
  function n=sfWrap(m,limit)
    if m>limit
      n=1;
    elseif m<1
      n=limit;
    else
      n=m;
    end
  end
%%
  function sfFindNumberofImages
    d=dir([app.prefix '*' app.extension]);
    app.numberofimages=length(d);
    for n=1:app.numberofimages
      tmp=utilExtractFilenameParts(d(n).name);
      %      app.fileindices(n)=str2double(tmp.index);
      app.fileindices(n)=tmp.index;
    end
  end

%% sfDisplayParameters
  function sfDisplayParameters
    fprintf('Current settings: \n')
    fprintf('\tFilename prefix [prefix]: %s\n',app.prefix);
    fprintf('\tFilename extension [extension]: %s\n',app.extension);
    if strcmpi(app.extension,'edf')
      fprintf('\tZero padding of numbers [numlength]: %d\n',app.numlength)
    end
    if ~isempty(app.roi)
      fprintf('\tApplying ROI [roi]: (%d %d %d %d)\n',app.roi)
    else
      fprintf('\tNot applying ROI [roi]\n');
    end
    fprintf('\tFlatfield correction [flatfield]: %s\n',app.flatfield);
    if ~isempty(app.clims)
      fprintf('\tColour limits [clims]: %.1f %.1f\n',app.clims);
    end
    fprintf('\tCurrent image [currentimage]: %d\n',app.currentimage);

  end
end
