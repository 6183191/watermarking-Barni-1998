% Created by Kwon Myung Joon (kwon19@kaist.ac.kr)
% May 4th, 2019
% Matlab 2019a, Windows 10
% reference : A DCT-domain system for robust image watermarking
% M Barni, F Bartolini, V Cappellini, A Piva - Signal processing, 1998 - Elsevier

%% 0. Parameters
imageIndex = 1; % Image index to be used. (default=1)
R = 9; % Block size used in visual masking is RxR. Must be odd integer. (default=9)
alphaBar = 0.2;
M=16000; % The number of random numbers in one watermark.
L=16000; % The number of skipped coefficients.
numOfX=1000; % The number of watermarks to be generated.
watermarks=[400]; % Array of watermark numbers. Element must not exceed numOfX.

%% 1. Read image
files = dir('input');
fileName = {files.name};
fileName = char(fileName(2+imageIndex));
image=im2double(imread(strcat('input/',fileName)));
try
    image = rgb2gray(image);
catch
end
%figure; imshow(image)
imwrite(image,strcat('output/',string(imageIndex),'_1_original_',fileName));

%% 2. Determine beta and alpha
r=(R-1)/2;
padImage = padarray(image,[r,r],'replicate','both');
beta=zeros(size(image));
for i=1:size(beta,1)
    for j=1:size(beta,2)
        beta(i,j)=var(padImage(i:2*r+i,j:2*r+j),0,'all');
    end
end
max_beta=max(beta,[],'all');
beta=beta./max_beta;
mean_beta=mean(beta,'all');
alpha = alphaBar / mean_beta;

%% 3. Generate watermark
Xarr = randn(numOfX, M);

%% 4. Cast watermark
imageDCT = dct2(image); %DCT the image
zz = zigzag(imageDCT); %make it linear using zigzag.m
for i=1:size(watermarks,2)
    X=Xarr(watermarks(i),:);
    t=zz(1+L:L+M); %select coefficients to embed watermark
    tPrime=t+alpha.*abs(t).*X;
    zz(1+L:L+M)=tPrime;
end
watermarkedImageDCT=inv_zigzag(zz,size(image,1),size(image,2));
watermarkedImage=idct2(watermarkedImageDCT); %inverse DCT
watermarkedVisualMaskedImage=image.*(1-beta)+beta.*watermarkedImage;
figure; imshow(watermarkedVisualMaskedImage);
imwrite(watermarkedVisualMaskedImage,strcat('output/',string(imageIndex),'_2_watermarked_',fileName));

%% 5. Detect watermark
dctWatermarkedImage = dct2(watermarkedVisualMaskedImage); %DCT the image
zz = zigzag(dctWatermarkedImage);
tStar=zz(1+L:L+M);
zArr=zeros([1,numOfX]);
for i=1:numOfX
    Y=Xarr(i,:);
    zArr(i)=dot(Y,tStar)/M;
end
Tz=alphaBar/(3*M)*sum(abs(tStar),'all');
figure; plot(1:numOfX,zArr);
%set(gca, 'YScale', 'log') 
% if you want to plot in log scale, uncomment this line
titleString='Normal watermark';
title(sprintf('%s (\\alpha=%.2f, M=%dk, L=%dk)',titleString,alpha,M/1000,L/1000));
hline = refline([0 Tz]); hline.Color = [0.6,0.6,0.6];
legend('response','threshold Tz'); xlabel('Watermarks'); ylabel('Detector Response');






