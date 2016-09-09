%% Initialize the folder path
clear all;
close all;
clc;
warning('off','all')

%****************************** set the initial parameters ****
centered = 0;
removeOutlier = 0;
MedFiltDetectedCenter = 1;
med_window = 4;                      
debug = 0;
testFewSlices = 0 ; % set to zero for all files


disp('Initializing folder path parameters...')

%****************************** imagePath********************
imagepath = '/media/baelo/JHA_dataVault/Dominique/Sandstone_dirty_25nm_tomo2_app8_slices_16bi'; 

patternname = '*.tif'; % change it if the extension name is tif or other!
imagelist = dir(fullfile(imagepath,patternname));
[m, n] = size(imread(fullfile(imagepath,imagelist(1).name)));
p=length(imagelist);

SaveFileName = strsplit((getfield(imagelist,'name')) , '.');
SaveFileName = strcat(SaveFileName(1), '_ringCor_');
SaveFileName=SaveFileName{1};

%******************Corrected Image path**********************
Corrimagepath=strsplit(imagepath,'/');
Corrimagepath=fullfile('/',Corrimagepath{1:end-1});
Corrimagepath = strcat(Corrimagepath, '/',SaveFileName,'/');
%Corrimagepath=Corrimagepath{1};

if ~exist(Corrimagepath, 'dir')
    mkdir(Corrimagepath);
end

%****************Override the automatic subfolder creation*******
%Corrimagepath= '/media/feynman/JHA_dataVault/Data/P3_processed/'


%single image
%[m,n]=size(imread('/Users/dj/nano_ku/Chalk/report_ring_removal_algorithm/XV_premount_25nm_0006_32bit_815.tif'));

%[m, n]=size(imread('/Volumes/Data_disc/Nano_old/Chalk/256_XV_0006_25nm_seq_crp'));
m=uint16(m);
n=uint16(n);
centX=zeros(p,1);
centY=zeros(p,1);

AcropSize=127; %accumulator crop size
IcropSize=378; %accumulator crop size

%***** 
if testFewSlices  
    image_nr=testFewSlices;
else
    image_nr = p;
end

disp('Parameters initialized!')
disp(strcat('Corrected files will be saved at: ', Corrimagepath))

%% load all images in 3D array
tic;
parfor k=1:image_nr %numel(imagelist) 
    warning('off','all')
    
    k_nr=num2str(k);
    k_nr = ['reading slice no.:    ', k_nr]; disp(k_nr);
    
    
    
    imdata = double(imread(fullfile(imagepath,imagelist(k).name)));
    [m, n]=size(imdata);
    m = uint16(m);
    n = uint16(n);
    
if debug
    disp ('step 1')
end

%circle find
if centered
    cmx_med = n/2;
    cmy_med = m/2;
    shiftedImage=imdata;
else
    
[cmy_c(k), cmx_c(k)] = CenterDetermination(imdata)
end
end

disp ('center for the rings determined')
%% median for smooth center
if MedFiltDetectedCenter
        cmx_med = medfilt1(double(cmx_c),med_window);
        cmy_med = medfilt1(double(cmy_c),med_window);
else
    cmx_med=cmx_c;
    cmy_med=cmy_c;
end

%% Correct the rings
disp ('ring correcting the slices')
parfor k=1:image_nr %numel(imagelist) 
    warning('off','all')
    
    k_nr=num2str(k);
    k_nr = ['reading slice no.:    ', k_nr]; disp(k_nr);
    
    
    
    imdata = double(imread(fullfile(imagepath,imagelist(k).name)));
    [m, n]=size(imdata);
    m = uint16(m);
    n = uint16(n);
    
       shift_x=abs((cmx_med(k)-(m/2))-1);
       shift_y=abs((cmy_med(k)-(n/2))-1);

%Left/right
shiftedImage= imdata(:,mod((1:n)+n+shift_x,n)+1);

%Up/Down
shiftedImage = shiftedImage(mod((1:m)+m+shift_y,m)+1,:);

    ang_sampling=8;
    
    %ring correction
    tol=median(shiftedImage(:));
    [imcorr,ring_im,im2,inv_pyra,medpolar] =dj_remove_rings_v3(shiftedImage, tol, ang_sampling);
    %reshiftedImage=imcorr(:,:,k);
    %disp('Ring corrected!')
if centered
    
    imgCorrected=imcorr;
else
    % shift the image in order to enhance the circles
        %Left/right
        reshiftedImage= imcorr(:,mod((1:n)+n-shift_x,n)+1);
        %Up/Down
        reshiftedImage = reshiftedImage(mod((1:m)+m-shift_y,m)+1,:);
        %imcorr(:,:,k)=reshiftedImage;    
    %disp('Image reshifted!')
        % removal of phase contrast, smaller details in image etc.
    %im_median_filt(:,:,k) = medfilt2( reshiftedImage,[6 6],'symmetric'); % increase the size [14 14] if fine ring appears
    imgCorrected=reshiftedImage;
end
    k_nr=num2str(k);
    k_nr = ['Completed slice No.:    ', k_nr]; disp(k_nr);
       
%% save the tiff files
    outputFileName = strcat(Corrimagepath,SaveFileName,'_',num2str(k),'.tif'); %change the prefixes
    imwrite(uint16(double(intmax('uint16'))*mat2gray(imgCorrected)), outputFileName)
    %fitswrite(im2uint16(imgCorrected), outputFileName );
end
toc;

%% display images
%%    figure (3);
%%    colormap ('gray');
    
%    imshow(imdata, []);
%    title('Original image');
%    
%    figure (4);
%    imshow(imgCorrected, []);
%    title('Ring corrected Image');
%    
%    axis square;
%    colormap('gray');