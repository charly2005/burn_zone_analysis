%% clear
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

%% a

% inonpolygon to check if a point is in/on a circle
% if there are >=2 pts that are all below center choose the left most
% if there are >= 2 pts that are all above center choose right most
% 
% edgecase choose inpolygon otherwise use onpolygon

%% Test
clc


frame = 29;

% smaller step = larger l
step = 0.5;
scale_factor = 1 / step; 

[l,b] = calculate_length(frame,raw_image_array,bayer_pattern, 64);

%% Calculate fractal dimension

% D = logN/logS

scale_factors = [8, 16,32, 64];
log_scale_factors = log(scale_factors);
log_n = [1,2,4,8];
figure
xlabel("Frames");
ylabel("Fractal Dimension");
hold on
for f = 41:41
    for s = 1:4
        [n,~] = calculate_length(f, raw_image_array, bayer_pattern, scale_factors(s));
        log_n(s) = log(n);
        plot(log_scale_factors(s), log_n(s), 'bo');
        hold on
    end
    %display(f);
    p = polyfit(log_scale_factors, log_n, 1);
    y = polyval(p,log_scale_factors);
    plot(log_scale_factors,y,'r');
    display(1-p(1));
    % plot(f,p(1), 'go');
    % hold on
end