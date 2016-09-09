%% Initialize the folder path
clear all;
close all;
clc;

disp('Initializing folder path parameters...')
tic;
%imagepath = '/Users/dj/Desktop/Limestone_005_DJT';
%imagepath = '/media/feynman/Storage/XVI_stefan/25nm/02-Highpass';
%Corrimagepath = '/media/feynman/JHA_dataVault/SandStone/CorrImgs';
centered = 1;
removeOutlier=0;
MedFiltDetectedCenter=0;
med_window=4;



disp('Initializing folder path parameters...')

%****************************** imagePath********************
imagepath = '/media/feynman/Storage/3D_multiscale_paper/Limestone2_0005_errorSlices/'; 

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


patternname = '*.tif'; % change it if the extension name is tif or other!
imagelist = dir(fullfile(imagepath,patternname));
[m, n]=size(imread(fullfile(imagepath,imagelist(1).name)));
p=length(imagelist);

%single image
%[m,n]=size(imread('/Users/dj/nano_ku/Chalk/report_ring_removal_algorithm/XV_premount_25nm_0006_32bit_815.tif'));

%[m, n]=size(imread('/Volumes/Data_disc/Nano_old/Chalk/256_XV_0006_25nm_seq_crp'));
m=uint16(m);
n=uint16(n);
image_nr=p;

AcropSize=127; %accumulator crop size
IcropSize=384; %accumulator crop size

cy=zeros(image_nr,1);
cx=zeros(image_nr,1);
smx=zeros(image_nr,1);
smy=zeros(image_nr,1);
   
disp('Parameters initialized!')

%% load all images in 3D array

for k=1:image_nr %numel(imagelist) 
    % disp('loading images...')
    imdata = double(imread(fullfile(imagepath,imagelist(k).name)));

%% circle find
if centered
    imgSlice = k;
    cmx_med = 690 %n/2;
    cmy_med =  720 %m/2;
    shiftedImage=imdata;
else
imgSlice=k;
    disp('Finding the center of circles...')
    imdataGrThresh=imdata;
    %imdataGrThresh=ring_im;
    gradientThreshold=0.01*max(imdataGrThresh(:));
    Img_short=imdataGrThresh((m/2-IcropSize):(m/2+IcropSize),(n/2-IcropSize):(n/2+IcropSize));
        
        [accum, circen, cirrad] = CircularHough_Grd(Img_short, [16 64], gradientThreshold, 30);
        %[accum, circen, cirrad] = CircularHough_Grd(imdata, [25 50], 17, 30);
         %disp('accumulation created')
         
         accum2=medfilt2(accum,[4 4]); % median filter the accumulation to remove the outliers
         %disp('median filtered')
         [a,b]=size(Img_short);
         %accum_short=accum;
         accum_short=accum2((a/2-AcropSize):(b/2+AcropSize),(a/2-AcropSize):(b/2+AcropSize));
         %disp('cropped accumulator')
         
         % center of mass of the 2D array
        %[cmx(imgSlice),cmy(imgSlice),smx(imgSlice),smy(imgSlice)] = centerofmass(accum_short); 
        [cmx(imgSlice),cmy(imgSlice)] = centerofmass(accum_short); % no standard deviation
        disp('center of mass calculated')
        
         % Maximum among the maximas indicating centers
        %[chy(imgSlice),chx(imgSlice)]=ind2sub(size(accum_short), find(accum_short==max(accum_short(:))));
        %disp('maximum in the accumulator matrix determined')
        
        cmx=round(cmx);
        cmy=round(cmy);
        %disp('center coordinates rounded off')
        
        a1 = max(accum_short(:)); 
        cm_a = accum_short(cmx(imgSlice),cmy(imgSlice)); 
        bg=median(accum_short(:));
        %disp('fit parameters determined')
        
        %[sf_amax]=Gaussian2D(accum_short,bg,a1,chx(imgSlice),chy(imgSlice));
        
        [sf_cmmax]=Gaussian2D(accum_short,bg,a1,cmx(imgSlice),cmy(imgSlice));
        %[sf_cmmax]=Gaussian2D(accum_short,bg,cm_a,cmx(imgSlice),cmy(imgSlice));
        disp('Performed gaussian fit over cropped accumulator with both initial parameters')
        
        %cy(imgSlice)=uint16(((m/2)+sf_amax.y0)-AcropSize);
        %cx(imgSlice)=uint16(((n/2)+sf_amax.x0)-AcropSize);
        %disp('MAxima in A, center coordinates recalculated for non-cropped images')
        
        cmy_c(imgSlice)=uint16(((m/2)+sf_cmmax.y0)-AcropSize);
        cmx_c(imgSlice)=uint16(((n/2)+sf_cmmax.x0)-AcropSize);
        disp('CM of A, center coordinates recalculated for non-cropped images')
    
    imgSlice_nr=num2str(imgSlice); 
    imgSlice_nr = ['found the center of rings in imgSlice No.:    ', imgSlice_nr]; disp(imgSlice_nr);

