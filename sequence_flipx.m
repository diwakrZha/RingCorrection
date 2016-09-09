function sequence_flipx(varargin)
  % SEQUENCE_FLIPX.M
  % Flips all edf files in directory in the x direction
  % March 2006
  % Greg
  %
  
  [tmp,dname,tmp,tmp]=fileparts(pwd);
  d=dir([dname '*.edf']);
  fname={d.name};

  if nargin==0 % run whole lot sequentially
    disp('Running normal version')

    sfProcess(1,1500);
    
  elseif nargin==1 % run parallel version
    if strcmpi(varargin{1},'parallel')
      % divide jobs into groups with just two reference images each
      disp('Parallel version')
      start=[0:100:1400];
      start=reshape(start,1,1,length(start));
      parallel('sequence_flipx',start)
    else
      fprintf('Looking at slice %d and onwards\n',varargin{1})
      first=varargin{1};

      sfProcess(first,first+100);
    end
  end
  function sfProcess(first,last)
    for n=first:last
      fprintf('%s\n',fname{n});
      edfwrite([fname{n} 'abc.edf'],flipud(edfread(fname{n})),'float32')
    end
  end
end

