function depsupport( product )

    if nargin == 0
        usage;
        return;
    else
        switch product
            case {'compiler','mex','builder'}
                % do nothing
            case {'path'}
                clipboard('copy',which('depsupport'));
                usage;
                return;
            otherwise
                usage;
                return;
        end
    end

    filename = [ tempname '.txt' ];
    diary(filename)

    section('current working directory')
    pwd

    section('MATLAB path')
    path

    section('matlabroot')
    matlabroot
    m=ver('matlab');
    if ( ~isempty(strfind(matlabroot,' ')) && ~strcmp(m.Release,'(R14SP3)') )
        warn('You have installed MATLAB into a path with spaces, this will likely cause problems.\n');
    end

    section('ver')
    ver

    % verify MATLAB Compiler versions match matlab versions %%%%%%%%%%%%%%%%%%%
    if ~strcmp(product,'mex')
        section('MATLAB and MATLAB Compiler Versions');

        m=ver('matlab');
        c=ver('compiler');

        [x y]=size(c);
        if x > 0 && y > 0
            % compiler found
            switch c.Release
                case {'(R14SP2)'}
                    if ~strcmp(m.Release,'(R14SP2)')
                        warn('You need to upgrade MATLAB to Release 14 Service Pack 2\nto use this version of MATLAB Compiler.\n');
                        return;
                    end
                case {'(R14SP1+)','(R14SP1)'}
                    if ~strcmp(m.Release,'(R14SP1)') && ~strcmp(m.Release,'(R14SP2)')
                        warn('You need to upgrade MATLAB to Release 14 Service Pack 1 or 2\nto use this version of MATLAB Compiler.\n');
                        return;
                    end
                case {'(R14+)','(R14)'}
                    if ~strcmp(m.Release,'(R14)') && ~strcmp(m.Release,'(R14SP1)') && ~strcmp(m.Release,'(R14SP2)')
                        warn('You need to use a version of MATLAB Release 14\nto use this version of MATLAB Compiler.\n');
                        return;
                    end
                otherwise
                    % do nothing
            end
        end
        fprintf('OK.\n');
    end

    % verify that their compiler is ANSI compliant %%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if isunix
        section('ANSI compliance');
        source = [tempname '.c'];
        output = tempname;
        fid = fopen(source,'wt');
        fprintf(fid,'#include<stdio.h>\n');
        fprintf(fid,'void test() {\n');
        fprintf(fid,'printf("hello world\\n");\n');
        fprintf(fid,'return;\n');
        fprintf(fid,'}\n');
        fprintf(fid,'int main(int argc, char* argv[])\n');
        fprintf(fid,'{\n');
        fprintf(fid,'    const int testvar = 0;\n');
        fprintf(fid,'    test();\n');
        fprintf(fid,'    return testvar;\n');
        fprintf(fid,'}\n');
        fclose(fid);

        command = ['cc -o ' output ' ' source ];
        fprintf([command '\n']);
        [s,w]=system(command);
        fprintf([w '\n']);

        if s
            warn('\nYour cc compiler is probably not ANSI compliant and therefore not compatible.\n');
            warn('See Tech Note 1601 for more details.\n\n');
        end
        fprintf(['Running: ' output '\n']);
        [s,w]=system(output);
        fprintf([w '\n']);
        if s
            warn('\nThe test hello world program failed to run successfully.\n');
            warn('It is highly likely that something is wrong with your cc compiler.\n');
        end

        command = ['gcc -o ' output ' ' source ];
        fprintf([command '\n']);
        [s,w]=system(command);
        fprintf([w '\n']);
        if s
            warn('\nYour gcc compiler is probably not ANSI compliant and therefore not compatible.\n');
            warn('See Tech Note 1601 for more details.\n\n');
        end
        fprintf(['Running: ' output '\n']);
        [s,w]=system(output);
        fprintf([w '\n']);
        if s
            warn('\nThe test hello world program failed to run successfully.\n');
            warn('It is highly likely that something is wrong with your gcc compiler.\n');
        end

    end

    % Verify that their compiler is the correct version %%%%%%%%%%%%%%%%%%%%%%%

    if isunix
        section('Compiler Version Check');

        m=ver('matlab');
        comp = computer;
        try
            switch m.Release
                case {'(R14SP2)','(R14SP1)','(R14+)','(R14)'}
                    switch comp
                        case {'GLNX86','GLNXA86'}
                            if ~system('which gcc')
                                [s,w]=system('gcc --version')
                                fprintf([w '\n']);
                                % gcc (GCC) 3.2.3
                                [s,f,t]=regexp(w,'gcc \(GCC\) ([0-9\.]+)');
                                if ~strcmp(w(t{1}(1):t{1}(2)),'3.2.3')
                                    warn('\nYou are using an unsupported gcc version!\n');
                                    warn('See Tech Note 1601 for more details.\n\n');
                                end
                            end
                        case {'MAC'}
                            if ~system('which gcc')
                                [s,w]=system('gcc --version')
                                fprintf([w '\n']);
                                % gcc (GCC) 3.2.3
                                [s,f,t]=regexp(w,'gcc \(GCC\) ([0-9\.]+)');
                                if ~strcmp(w(t{1}(1):t{1}(2)),'3.3')
                                    warn('\nYou are using an unsupported gcc version!\n');
                                    warn('See Tech Note 1601 for more details.\n\n');
                                end
                            end
                        case 'SOL2'
                            if ~system('which gcc')
                                [s,w]=system('gcc --version')
                                fprintf([w '\n']);
                                % gcc (GCC) 3.2.3
                                [s,f,t]=regexp(w,'gcc \(GCC\) ([0-9\.]+)');
                                if ~strcmp(w(t{1}(1):t{1}(2)),'3.2.3')
                                    warn('\nYou are using an unsupported gcc version!\n');
                                    warn('See Tech Note 1601 for more details.\n\n');
                                end
                            end
                            if ~system('which cc')
                                [s,w]=system('cc -V')
                                fprintf([w '\n']);
                                % cc: Sun C 5.5 Patch 112760-08 2004/02/20
                                [s,f,t]=regexp(w,'Sun C ([0-9\.]+)');
                                if ~strcmp(w(t{1}(1):t{1}(2)),'5.5')
                                    warn('\nYou are using an unsupported cc version!\n');
                                    warn('See Tech Note 1601 for more details.\n\n');
                                end
                            end
                        otherwise

                            [s,w]=system('cc -V')
                            fprintf([w '\n']);
                            [s,w]=system('cc -v')
                            fprintf([w '\n']);
                            [s,w]=system('acc -v')
                            fprintf([w '\n']);
                            [s,w]=system('aCC -v')
                            fprintf([w '\n']);
                            % do nothing
                    end

                otherwise
                    % do nothing
            end

        catch
            warn('\nError checking compiler versions!\n');
        end

    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if strcmp(product,'mex')
        section('mex -setup');
        mex -setup
    end

    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    if ~strcmp(product,'mex')

        section('mbuild -setup');
        mbuild -setup
    end
    % if Builder, verify MSVC %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

    if strcmp( product, 'builder' )
        section('Compiler Check for Builder Products');
        res = currentCompiler;
        if ~strcmp(lower(res),'msvc60compp.bat') && ~strcmp(lower(res),'msvc70compp.bat') && ~strcmp(lower(res),'msvc71compp.bat')
            warn('You need to choose a compiler that is compatible with the Builder products.\nSee Tech Note 1601 for details.\n\n')
            web http://www.mathworks.com/support/tech-notes/1600/1601.html
            mbuild -setup
        else
            fprintf('OK.\n');
        end
    end

    if strcmp( product, 'builder' )
        section('Component Info')
        res = componentinfo;
        printcomponents( res );
    end

    section('Verbose Build');
    s = [];
    while isempty(strfind(s,'-v') )

        switch product
            case {'compiler'}
                s=input('\nEnter the MCC or MBUILD command to compile your application.\nYou may want to use the up/down arrows to find it.\nIf so, type "mcc " or "mbuild " and then hit your up arrow.\nBe sure to include the -v flag for verbose output.\nTechnical support needs verbose output:  ','s');
            case {'mex'}
                s=input('\nEnter the MEX command to compile your application.\nYou may want to use the up/down arrows to find it.\nIf so, type "mex " and then hit your up arrow.\nBe sure to include the -v flag for verbose output.\nTechnical support needs verbose output:  ','s');
            case {'builder'}
                s=input('\nEnter the an MCC command to compile any simple M-function you have.\nWe need to verify that MATLAB Compiler works fine for you.\nIf you need to change directories first, you can do something like: cd d:\temp, mcc -mv test.m\nYou may want to use the up/down arrows to find it.\nIf so, type "mcc " and then hit your up arrow.\nBe sure to include the -v flag for verbose output.\nTechnical support needs verbose output:  ','s');
            otherwise
                % do nothing
        end
        if isempty(strfind(s,'-v') )
            fprintf('\n!!! -v is required for verbose output.\n');
        end

    end
    try
        eval(s)
    catch
        warn(['\n' s '\nfailed!\n']);
    end


    section('More UNIX Compiler Checking');
    if ~ispc
        !cc -v
        !cc --version
        !cc -ver
        !which cc
        !gcc --version
        !which gcc
    end

    section('Environment Variables');

    if isunix
        fprintf('LD_LIBRARY_PATH = ');
        getenv LD_LIBRARY_PATH
        fprintf('SHLIB_PATH = ');
        getenv SHLIB_PATH
        fprintf('DYLD_LIBRARY_PATH = ');
        getenv DYLD_LIBRARY_PATH
        fprintf('XAPPLRESDIR = ');
        getenv XAPPLRESDIR
        fprintf('SHELL = ');
        getenv SHELL
        fprintf('LD_ASSUME_KERNEL = ');
        getenv LD_ASSUME_KERNEL


        r='';
        while ~strcmp(r,'y') && ~strcmp(r,'n')
            r = input('Are you trying to use MATLAB Engine (y/n)?\n','s');
        end

        if strcmp(r,'y')

            section('Verify CSH');
            !which csh
            !ls -l /bin/*csh
            !ls -l /usr/bin/*csh
            shell = getenv('SHELL');
            if ~strcmp(shell,'csh') && ~strcmp(shell,'/bin/csh') && ~strcmp(shell,'/usr/bin/csh')
                warn(['You need to have csh as your shell in order to start a MATLAB Engine program instead of ' shell '!\n']);
            else
                fprintf('OK.\n');
            end

            section('Verify Library Path');
            % verify LD_LIBRARY_PATH if engine %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            % http://www.mathworks.com/support/solutions/data/1-1BSZR.html?solution=1-1BSZR
            %
            % 1. Set the runtime library path environment variable LD_LIBRARY_PATH to:
            % <matlab>/extern/lib/<arch>:<matlab>/sys/os/<arch>:$LD_LIBRARY_PATH
            path1 = [matlabroot '/extern/lib/' arch];
            path2 = [matlabroot '/sys/os/' arch];

            comp = computer;
            switch comp
                case {'HPUX'}
                    ldpath = getenv('SHLIB_PATH');
                case {'MAC'}
                    ldpath = getenv('DYLD_LIBRARY_PATH');
                otherwise
                    ldpath = getenv('LD_LIBRARY_PATH');
            end

            if isempty(strfind(ldpath,path1)) || isempty(strfind(ldpath,path2))
                warn('You need to set the Library Path as in Solution 1-1BSZR!\n');
                web http://www.mathworks.com/support/solutions/data/1-1BSZR.html
            else
                fprintf('OK.\n');
            end
        end


    end

    fprintf('PATH = ');
    getenv PATH

    section('UNIX System Info');

    if isunix
        !uname -a
    end

    comp = computer;

    if ~isempty(strfind(comp,'GLNX'))
        !/lib/libc.so.6
        % see if we can get the distribution version here
        !cat /etc/issue.net
        !cat /proc/cpuinfo
    end

    section('Files On Path');

    search_path matlab

    if ispc
        search_path perl -all
        search_dll_path libut.dll
        search_dll_path mclmcrrt71.dll
        search_dll_path libmx.dll
    end

    if exist('startup')
        section('startup.m')
        type startup
    end

    section('matlabrc.m')
    which -all matlabrc
    if exist('matlabrc')
        type matlabrc
    end

    diary off
    edit(filename)

    fprintf('\n-----------------------------------------------------------------\n');

    fprintf('At this point, take a look at the file in the editor and\nsee if there is anything you can identify as possibly the problem.\n');
    fprintf('If you can not identify the problem yourself, send the output to technical support in an e-mail.\n\n');
end

function where = search_path(what,switches)

    %SEARCH_PATH Searches the system path for executables
    %   SEARCH_PATH S1 returns the path to the executable S1 if
    %   it exist anywhere in the system path.
    %
    %   S = SEARCH_PATH(S1) returns the results of SEARCH_PATH in
    %   the string S instead of printing it to the screen.  S will
    %   be the string of the executable S1.  You must use the
    %   functional form of SEARCH_PATH when there is an output argument.
    %
    %   W = SEARCH_PATH(S1,'-all') returns the results of the multiple
    %   search version of SEARCH_PATH in the cell array W.  W will
    %   contain the path strings normally printed to the screen.
    %
    %   SEARCH_PATH S1 -ALL displays the paths to all executables with
    %   the name S1. The -ALL flag can be used withs all forms of SEARCH_PATH.
    %
    %   Windows executables must end in .EXE for it to find them, however
    %   you should not put a .EXE on your search.
    %
    %   Examples:
    %       search_path notepad
    %       search_path notepad -all
    %       search_path ls

    %   Copyright 1984-2002 The MathWorks, Inc.

    % this belongs in here if we use the found variable, but I've removed that
    %function [where, found ] = search_path(what,switches)
    %   [where, found] = SEARCH_PATH(S1) returns the path to the executable if
    %   it exist anywhere in the system path, and a boolean value for whether
    %   it was found or not.

    if nargin < 2
        switches = '';
    end;

    % this is something I think all of our functions should have, at least for
    % nargin == 0
    if nargin == 0 | nargin > 2 | ( nargin == 2 & ~strcmp(switches,'-all') )
        help search_path
        return;
    end;

    all = strcmp(switches,'-all');
    where = {};
    %found = false;
    token = '';
    ext = '';

    if ispc
        token = ';';
        ext = '.exe';
    elseif isunix
        token = ':';
    else
        error('SEARCH_PATH only works on UNIX or Windows');
    end;

    rem = getenv('PATH');
    i=1;
    while ~isempty(rem);
        [a_path,rem]=strtok(rem,token);
        % if you want to debug, uncomment this
        % sprintf('Searching for %s', strcat(a_path,filesep,what,ext) )
        if exist(strcat(a_path,filesep,what,ext));
            %found = true;
            if ~all
                where = strcat(a_path,filesep,what,ext);
                rem = '';
            else
                where{i,1} = strcat(a_path,filesep,what,ext);
                i = i + 1;
            end;
        end
    end
    if iscell(where)
        where=unique(where);
    end;
end

function where = search_dll_path(what,switches)

    if nargin < 2
        switches = '';
    end;

    % this is something I think all of our functions should have, at least for
    % nargin == 0
    if nargin == 0 | nargin > 2 | ( nargin == 2 & ~strcmp(switches,'-all') )
        help search_path
        return;
    end;

    all = 1;%strcmp(switches,'-all');
    where = {};
    %found = false;
    token = '';
    ext = '';

    if ispc
        token = ';';
        ext = '';
    elseif isunix
        token = ':';
    else
        error('SEARCH_PATH only works on UNIX or Windows');
    end;

    rem = [ getenv('PATH') token getenv('windir') filesep 'system' token getenv('windir') filesep 'system32' ];
    i=1;
    while ~isempty(rem);
        [a_path,rem]=strtok(rem,token);
        if a_path(end) == filesep
            a_path = a_path(1:end-1);
        end
        % if you want to debug, uncomment this
        % sprintf('Searching for %s', strcat(a_path,filesep,what,ext) )
        if exist(strcat(a_path,filesep,what,ext));
            %found = true;
            if ~all
                where = strcat(a_path,filesep,what,ext);
                rem = '';
            else
                where{i,1} = strcat(a_path,filesep,what,ext);
                i = i + 1;
            end;
        end
    end

    if iscell(where)
        where=unique(where);
    end;

end

function warn( str )
    fprintf( str );
    %warndlg( strrep( str, '\n', '' ) );
end

function usage
    fprintf('\nYou should call this function in one of the following ways:\n');
    fprintf('   depsupport compiler     %% for MATLAB Compiler\n');
    fprintf('   depsupport mex          %% for a MEX or MATLAB Engine issue\n');
    fprintf('   depsupport builder      %% for Builder for COM or Builder for Excel\n\n');
end

function c = currentCompiler
    cd(prefdir)
    res = exist('compopts.bat','file');
    if res == 0
        c = 'none chosen yet'
        return;
    end
    fid=fopen('compopts.bat','rt');
    line = fgetl(fid);
    line = fgetl(fid);
    c = line( 5:end );
end

function section( str )
    fprintf('\n ------------- %s -------------\n\n', upper(str) );
end

function printcomponents( res )
    for i=1:length(res)
        fprintf('Component %i:\n\n',i);
        temp = res(i);
        fprintf('          Name: ''%s''\n',temp.Name);
        fprintf('       TypeLib: ''%s''\n',temp.TypeLib);
        fprintf('         LIBID: ''%s''\n',temp.LIBID);
        fprintf('      MajorRev: %i\n',temp.MajorRev);
        fprintf('      MinorRev: %i\n',temp.MinorRev);
        fprintf('      FileName: ''%s''\n',temp.FileName);
        fprintf('    Interfaces:\n');
        fprintf('              Name: ''%s''\n',temp.Interfaces.Name);
        fprintf('               IID: ''%s''\n',temp.Interfaces.IID);
        fprintf('     CoClasses:\n');
        fprintf('              Name: ''%s''\n',temp.CoClasses.Name);
        fprintf('             CLSID: ''%s''\n',temp.CoClasses.CLSID);
        fprintf('            ProgID: ''%s''\n',temp.CoClasses.ProgID);
        fprintf('      VerIndProgID: ''%s''\n',temp.CoClasses.VerIndProgID);
        fprintf('    InprocServer32: ''%s''\n',temp.CoClasses.InprocServer32);
        for j=1:length(temp.CoClasses.Methods)
            fprintf('        Methods(%i):\n',j);
            fprintf('                   IDL: ''%s''\n',temp.CoClasses.Methods(j).IDL);
            fprintf('                     M: ''%s''\n',temp.CoClasses.Methods(j).M);
            fprintf('                     C: ''%s''\n',temp.CoClasses.Methods(j).C);
            fprintf('                    VB: ''%s''\n\n',temp.CoClasses.Methods(j).VB);
        end
    end

end

function a = arch
    c = computer;
    if strcmp(c,'PCWIN')
        a = 'win32';
    else
        a = lower( c );
    end

end
