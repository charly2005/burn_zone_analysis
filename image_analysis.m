%% Binarizing images with MATLAB 
%  This script should give you a good introduction into binarizing images
%  from our cameras (Phantom) and then pulling out some interesting
%  information from these videos. 
%  Feel free to experiment more with this beyond what I've given you as
%  well. 


clear        % Clears the workspace 
clc          % Clears the console window 
close all    % Closes all figures 

%% Import data from video file 
%  Our video files are in a *.cine file format which is a binary encoded
%  file type. We already have a way to extract all the information out of
%  it, but please take a look at it. 

addpath("External Functions\")
addpath("Test Data\")

filename = "Test Data\run000_5L_30_2000fps_490us_dec1_trimmed.cine";

% The most important variable that is returned here is the raw_image_array.
% This is the "raw" image from the camera. For now, I'll add a way for you
% to convert it to a conventional three color image. The other variables
% are metadata about the video file. These are structure files, kind of
% like dictionaries from Python. Properties can be acessed with typical
% object oriented programming. 

[header, bitmap, setup, raw_image_array] = automated_MatCine(filename);

% Video Size Parameters 
im_height = size(raw_image_array, 1);
im_width = size(raw_image_array, 2);
num_images = size(raw_image_array, 3);

% Time in seconds [s] t = (# of frames)/(Frames/Second) 
time_s = (0:1:num_images-1)./(setup.FrameRate);




%% Getting Single frame 

frame = 45;


demosaiced_image = demosaic(raw_image_array(:,:,frame), "gbrg");       % 12-bit image
% R = double(demosaiced_image(:,:,1));

% Y = 1:im_width;
% X = 1:im_height;

% [xx,yy]=meshgrid(Y,X);

% figure 
% hold on 
% mesh(xx, yy, R)

% analyze image row by row

row_number = 20;
start_pixel = 599;
end_pixel = 1000;
row = double(raw_image_array(row_number, :, frame));
row = row(start_pixel:end_pixel);
% 1-1280 
pixels = start_pixel:end_pixel;


odd_pixels = find(mod(pixels, 2) == 1);
even_pixels = find(mod(pixels,2) == 0);
row = row(even_pixels);

pixel_type = even_pixels;

row_fit = polyfit(pixel_type, row, 25);
row_fit = polyval(row_fit, pixel_type);

figure
plot(pixel_type + start_pixel, row, 'o');
hold on
plot(pixel_type + start_pixel, row_fit, 'r');
xlabel('Pixel');
ylabel('Pixel Val');
title('Value Curve');

