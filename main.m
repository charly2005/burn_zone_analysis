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


%% plot smoothed intensity line

pxSize_um_px = 1.7;
start_frame = 30;
final_frame = 70;
load("run000_5L_30_2000fps_490us_dec1_properties.mat", "filters");

start_pixel = 1;
end_pixel = 1280;

pixels = start_pixel:end_pixel;
pixels = pixels(:);

frame = 25;
img_row = 732;

color_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
% viewable = uint8(double(color_image).*(255/4095).*5);  % 8-bit image;
% imshow(viewable);
% hold on
R = double(color_image(:,:,1));
intensity_line = R(img_row,:,1);
% Smoothing becasue this data is very noisy
smoothed_line = smooth(intensity_line);

figure
plot(pixels, smoothed_line, 'r');
title(['Frame: ', frame, " Row: ", img_row]);
hold on

% plot(pixels, intensity_line, 'b');
% hold on


%% Find bad values

bad_rows = [];
good_rows = [];


for row=1:size(raw_image_array, 1)
    smoothed_intensity_line = smooth(R(row, :, 1));

    % copy over getIndices function bc I can't use tpp as of now
    [~, max_intensity_idx] = max(smoothed_intensity_line);
    [~, slopes, intercepts] = ischange(smoothed_intensity_line(max_intensity_idx:end), 'linear', 'MaxNumChanges',1);

    unique_slopes = unique(slopes, "stable");
    unique_y_ints = unique(intercepts, "stable");

    if length(unique_slopes)~=2 || length(unique_y_ints)~=2
                % Helps check in case there are two peaks, or other weird
                % fitting things going on 
                max_intensity_idx = NaN;
                min_intensity_idx = NaN;
    
    else
        x_left = sum(slopes==unique_slopes(1));
        x_right = x_left+1;
        x_center = (unique_y_ints(2) - unique_y_ints(1))/(unique_slopes(1)-unique_slopes(2));

        if x_left<x_center && x_center<x_right
            min_intensity_idx = x_left+max_intensity_idx;
        else
            max_intensity_idx = NaN;
            min_intensity_idx = NaN;
        end
    end
    % 

    if isnan(max_intensity_idx) || isnan(min_intensity_idx)
        if mod(row, 3) == 0
            bad_rows = [bad_rows; row];
        end
    else
        if mod(row, 9) == 0
            good_rows = [good_rows; row];
        end
    end
end

% display(good_rows(1:50));
% display(bad_rows(1:30));

%% import csv
filename = "flamefrontdata.csv";
data = importdata(filename);
data = data.data;

%% idk
% each row is an instance
% col 1 = frame, col 2 = row, col 3 = x1, col 4 = x2

% image row #2
% display(data(2, 1:4));

% average flame front
average_dist = 0;
for row = 1:333
    x1 = data(row, 3);
    x2 = data(row, 4);
    average_dist = average_dist + (x2 - x1);
end

average_dist = average_dist / 166;
display("Average flame front length in pixels: " + average_dist);

% test = data(1, :);
% display(test(1));

%% pair data w image
clc
ds = cell(463, 1);
for row = 1:463
    x = data(row, :);
    color_image = demosaic(raw_image_array(:,:,x(1)), bayer_pattern);
    R = double(color_image(:,:,1));
    intensity_line = R(x(2),:,1);
    % intensity_line = smooth(intensity_line);
    % change size [1280, 1] back to [1, 1280]
    % intensity_line = reshape(intensity_line, 1, []);
    ds{row} = [x(3:4) , intensity_line];
end


writecell(ds, 'flamefrontds.csv');
%% load keras model
front_net = importNetworkFromTensorFlow("kerasLionfront.pb");
back_net = importNetworkFromTensorFlow("kerasLionback.pb");
%% test model
front = predict(front_net, intensity_line);
back = predict(back_net, intensity_line);
display(front + " " + back); 

front_y = interp1(pixels, smoothed_line, front, 'linear');
back_y = interp1(pixels, smoothed_line, back, 'linear'); 

plot(front, front_y, 'bo');
hold on
plot(back, back_y, 'bo');
hold on
