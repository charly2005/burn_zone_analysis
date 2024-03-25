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


%% plot smoothed intensity line

bayer_pattern = "gbrg";
pxSize_um_px = 1.7;
start_frame = 30;
final_frame = 70;
load("run000_5L_30_2000fps_490us_dec1_properties.mat", "filters");

start_pixel = 1;
end_pixel = 1280;

pixels = start_pixel:end_pixel;
pixels = pixels(:);

frame = 50;
img_row = 38;

color_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
R = double(color_image(:,:,1));
intensity_line = R(img_row,:,1);
% Smoothing becasue this data is very noisy
smoothed_line = smooth(intensity_line);

figure
plot(pixels, smoothed_line, 'r');
title(['Frame: ', frame, " Row: ", img_row]);
hold on


%% Find bad values

bad_rows = [];
good_rows = []

% replace 2 with raw_image_array
for row=1:size(2, 1)
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
   
        bad_rows = [bad_rows; row];
    else
        good_rows = [good_rows; row];
    end
end

% display(good_rows(1:119));

%% import csv
filename = "flamefrontdata.csv";
ds = importdata(filename);

%% idk
% each row is an instance
% col 1 = frame, col 2 = row, col 3 = x1, col 4 = x2

% image row #2
% display(data(2, 1:4));

% average flame front
average_dist = 0;
for row = 1:166
    x1 = data(row, 3);
    x2 = data(row, 4);
    average_dist = average_dist + (x2 - x1);
end

average_dist = average_dist / 166;
% display("Average flame front length in pixels: " + average_dist);

% test = data(1, :);
% display(test(1));

%% pair data w image
clc
ds = cell(166, 1);
for row = 1:166
    x = data(row, :);
    color_image = demosaic(raw_image_array(:,:,x(1)), bayer_pattern);
    R = double(color_image(:,:,1));
    intensity_line = R(x(2),:,1);
    ds{row} = {x , intensity_line};
end

display(ds{1}{1});


%% split data
% 80 20 split
x_len = int8(0.8 * 166);
y_len = 166 - x_len;

x_train = cell(x_len, 1);
x_val = cell(x_len, 1);
y_train = cell(y_len, 1);
y_val = cell(y_len, 1);

% first shuffle ds
shuffled_indices = randperm(166);
ds = ds(shuffled_indices, :);

for row = 1:x_len
    x_train{row} = ds{row}{2};
    x_val{row} = ds{row}{1};
end

for row = 1:y_len
    y_train{row} = ds{row}{2};
    y_val{row} = ds{row}{1};
end

%% model

layers = [...
    sequentialInputLayer([1,1280])]