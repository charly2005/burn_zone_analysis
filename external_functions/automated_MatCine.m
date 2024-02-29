function [header, bitmap, setup, raw_image_array]=automated_MatCine(filename)
%%%%%%% Edited by Erik, removed cropping for autmated stuff!!!
%% MATCINE - Cine Extraction Software for Matlab
%  Dylan J. Kline
%  University of Maryland College Park / NASA Goddard Space Flight Center
%  dkline@umd.edu / dylan.kline@nasa.gov

%  This program has been designed to extract raw data from a Cine recorded
%  file produced by the Vision Research Phantom Miro M110. It is based on
%  the file format as described in the file 'Cine File Format June 2011' by
%  Vision Research.

%  Adapted from PyCine_V2 by Adam D. Light and Dylan J. Kline

%% File Selection

% %  Pick Cine File
% [files, path]=uigetfile({'*.cine'}, 'Pick a Cine File');
% filename=fullfile(path, char(files));

%  Open Cine file
cine = fopen(filename);

%% Header

header_length = 44;         % first 44 bytes are header

header.Type = fscanf(cine,'%c',2);
header.Headersize = fread(cine,1,'ushort');
header.Compression = fread(cine,1,'ushort');
header.Version = fread(cine,1,'ushort');
header.FirstMovieImage = fread(cine,1,'long');
header.TotalImageCount = fread(cine,1,'uint');
header.FirstImageNo = fread(cine,1,'long');
header.ImageCount = fread(cine,1,'uint');
header.OffImageHeader = fread(cine,1,'uint');
header.OffSetup = fread(cine,1,'uint');
header.OffImageOffsets = fread(cine,1,'uint');
header.TriggerTime = [fread(cine,1,'uint'), fread(cine,1,'uint')];

if ftell(cine)~=header_length
    disp('There has been an error reading the header!');
    return;
end
    
%% Bitmap Info
bitmapinfo_length = 40;     % next 40 bytes are bitmap header

bitmap.biSize = fread(cine,1,'uint');
bitmap.biWidth = fread(cine,1,'long');
bitmap.biHeight = fread(cine,1,'long');
bitmap.biPlanes = fread(cine,1,'ushort');
bitmap.biBitCount = fread(cine,1,'ushort');
bitmap.biCompression = fread(cine,1,'uint');
bitmap.biSizeImage = fread(cine,1,'uint');
bitmap.biXPelsPerMeter = fread(cine,1,'long');
bitmap.biYPelsPerMeter = fread(cine,1,'long');
bitmap.biClrUsed = fread(cine,1,'uint');
bitmap.biClrImportant = fread(cine,1,'uint');

if ftell(cine)~=header_length+bitmapinfo_length
    disp('There has been an error reading the bitmap info!');
    return;
end

if bitmap.biBitCount~=16
    disp('Your video is not 16bpp unpacked!');
    return;
end

%% Deprecated Skip
deprecated_skip=140;

fseek(cine,deprecated_skip,0);

if ftell(cine)~=header_length+bitmapinfo_length+deprecated_skip
    disp('There has been an error reading the header!');
    return;
end

%% Setup
% setupcheck = fscanf(cine,'%c',2); %%%%%%
% setup.Length = fread(cine,1,'ushort');
fseek(cine,header.OffSetup,'bof');

