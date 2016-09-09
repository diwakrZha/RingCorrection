function sequence_clean(varargin)
 % SEQUENCE_CLEAN.M
 % fixes hot pixels in detector using error map
 % STILL IN PROGRESS
 %
   if nargin==0 % run whole lot sequentially
    disp('Running normal version')
   d=dir('*.edf');
   maskfname='mask.edf';
   for n=1:length(d)
     im=edfreadandclean(d(n).name,maskfname);
     parts=utilExtractFilenameParts(d(n).name);
     if isempty(parts)
        % do something special for special files
       continue
     end
    
     newfname=[parts.prefix 'clean_' parts.index '.' parts.extension]
     edfwrite(newfname,im,'float32');
   end
   
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
        im_dark=edfread('dark.edf');
      elseif exist('darkend0000.edf','file')
        % dark image is a summed one - we can use and write the dark.edf while we
        % are at it...
        im_dark=edfread('darkend0000.edf')./acq.nDarks;
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

