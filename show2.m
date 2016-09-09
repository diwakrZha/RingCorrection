function show2(varargin)
  % Newish way of writing GUI programs - nice handling of callbacks with
  % function handles and better parsing of command line - parse_pv_pairs.m
  %
  % Specify the structure field name as an argument to the function, and it
  % will nicely be modified:
  %
  % show2('currentimage',3,'prefix','myspecialprefix_')
  %
  % 
  % parameters can be used in any order
  % useful parameters are: currentimage, prefix, extension, numlength (not
  % sure it's needed anymore), cmap

  sfInitialiseFigure;
  if nargin>0
    % parse_pv_pairs will not remove any part of the structure...
    app=parse_pv_pairs(app,varargin); 
  end
  sfFindNumberOfImages;
  sfUpdateFigure;

  %% sfInitialiseFigure
  function sfInitialiseFigure
    warning('off','Images:initSize:adjustingMag');
    [tmp,dname,tmp,tmp]=fileparts(pwd);
    app.prefix=dname;
    app.extension='edf';
    app.currentimage=1;
    app.numlength=4;
    app.clims=[];
    app.flatfield='no';
    app.h_fig=figure;
    app.h_histogram=figure;
    set(app.h_histogram,'visible','off')
    app.firsttime=1;
    set(app.h_fig,'keypressfcn',@sfKeyPress)
  end

  %% sfFindNumberOfImages
  function sfFindNumberOfImages
    d=dir([app.prefix '*.' app.extension]);
    app.numberofimages=length(d);
    [app.filenames{1:app.numberofimages}]=deal(d.name);
    app.filenames=sort(app.filenames);
  end

  %%  sfUpdateFigure
  function sfUpdateFigure(varargin)
    if nargin==0 % file has changed or flatfield correction toggled
      if isfield(app,'im') && length(app.im)>1024
        set(gcf,'name','Loading...','numbertitle','off');
        drawnow
      end
      
      if strcmpi(app.extension,'edf')
        app.im=edfread(app.filenames{app.currentimage})';
      else
        app.im=imread(app.filenames{app.currentimage});
      end
      
      if strcmpi(app.flatfield,'yes')
        fname_nextref=sprintf('refHST%04d.edf',...
          (floor(app.currentimage/app.acq.RefSpacing)+1)*app.acq.RefSpacing);
        fname_prevref=sprintf('refHST%04d.edf',...
          (floor(app.currentimage/app.acq.RefSpacing))*app.acq.RefSpacing);
        
        fprintf('\nReading reference image (%s, %s)\n',fname_prevref,fname_nextref)
        im_refNext=edfread(fname_nextref)-app.im_dark;
        im_refPrev=edfread(fname_prevref)-app.im_dark;
        
        % what ratio between the two references?
        fraction=mod(app.currentimage,app.acq.RefSpacing)/app.acq.RefSpacing;
        
        im_ref=(im_refNext.*(fraction))+(im_refPrev.*(1-fraction));
        app.im=app.im./im_ref';
      end
      if app.firsttime
        app.clims=[min(app.im(:)) max(app.im(:))];
        disp('Resetting colourmap')
        app.firsttime=0;
      end

      
    elseif strcmp(varargin{1},'clims') % COLORLIMITS HAVE CHANGED
    end
    
    figure(app.h_fig)
    imshow(app.im,app.clims);

    
    set(gcf,...
      'name',[num2str(app.currentimage) ': ' app.filenames{app.currentimage}],...
      'numbertitle','off',...
      'menubar','none')
    drawnow;
  end

  %%  sfKeyPress
  function sfKeyPress(varargin)
    % varargin{2} contains the event details 
    c=varargin{2};

    switch c.Key
      % CURSOR KEYS
      case 'uparrow'
        sfUpdateFigure;
      case 'downarrow'
        sfUpdateFigure;
      case 'rightarrow'
        if strcmp(c.Modifier,'shift')
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage+10,app.numberofimages);
        elseif strcmp(c.Modifier,'control')
          disp('Movie')
          while 1
            app.previousimage=app.currentimage;
            app.currentimage=sfWrap(app.currentimage+10,app.numberofimages);
            sfUpdateFigure
          end
        else
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage+1,app.numberofimages);
        end
        sfUpdateFigure;
      case 'leftarrow'
        if strcmp(c.Modifier,'shift')
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage-10,app.numberofimages);
        elseif strcmp(c.Modifier,'control')
          disp('moving')
          while 1
            app.previousimage=app.currentimage;
            app.currentimage=sfWrap(app.currentimage-10,app.numberofimages);
            sfUpdateFigure
          end
        else
          app.previousimage=app.currentimage;
          app.currentimage=sfWrap(app.currentimage-1,app.numberofimages);
        end
        sfUpdateFigure;
        
        % OTHER KEYS
      case 'return'
        if isempty(c.Modifier) % just a plain keystroke
          % write image to workspace 'im' variable
          disp('Variable ''im'' now contains image');
          assignin('base','im',app.im);
        end
      case 'h'
        figure(app.h_histogram)
        set(app.h_histogram,'visible','on')
        hist(app.im(:),100)
        figure(app.h_fig)
        
        % COLOURMAP CHANGES
      case 'c'
        disp('Resetting colormap')
        app.clims=[min(app.im(:)) max(app.im(:))];
        sfUpdateFigure
      case '1'
        disp('Increasing contrast')
        app.clims=app.clims*0.95;
        sfUpdateFigure('clims');
      case '2'
        disp('Decreasing contrast')
        app.clims=app.clims*1.05;
        sfUpdateFigure('clims');
      case '3'
        disp('Colormap brighter')
        app.clims=app.clims-max(app.clims)*0.05;
        sfUpdateFigure('clims');
      case '4'
        disp('Colormap darker')
        app.clims=app.clims+max(app.clims)*0.05;
        sfUpdateFigure('clims');
      % TOGGLE FLAT CORRECTION
      case 'd'
        if strcmpi(app.flatfield,'yes')
          disp('Disabling flatfield correction')
          app.flatfield='no';
          app.firsttime='yes';
          sfUpdateFigure
        else
          disp('Enabling flatfield correction')
          app.flatfield='yes';
          app.firsttime='yes';
          
          fname=[app.prefix '.xml'];
          if exist(fname,'file')
            disp('Using XML file')
            app.acq=query_xml(fname,'acquisition');
            disp('Dark file is hardcoded - fix this');
            app.im_dark=edfread('dark.edf');
            sfUpdateFigure
          else
            disp('Cannot find XML file - will need to set reference file manually');
            app.flatfield='no';
            sfUpdateFigure
          end
        end
      case 'q' % QUIT
        set(app.h_fig,'KeyPressFcn',[]);
        close(app.h_histogram);
    end
  end


  function n=sfWrap(m,limit)
    if m>limit
      n=1;
    elseif m<1
      n=limit;
    else
      n=m;
    end
  end
end
