function sequence_downsample(varargin)
 % SEQUENCE_DOWNSAMPLE.M
 % Will try to automatically downsample an entire scan of images
 % Calls edf_downsample for each file
 
 d=dir('*.edf');
 for n=1:length(d)
   fnamein=d(n).name;
   fprintf('Processing %s\n',fnamein);
   edf_downsample(fnamein)
 end
 
 
 
 
 
 
 
 
 
 
 return
 
   if nargin==0 % run whole lot sequentially
    disp('Running normal version')
    % find directory name (which is prefix for all radiographs)
    [tmp,dname,tmp,tmp]=fileparts(pwd);

    fname_xml=[dname '.xml'];
    if ~exist(fname_xml,'file')
      fprintf('%s must exist!!\n',fname_xml)
      return
    end

    acq=query_xml(fname_xml,'acquisition');
    % read dark image
    if exist('dark.edf','file')
      % dark image has already been divided and can be used as-is
      im_dark=edf_read('dark.edf');
    elseif exist('darkend0000.edf','file')
      % dark image is a summed one - we can use and write the dark.edf while we
      % are at it...
      fprintf('Generating dark.edf\n')
      im_dark=edf_read('darkend0000.edf')./acq.nDarks;
      edf_write(im_dark,'dark.edf','uint16');
    else
      disp('No dark files!')
      return
    end
    % initialise with ref0
    fprintf('Reading reference image (refHST0000.edf)\n')
    im_refNext=edf_read('refHST0000.edf')-im_dark;
    im_refPrevious=im_refNext;
    clear meanN
    for n=0:acq.nRadio % loop over all files
      if n~=acq.nRadio % stupid check to avoid problems with the last file (1500 usually)
        if mod(n,acq.RefSpacing)==0
          % time to read some new reference images
          im_refPrevious=im_refNext;
          
          fname_nextref=sprintf('refHST%04d.edf',...
            (floor(n/acq.RefSpacing)+1)*acq.RefSpacing);
          fprintf('\nReading reference image (%s)\n',fname_nextref)
          im_refNext=edf_read(fname_nextref)-im_dark;
        end
      end

      % what ratio between the two references?
      fraction=mod(n,acq.RefSpacing)/acq.RefSpacing;

      fprintf('Correcting image %d... ',n);
      im=edf_read(sprintf('%s%04d.edf',dname,n))-im_dark;
      im_refN=(im_refNext.*(fraction))+(im_refPrevious.*(1-fraction));
      im_corrected=im./im_refN;
      meanN(n+1)=mean(im(:));
      fname_imC=sprintf('%sflat_%04d.edf',dname,n);
      fprintf('Writing result (%s)\r',fname_imC);
      %  imagesc(im_corrected,[0 1]),axis image,drawnow
      edfwrite(fname_imC,im_corrected,'float32');
      plot(meanN,'.'),drawnow
    end
    fprintf('\n')

  elseif nargin==1 % run parallel version
    if strcmpi(varargin{1},'parallel')
      % divide jobs into groups with just two reference images each
      disp('Parallel version')
      start=[0:100:1400];
      start=reshape(start,1,1,length(start));
      fprintf('This code needs improving to use the XML\n')
      % run the parallel client but don't wait for an answer ('&')
      parallel('sequence_flatfield&',start)
    else
      fprintf('Looking at slice %d and onwards\n',varargin{1})
      first=varargin{1};

      % find directory name (which is prefix for all radiographs)
      [tmp,dname,tmp,tmp]=fileparts(pwd);

      %check state of reference images (refHST*)
      if length(dir('refHST*'))==0
        fprintf('Need some corrected reference images.  Please use\n')
        fprintf('''sequence_median_refs'' to generate some!\n');
        return
      end

      fname_xml=[dname '.xml'];
      if ~exist(fname_xml,'file')
        fprintf('%s must exist!!\n',fname_xml)
        return
      end

      acq=query_xml(fname_xml,'acquisition');

      % read dark image
      if exist('dark.edf','file')
        % dark image has already been divided and can be used as-is
        im_dark=edf_read('dark.edf');
      elseif exist('darkend0000.edf','file')
        % dark image is a summed one - we can use and write the dark.edf while we
        % are at it...
        im_dark=edf_read('darkend0000.edf')./acq.nDarks;
        edfwrite('dark.edf',im_dark,'uint16');
      else
        disp('No dark files!')
        return
      end

      fname=sprintf('refHST%04d.edf',floor(first/acq.RefSpacing)*acq.RefSpacing);
      im_refPrevious=edfread(fname)-im_dark;

      fname=sprintf('refHST%04d.edf',(floor(first/acq.RefSpacing)+1)*acq.RefSpacing);
      im_refNext=edfread(fname)-im_dark;

      for n=first:first+acq.RefSpacing
        % what ratio between the two references?

        fprintf('Correcting image %d... ',n);
        im=edfread(sprintf('%s%04d.edf',dname,n))-im_dark;

        fraction=mod(n,acq.RefSpacing)/acq.RefSpacing;
        im_refN=(im_refNext.*(fraction))+(im_refPrevious.*(1-fraction));
        im_corrected=im./im_refN;

        fname_imC=sprintf('%sflat_%04d.edf',dname,n);
        fprintf('Writing result (%s)\r',fname_imC);
        edfwrite(fname_imC,im_corrected,'float32');
      end
      fprintf('\n')
    end
  end
end

