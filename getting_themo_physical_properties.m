
clear
clc
close all



%% Initilizing Necessary Data 

bayer_pattern = "gbrg";
pxSize_um_px = 1.7;
start_frame = 30;
final_frame = 108;

load("run000_5L_30_2000fps_490us_dec1_properties.mat", "raw_image_array", "filters");

%% Setting up thermo-physical properties variable 

% filters: This is a variable that the guy who originally made our camera
% processing stuff created. It has a list of information for pyrometry. In
% this case we're interested in filters.summary. 
% filters.summary: A stack that has the same size as our raw_image_array.
% This stack only contains temperatures that are within a set of parameters
% that were used beforehand. 

tpp = thermoPhysicalProperties(raw_image_array, bayer_pattern, pxSize_um_px, filters.summary, start_frame, final_frame);

%% Getting thermo-physical properties 
tic
tpp.getFittedTemperatures();
tpp.getProperties();
toc

%% Plotting to see stuff 

tpp.plotAllDistributions();


%% Showing good points 
% You'll need to edit this to 