setup.Framerate16 = fread(cine,1,'uint16'); 
setup.Shutter16 = fread(cine,1,'uint16');                   
setup.PostTrigger16 = fread(cine,1,'uint16');               
setup.FrameDelay16 = fread(cine,1,'uint16');                
setup.AspectRatio = fread(cine,1,'uint16');
setup.Res7 = fread(cine,1,'uint16');
setup.Res8 = fread(cine,1,'uint16');
setup.Res9 = fread(cine,1,'uint8');
setup.Res10 = fread(cine,1,'uint8');
setup.Res11 = fread(cine,1,'uint8');
setup.TrigFrame = fread(cine,1,'uint8');
setup.Res12 = fread(cine,1,'uint8');
setup.DescriptionOld = fscanf(cine,'%c',121); %%%%%%
setup.Mark = fscanf(cine,'%c',2); %%%%%%;
setup.Length = fread(cine,1,'uint16');
setup.Res13 = fread(cine,1,'uint16');
setup.SigOption = fread(cine,1,'uint16');
setup.BinChannels = fread(cine,1,'int16');
setup.SamplesPerImage = fread(cine,1,'uint8');
setup.BinName = fscanf(cine,'%c',88); %%%%%%
setup.AnaOptions = fread(cine,1,'uint16');
setup.AnaChannels = fread(cine,1,'int16');
setup.Res6 = fread(cine,1,'uint8');
setup.AnaBoard = fread(cine,1,'uint8');
setup.ChOption = fread(cine,8,'int16');
setup.AnaGain = fread(cine,8,'float');
setup.AnaUnit = fscanf(cine,'%c',48); %%%%%%
setup.AnaName = fscanf(cine,'%c',88); %%%%%%
setup.lFirstImage = fread(cine,1,'int32');
setup.dwImageCount = fread(cine,1,'uint32');
setup.nQFactor = fread(cine,1,'int16');
setup.wCineFileType = fread(cine,1,'uint16');
setup.szCinePath = fscanf(cine,'%c',260); %%%%%%
setup.Res14 = fread(cine,1,'uint16');
setup.Res15 = fread(cine,1,'uint8');
setup.Res16 = fread(cine,1,'uint8');
setup.Res17 = fread(cine,1,'uint16');
setup.Res18 = fread(cine,1,'double');
setup.Res19 = fread(cine,1,'double');
setup.Res20 = fread(cine,1,'uint16');
setup.Res1 = fread(cine,1,'int32');
setup.Res2 = fread(cine,1,'int32');
setup.Res3 = fread(cine,1,'int32');
setup.ImWidth = fread(cine,1,'uint16');
setup.ImHeight = fread(cine,1,'uint16');
setup.EDRShutter16 = fread(cine,1,'uint16');
setup.Serial = fread(cine,1,'uint32');
setup.Saturation = fread(cine,1,'int32');
setup.Res5 = fread(cine,1,'uint8');
setup.AutoExposure = fread(cine,1,'uint32');
setup.bFlipH = fread(cine,1,'uint32');
setup.bFlipV = fread(cine,1,'uint32');
setup.Grid = fread(cine,1,'uint32');
setup.FrameRate = fread(cine,1,'uint32');
setup.Shutter = fread(cine,1,'uint32');
setup.EDRShutter = fread(cine,1,'uint32');
setup.PostTrigger = fread(cine,1,'uint32');
setup.FrameDelay = fread(cine,1,'uint32');
setup.bEnableColor = fread(cine,1,'uint32');
setup.CameraVersion = fread(cine,1,'uint32');
setup.FirmwareVersion = fread(cine,1,'uint32');
setup.SoftwareVersion = fread(cine,1,'uint32');
setup.RecordingTimeZone = fread(cine,1,'int32');
setup.CFA = fread(cine,1,'uint32');
setup.Bright = fread(cine,1,'int32');
setup.Contrast = fread(cine,1,'int32');
setup.Gamma = fread(cine,1,'int32');
setup.Res21 = fread(cine,1,'uint32');
setup.AutoExpLevel = fread(cine,1,'uint32');
setup.AutoExpSpeed = fread(cine,1,'uint32');

setup.AutoExpRect.left =  fread(cine,1,'int32'); %%%%
setup.AutoExpRect.top =  fread(cine,1,'int32'); %%%%
setup.AutoExpRect.right =  fread(cine,1,'int32'); %%%%
setup.AutoExpRect.bottom =  fread(cine,1,'int32'); %%%%

setup.WBGain1.R = fread(cine,1,'float'); %%%%
setup.WBGain1.B = fread(cine,1,'float'); %%%%
setup.WBGain2.R = fread(cine,1,'float'); %%%%
setup.WBGain2.B = fread(cine,1,'float'); %%%%
setup.WBGain3.R = fread(cine,1,'float'); %%%%
setup.WBGain3.B = fread(cine,1,'float'); %%%%
setup.WBGain4.R = fread(cine,1,'float'); %%%%
setup.WBGain4.B = fread(cine,1,'float'); %%%%

