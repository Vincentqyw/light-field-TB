
%% This is a simple test for light field ToolBox.
% You can use your own Lytro or Illum devices to decode the lfp
% or lfr files, and further processing color correction and
% frequency domain correction to improve the quality of your images.
% Enjoy it!
% Anthor: Vincent Qin
% Data: 2017.10

%% Begin to enjoy it.

clc;
clear all;
clc;

addpath(genpath('Sample_test'));
addpath(genpath('LFToolbox0.4'));

LFMatlabPathSetup;

%% Step1: Decompress data.C.0/1/2/3---> to get white image data
fprintf('===============Step1: Unpack Lytro Files===============\n\n ');
LFUtilUnpackLytroArchive('Sample_test')   

%% Step2: Including the files after decompressing

fprintf('===============Step2: Process WhiteImages===============\n\n');
% your series number:
% lytro: Axxxxxxxxxx
% illum: Bxxxxxxxxxx
WhiteImagesPath='Sample_test\Cameras\Axxxxxxxxxx'; 
LFUtilProcessWhiteImages( WhiteImagesPath);     

%% Step3: Decode your.lfp/.lfr files
tic
fprintf('=====================Step3: Decode LFP===================\n\n');
cd('Sample_test');  % go to Sample_test directory

lfpname='test';     % test file name


if WhiteImagesPath(21)=='A'    %if lytro  exist('LYTRO','var')
    version='F01';
elseif WhiteImagesPath(21)=='B'%if illum  exist('ILLUM','var')
    version='B01';
end

InputFname=['Images\',version,'\',lfpname,'.lfp'];   

[LF, LFMetadata,WhiteImage,CorrectedLensletImage, ...
WhiteImageMetadata, LensletGridModel, DecodeOptions]...
                              =  LFLytroDecodeImage(InputFname);
 cd('..');

imshow(CorrectedLensletImage) %Raw Image 
mkdir(['Results_saving\',lfpname]);
imwrite(CorrectedLensletImage,['Results_saving\',lfpname,'\',lfpname,'.bmp']);
save(['Results_saving\',lfpname,'\',lfpname,'.mat'],'CorrectedLensletImage');
toc

%% =======================Frequecy domain Correction================================
%---Setup for linear filters---
tic
% lytro
if strcmp(version,'F01')==1
    LFPaddedSize = [16, 16, 400, 400];
    BW = 0.03;
    FiltOptions = [];
    FiltOptions.Rolloff = 'Butter';
    Slope1 = -3/9; % Lorikeet
    Slope2 = 4/9;  % Building
    fprintf('Building 4D frequency hyperfan... ');
    [H, FiltOptionsOut] = LFBuild4DFreqHyperfan( LFPaddedSize, Slope1, Slope2, BW, FiltOptions );
    fprintf('Applying filter');
    [LFFilt, FiltOptionsOut] = LFFilt4DFFT( LF, H, FiltOptionsOut );

% illum
elseif strcmp(version,'B01')==1

    LFSize = size(LF);
    LFPaddedSize = LFSize;
    BW = 0.04;
    FiltOptions = [];
    %---Demonstrate 4D Hyperfan filter---
    Slope1 = -4/15; % Lorikeet
    Slope2 = 15/15; % Far background
    fprintf('Building 4D frequency hyperfan... ');
    [H, FiltOptionsOut] = LFBuild4DFreqHyperfan( LFPaddedSize, Slope1, Slope2, BW, FiltOptions );
    fprintf('Applying filter');
    [LFFilt, FiltOptionsOut] = LFFilt4DFFT( LF, H, FiltOptionsOut );
    title(sprintf('Frequency hyperfan filter, slopes %.3g, %.3g, BW %.3g', Slope1, Slope2, BW));
    drawnow
    save(['Results_saving\',lfpname,'\',lfpname,'5D.mat'],'LFFilt');
end


%% ====================Color correction using Gamma correction=====================                                  

ColMatrix = DecodeOptions.ColourMatrix;
Gamma=DecodeOptions.Gamma;
ColBalance=DecodeOptions.ColourBalance;

% processing gamma correction to get one image NOT 5D LF
ColorCorrectedImage=LFColourCorrect(CorrectedLensletImage, ColMatrix, ColBalance, Gamma);
imwrite(ColorCorrectedImage,['Results_saving\',lfpname,'\',lfpname,'ColorCorrectedImage.bmp']);
save(['Results_saving\',lfpname,'\',lfpname,'ColorCorrectedImage.mat'],'ColorCorrectedImage')
imshow(ColorCorrectedImage);title('Corrected Lenslet Image');



%% Color correction to get 5-D LFColorCorrectedImage data
LFColorCorrectedImage=zeros(size(LF,1),size(LF,2),size(LF,3),size(LF,4),size(LF,5));
for i=1:size(LF,1)
    for j=1:size(LF,2)    
        temp =squeeze(LFFilt(i,j,:,:,1:3));
        temp = LFColourCorrect(temp, ColMatrix, ColBalance, Gamma);
        LFColorCorrectedImage(i,j,:,:,1:3)=temp;    
        imshow(temp);
        pause(0.1)
    end
end
LFColorCorrectedImage(:,:,:,:,4)=LF(:,:,:,:,4);
save(['Results_saving\',lfpname,'\',lfpname,'RawLFColorCorrectedImage.mat'],'LFColorCorrectedImage');% very important

%% show your light field image.
ViewLightField(LFColorCorrectedImage(:,:,:,:,1:3));

toc
%--------------------------------------------------------------------------------------------------------------------
