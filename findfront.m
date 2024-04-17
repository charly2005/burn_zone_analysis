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

%% Calculate flame front data for specific frame/row
% start frame 20, end frame 60
frame = 60;
img_row = 100;

[x1, y1, x2, y2] = calculate_front(frame, img_row, raw_image_array, bayer_pattern);

demosaiced_image = demosaic(raw_image_array(:,:,frame), "gbrg");

R = double(demosaiced_image(:,:,1));

intensity_line = R(img_row,:,1);
smoothed_line = smooth(intensity_line);

start_pixel = 1;
end_pixel = 1280;

pixels = start_pixel:end_pixel;
pixels = pixels(:);

figure
plot(pixels, smoothed_line, 'r');
plot_title = "Frame: " + frame + "   Row: " + img_row;
title(plot_title);
hold on

plot(x1, y1,'bo');
plot(x2, y2, 'bo');


%% find highest value possible
ymax = 0;
for f = 1:84
    for row = 1:800
    demosaiced_image = demosaic(raw_image_array(:,:,f), "gbrg");
    R = double(demosaiced_image(:,:,1));
    intensity_line = R(img_row,:,1);
        if (max(intensity_line) > ymax)
            ymax = max(intensity_line);
        end
    end
    disp(f);
end

%% Create gif for row

start_pixel = 1;
end_pixel = 1280;

pixels = start_pixel:end_pixel;
pixels = pixels(:);

 
for f = 20:60
    [x1, y1, x2, y2] = calculate_front(f, img_row, raw_image_array, bayer_pattern);
    demosaiced_image = demosaic(raw_image_array(:,:,f), "gbrg");

    R = double(demosaiced_image(:,:,1));
    
    intensity_line = R(img_row,:,1);
    smoothed_line = smooth(intensity_line);
    figure('Visible', 'off');
    plot(pixels, smoothed_line, 'r');
    ylim([0,3000]);
    plot_title = "Frame: " + f + "   Row: " + img_row; 
    title(plot_title);
    hold on
    plot(x1, y1,'bo');
    plot(x2, y2, 'bo');
    
    exportgraphics(gcf, '100.gif', 'Append', true);

end

