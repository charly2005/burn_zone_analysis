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

% bayer pattern
bayer_pattern = "gbrg";


%% find flame front for specific frame

frame = 50;
img_row = 545;

color_image = demosaic(raw_image_array(:,:,frame), "gbrg");
% color_image = uint8(double(demosaiced_image).*(255/4095).*5); 
gray = rgb2gray(color_image);
binary = imbinarize(gray, 'global');

imshow(gray);
% hold on
%imshow(color_image);
hold on

% pixel value
back = zeros(1, 800);

for row = 1:800
    back(row) = find(binary(row, :), 1, 'last');
end

R = double(color_image(:,:,1));
intensity_line = R(img_row,:,1);
smoothed_line = smooth(intensity_line);

start_pixel = 1;
end_pixel = 1280;

pixels = start_pixel:end_pixel;
pixels = pixels(:);

figure
plot(pixels, smoothed_line, 'r');
title(['Frame: ', frame, " Row: ", img_row]);
hold on

back_y = smoothed_line(back(img_row));

plot(back(img_row), back_y, 'bo');

[peaks, x] = findpeaks(smoothed_line, pixels);

% find closest 2 peaks (based off x value) to back(img_row)
edge_front = x(1);
edge_back_estimate = x(1);
for pk = 1:size(x)
    if (x(pk) >= back(img_row))
        start = pk;
        break;
    end
    diff = x(pk) - back(img_row);
    if (diff > edge_front - back(img_row))
        edge_front = x(pk);
    end
end

for pk = start:size(x)
    diff = x(pk) - back(img_row);
    if (diff < abs(edge_back_estimate - back(img_row)))
       edge_back_estimate = x(pk);
    end
end
plot(edge_front, smoothed_line(edge_front), 'go');

% for edge_back
y_dist = back_y - smoothed_line(edge_back_estimate);
% create a square and draw a diagonal through the middle to estimate
% inflection point
edge_back_lower = round(back(img_row) + y_dist);
edge_back_y = (smoothed_line(edge_back_estimate) + smoothed_line(edge_back_lower)) / 2;

% find edge_back with edge_back_y
possible = [];
last_idx = 0;
% fix me
for px = back:1280
    if (abs(smoothed_line(px) - edge_back_y) <= 1)
        possible = [possible, px]
    end
end

%find closest to edge_back_estimate
edge_back = 1280;
for px = 1:size(possible)
    dist = abs(edge_back_estimate - possible(px));
    if (edge_back < dist)
        edge_back = dist;
    end
end


plot(edge_back_estimate, smoothed_line(edge_back_estimate), 'go');
plot(edge_back_lower, smoothed_line(edge_back_lower), 'go');
plot(edge_back, edge_back_y, 'go');
