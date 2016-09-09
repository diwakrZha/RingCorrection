%% load all images in 3D array
function [cmy_c, cmx_c] = CenterDetermination(imdata)
    debug = 0;
    cmx_c = 0;
    cmy_c = 0 ;
    AcropSize=127; %accumulator crop size
    IcropSize=378; %accumulator crop size
    [m, n]=size(imdata);
    m = uint16(m);
    n = uint16(n);
    
if debug
    disp ('step 1')
end

%% circle find  
if debug 
    disp ('step 2')
end

    %disp('Finding the center of circles...')
    imdataGrThresh=imdata; % preprocessing to make hough reliable 
    gradientThreshold=0.01*max(imdataGrThresh(:));
    %imdataGrThresh=ring_im;
    
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
        %[cmx(k),cmy(k),smx(k),smy(k)] = centerofmass(accum_short); 
        [cmx,cmy] = centerofmass(accum_short); % no standard deviation
        %disp('center of mass calculated')
        
if debug
    disp ('step 3')
end

         % Maximum among the maximas indicating centers
        %[chy(k),chx(k)]=ind2sub(size(accum_short), find(accum_short==max(accum_short(:))));
        %disp('maximum in the accumulator matrix determined')
        
        cmx=round(cmx);
        cmy=round(cmy);
        %disp('center coordinates rounded off')
        
        a1 = max(accum_short(:)); 
        cm_a = accum_short(cmx,cmy); 
        bg=median(accum_short(:));
        %disp('fit parameters determined')
        
if debug
    disp ('step 4')
end

        %[sf_amax]=Gaussian2D(accum_short,bg,a1,chx(k),chy(k));
        
        [sf_cmmax]=Gaussian2D(accum_short,bg,a1,cmx,cmy);
        %[sf_cmmax]=Gaussian2D(accum_short,bg,cm_a,cmx(k),cmy(k));
        %disp('Performed gaussian fit over cropped accumulator with both initial parameters')
        
        %cy(k)=uint16(((m/2)+sf_amax.y0)-AcropSize);
        %cx(k)=uint16(((n/2)+sf_amax.x0)-AcropSize);
        %disp('MAxima in A, center coordinates recalculated for non-cropped images')
   
        cmy_c=uint16(((m/2)+sf_cmmax.y0)-AcropSize);
        cmx_c=uint16(((n/2)+sf_cmmax.x0)-AcropSize);
    %assignin ('base', 'centX', cmx_c)
    %assignin ('base', 'centY', cmY_c)
        %CentX(k) = cmx_cs
        %CentY(k) = cmy_c

    %disp('CM of A, center coordinates recalculated for non-cropped images')
    % k_nr=num2str(k); 
    % k_nr = ['found the center of rings in slice No.:    ', k_nr, ]; disp(k_nr);
%% median for smooth center
        %cmx_med = medfilt1(double(CentX(k)),med_window);
        %cmy_med = medfilt1(double(CentY(k)),med_window);
%% process all the images in the folder
    % shift the image in order to centere the ring artefacts
    
    %if   cmx_c >720 && cmx_c<675
    %    cmx_c=690;
    %end
    
    %if   cmy_c >1200 && cmy_c<675
    %    cmy_c =720;
    %end
end