setup.Rotate = fread(cine,1,'int32');

setup.WBView.R = fread(cine,1,'float'); %%%%
setup.WBView.B = fread(cine,1,'float'); %%%%

setup.RealBPP = fread(cine,1,'uint32');
setup.Conv8Min = fread(cine,1,'uint32');
setup.Conv8Max = fread(cine,1,'uint32');
setup.FilterCode = fread(cine,1,'int32');
setup.FilterParam = fread(cine,1,'int32');

setup.UF.dim = fread(cine,1,'int32'); %%%%
setup.UF.shifts = fread(cine,1,'int32'); %%%%
setup.UF.bias = fread(cine,1,'int32'); %%%%
setup.UF.Coef = fread(cine,25,'int32'); %%%%

setup.BlackCalSVer = fread(cine,1,'uint32');
setup.WhiteCalSVer = fread(cine,1,'uint32');
setup.GrayCalSVer = fread(cine,1,'uint32');
setup.bStampTime = fread(cine,1,'uint32');
setup.SoundDest = fread(cine,1,'uint32');
setup.FRPSteps = fread(cine,1,'uint32');
setup.FRPImgNr = fread(cine,16,'int32');
setup.FRPRate = fread(cine,16,'uint32');
setup.FRPExp = fread(cine,16,'uint32');
setup.MCCnt = fread(cine,1,'int32');
setup.MCPercent = fread(cine,64,'float');
setup.CICalib = fread(cine,1,'uint32');
setup.CalibWidth = fread(cine,1,'uint32');
setup.CalibHeight = fread(cine,1,'uint32');
setup.CalibRate = fread(cine,1,'uint32');
setup.CalibExp = fread(cine,1,'uint32');
setup.EDR = fread(cine,1,'uint32');
setup.CalibTemp = fread(cine,1,'uint32');
setup.HeadSerial = fread(cine,4,'uint32'); 
setup.RangeCode = fread(cine,1,'uint32');
setup.RangeSize = fread(cine,1,'uint32');
setup.Decimation = fread(cine,1,'uint32');
setup.MasterSerial = fread(cine,1,'uint32');
setup.Sensor = fread(cine,1,'uint32');
setup.ShutterNs = fread(cine,1,'uint32');
setup.EDRShutterNs = fread(cine,1,'uint32');
setup.FrameDelayNs = fread(cine,1,'uint32');
setup.ImPosXAcq = fread(cine,1,'uint32');
setup.ImPosYAcq = fread(cine,1,'uint32');
setup.ImWidthAcq = fread(cine,1,'uint32');
setup.ImHeightAcq = fread(cine,1,'uint32');
setup.Description = fscanf(cine,'%c',4096); %%%%%%
setup.RisingEdge = fread(cine,1,'uint32');
setup.FilterTime = fread(cine,1,'uint32');
setup.LongReady = fread(cine,1,'uint32');
setup.ShutterOff = fread(cine,1,'uint32');
setup.Res4 = fread(cine,16,'uint8');
setup.bMetaWB = fread(cine,1,'uint32');
setup.Hue = fread(cine,1,'int32');
setup.BlackLevel = fread(cine,1,'int32');
setup.WhiteLevel = fread(cine,1,'int32');
setup.LensDescription = fscanf(cine,'%c',256); %%%%%%
setup.LensAperture = fread(cine,1,'float');
setup.LensFocusDistance = fread(cine,1,'float');
setup.LensFocalLength = fread(cine,1,'float');
setup.fOffset = fread(cine,1,'float');
setup.fGain = fread(cine,1,'float');
setup.fSaturation = fread(cine,1,'float');
setup.fHue = fread(cine,1,'float');
setup.fGamma = fread(cine,1,'float');
setup.fGammaR = fread(cine,1,'float');
setup.fGAmmaB = fread(cine,1,'float');
setup.fFlare = fread(cine,1,'float');
setup.PedestalR = fread(cine,1,'float');
setup.PedestalG = fread(cine,1,'float');
setup.PedestalB = fread(cine,1,'float');
setup.fChroma = fread(cine,1,'float');
setup.ToneLabel = fscanf(cine,'%c',256); %%%%%%
setup.TonePoints = fread(cine,1,'int32');
setup.fTone = fread(cine,64,'float'); %%%%%%
setup.UserMatrixLabel = fscanf(cine,'%c',256); %%%%%%
setup.EnableMatrices = fread(cine,1,'uint32');
setup.fUserMatrix = fread(cine,9,'float'); %%%%%%
setup.EnableCrop = fread(cine,1,'uint32');