%% remove the outlier
        %remove outliers-
        if (cmx_c(imgSlice)>750 || cmx_c(imgSlice)<650) && imgSlice>4 ...
                && removeOutlier
         cmx_c(imgSlice)=cmx_c(imgSlice+1);
        else 
            cmx_c(imgSlice)=cmx_c(imgSlice);
         
        end
        
        if (cmy_c(imgSlice)>750 ||  cmy_c(imgSlice)<650) && imgSlice>4 ...
                && removeOutlier
          cmy_c(imgSlice)=cmy_c(imgSlice+1);
        else
            cmx_c(imgSlice)=cmx_c(imgSlice);
        end


%% median for smooth center
        cmx_med = medfilt1(double(cmx_c),med_window);
        cmy_med = medfilt1(double(cmy_c),med_window);
   
%% process all the images in the folder
    % shift the image in order to centere the ring artefacts
        shift_x(imgSlice)=abs((cmx_med(imgSlice)-(m/2))-1);
        shift_y(imgSlice)=abs((cmy_med(imgSlice)-(n/2))-1);

        %Left/right
        shiftedImage= imdata(:,mod((1:n)+n+shift_x(imgSlice),n)+1);

        %Up/Down
        shiftedImage = shiftedImage(mod((1:m)+m+shift_y(imgSlice),m)+1,:);
end
    ang_sampling=16;
    
    %ring correction
    tol=median(shiftedImage(:));
    [imcorr,ring_im,im2,inv_pyra,medpolar] =dj_remove_rings_v3(shiftedImage, tol, ang_sampling);
    %reshiftedImage=imcorr(:,:,imgSlice);
    disp('Ring corrected!')
if centered
    
    imgCorrected=imcorr;
else
    % shift the image in order to enhance the circles
        %Left/right
        reshiftedImage= imcorr(:,mod((1:n)+n-shift_x(imgSlice),n)+1);
        %Up/Down
        reshiftedImage = reshiftedImage(mod((1:m)+m-shift_y(imgSlice),m)+1,:);
        %imcorr(:,:,imgSlice)=reshiftedImage;    
    disp('Image reshifted!')
        % removal of phase contrast, smaller details in image etc.
    %im_median_filt(:,:,imgSlice) = medfilt2( reshiftedImage,[6 6],'symmetric'); % increase the size [14 14] if fine ring appears
    imgCorrected=reshiftedImage;
end
    imgSlice_nr=num2str(imgSlice);
    imgSlice_nr = ['Completed imgSlice No.:    ', imgSlice_nr]; disp(imgSlice_nr);
       
%% save the tiff files
    outputFileName = strcat(Corrimagepath,SaveFileName,'_',num2str(k),'.tif'); %change the prefixes
    imwrite(uint16(double(intmax('uint16'))*mat2gray(imgCorrected)), outputFileName)
end


%% display images
    figure (3);
    colormap ('gray');
    
    imshow(imdata, []);
    title('Original image');
    
    figure (4);
    imshow(imgCorrected, []);
    title('Ring corrected Image');
    
    axis square;
    colormap('gray');