setup.CropRect.left = fread(cine,1,'int32'); %%%%
setup.CropRect.top = fread(cine,1,'int32'); %%%%
setup.CropRect.right = fread(cine,1,'int32'); %%%%
setup.CropRect.bottom = fread(cine,1,'int32'); %%%%

setup.EnableResample = fread(cine,1,'uint32');
setup.ResampleWidth = fread(cine,1,'uint32');
setup.ResampleHeight = fread(cine,1,'uint32');
setup.fGain16_8 = fread(cine,1,'float');
setup.FRPShape = fread(cine,16,'uint32');

% couldnt get time to cooperate
fseek(cine,8,0);

setup.fPbRate = fread(cine,1,'float');
setup.fTcRate = fread(cine,1,'float');
setup.CineName = fscanf(cine,'%c',256); %%%%%%

%% Read Images
fseek(cine,header.OffImageOffsets,'bof');
raw_image_array=zeros([bitmap.biHeight,bitmap.biWidth,header.ImageCount],'uint16');
pointer_array=fread(cine,header.ImageCount,'uint64');
fseek(cine,pointer_array(1),'bof');
annotation_size=fread(cine,1,'uint');
string_size=annotation_size-8;
annotation=fscanf(cine,'%c',string_size);
image_size=fread(cine,1,'uint');

if image_size~=2*bitmap.biWidth*bitmap.biHeight
    disp('Image sizes are not correct, file may be corrupt or using an outdated version of PCC!')
    return;
end

wait=waitbar(0,sprintf('Reading %d images...',header.ImageCount));
for i=1:header.ImageCount
    raw_image_array(:,:,i)=rot90(reshape(fread(cine,image_size/2,'ushort'),[bitmap.biWidth,bitmap.biHeight]));
    fseek(cine,annotation_size,0);
    waitbar(i/header.ImageCount)
end
close(wait)

%% Cropping Video
% crop = input('Would you like to crop the video (y/n)? ','s');
crop='n';

%  Bayer Pattern - need full gbrg square for correct cropping. must be even
%  height and width, starting on an odd number x and y.
%     1 2 3 4 5 6 ...  
%  1| g b g b g b ...
%  2| r g r g r g ...
%  3| g b g b g b ...
%  4| r g r g r g ...
%  5| g b g b g b ...
%  6| r g r g r g ...

if crop=='y'
    
    %  making a normalized light intensity calculation
    for i=1:header.ImageCount
    %  Integrated amount of light hitting the sensor
        light_intensity(i)=sum(sum(sum(raw_image_array(:,:,i))));
    end
    light_intensity=light_intensity/max(light_intensity);
    [~,brightframe]=max(light_intensity);
    
    gain=4096/max(max(raw_image_array(:,:,brightframe)));
    
    [~,rect2]=imcrop(image(double(demosaic(raw_image_array(:,:,brightframe)*gain,'gbrg'))/4096));
    close all
    
    xmin=2*round((rect2(1)+1)/2)-1;
    newwidth=2*round(rect2(3)/2);
    ymin=2*round((rect2(2)+1)/2)-1;
    newheight=2*round(rect2(4)/2);
    
    crop=input(sprintf('Area selected is %d x %d, would you like to change it (y/n)? ',newheight,newwidth),'s');
    if crop=='y'
       newheight=2*round(input('Desired height: ')/2);
       newwidth=2*round(input('Desired width:  ')/2);
    end
    
    rect2=[xmin ymin newwidth newheight];
    
    raw_image_array=raw_image_array(rect2(2):(rect2(2)+rect2(4)-1),rect2(1):(rect2(1)+rect2(3)-1),:);
    
else 
    return;
end

% %% Save Data
% save(char(sprintf('%s.mat',filename(1:end-4)),'raw_image_array','header'));

fclose('all');

end
