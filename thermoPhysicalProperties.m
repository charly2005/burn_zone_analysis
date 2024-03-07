classdef thermoPhysicalProperties < matlab.mixin.SetGet

    % thermoPhysicalProperties: Used to measure thermo-physical-properties
    % of thin films at high magnification.
    %   Detailed explanation goes here

    properties (Access = public)
        % Inputs
        raw_image_array {uint16};
        bayer_pattern (1,4) {string};
        pxSize (1,1) {mustBeNumeric, mustBeNonnegative};
        filtered_temperatures;
        start_frame (1,1) {mustBeInteger, mustBeNonnegative};
        final_frame (1,1) {mustBeInteger, mustBeNonnegative};


        % Outputs
        fitted_temperatures {cell};

        % T^4/I
        fitting_constants;
        average_fitting_constant (1,1) {mustBeNumeric};
        std_dev_fitting_constant (1,1) {mustBeNumeric};

        % Thickness
        flame_thickensses;
        average_flame_thickness (1,1) {mustBeNumeric};
        std_dev_flame_thickness (1,1) {mustBeNumeric};

        % dT/dx
        temperature_gradiants;
        average_temperature_gradiant (1,1) {mustBeNumeric};
        std_dev_temperature_gradiant (1,1) {mustBeNumeric};

        % Diffusivity Constant
        diffusivity_contstants;
        average_diffusivity_contstant (1,1) {mustBeNumeric};
        std_dev_diffusivity_contstant (1,1) {mustBeNumeric};

    end

    properties (Access = public)
        intensities_for_fitting;
        temperatures_for_fitting;
    end

    

    methods (Access = public)

        function [max_intensity_idx, min_intensity_idx] = getIndicies(obj, smoothed_intensity_line)

            % The brightest point is the left hand index
            [~, max_intensity_idx] = max(smoothed_intensity_line);


            % ischange is used to detect the four legs of this curve. The
            % first point of the final leg is chosen to be the right handed
            % point of the curve. Helps with automation.

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

        end

        function fillFittingCells(obj)

            disp('Getting Fitting Data')

            % Protected Variables
            intensities = cell([1, ((obj.final_frame - obj.start_frame)+1)*size(obj.raw_image_array, 1)]);
            temperatures = cell([1, ((obj.final_frame - obj.start_frame)+1)*size(obj.raw_image_array, 1)]);

            pos = 1;

            bad_positions = [];

            for frame=obj.start_frame:obj.final_frame


                color_image = demosaic(obj.raw_image_array(:,:,frame), obj.bayer_pattern);
                R = double(color_image(:,:,1));

                for row=1:size(obj.raw_image_array, 1)

                    intensity_line = R(row,:,1);
                    % Smoothing becasue this data is very noisy
                    smoothed_intensity_line = smooth(intensity_line);


                    [max_intensity_idx, min_intensity_idx] = getIndicies(obj, smoothed_intensity_line);

                    if isnan(max_intensity_idx) || isnan(min_intensity_idx)
                        intensities{pos} = [];
                        temperatures{pos} = [];
                        bad_positions = [bad_positions; pos];
                    else
                        intensities{pos} = reshape(smoothed_intensity_line(max_intensity_idx:min_intensity_idx), [], 1);
                        temperatures{pos} = reshape(obj.filtered_temperatures(row, max_intensity_idx:min_intensity_idx, frame), [], 1);
                    end
                    pos = pos + 1;

                end

            end

            intensities(bad_positions) = [];
            temperatures(bad_positions) = [];

            set(obj, 'intensities_for_fitting', intensities')
            set(obj, 'temperatures_for_fitting', temperatures')
        end
    end

    methods (Hidden)

        % Trimming the line 
        function trimmed_temperature_line = trimTemperatureLine(obj, temperature_line, options)
            
            arguments
                obj;
                temperature_line (:,1) {mustBeNumeric};
                options.trimming_line (1,1) = 0.8;
            end

            cushion = round( ((1 - options.trimming_line)/2)*length(temperature_line) );
            trimmed_temperature_line = temperature_line(cushion:end-cushion);

        end


        % Flame Thickness
        function getFlameThickness(obj)

            disp('Getting Flame Thickness')

            set(obj, 'flame_thickensses', cellfun('length', obj.fitted_temperatures));
            set(obj, 'average_flame_thickness', mean(obj.flame_thickensses));
            set(obj, 'std_dev_flame_thickness', std(obj.flame_thickensses));

        end


        % dT/dx
        function getTemperatureGradient(obj)

            disp('Getting Temperature Gradient')

            temp_temperature_gradiants = nan([1, length(obj.fitted_temperatures)]);

            for i=1:length(temp_temperature_gradiants)

                % Getting the temperature line 
                temperature_line = obj.fitted_temperatures{i};
                trimmed_temperature_line = obj.trimTemperatureLine(temperature_line);

                distances = (1:length(trimmed_temperature_line)).*obj.pxSize;

                pFit = polyfit(distances, trimmed_temperature_line, 1);

                temp_temperature_gradiants(i) = abs(pFit(1));

            end

            set(obj, 'temperature_gradiants', temp_temperature_gradiants)
            set(obj, 'average_temperature_gradiant', mean(obj.temperature_gradiants));
            set(obj, 'std_dev_temperature_gradiant', std(obj.temperature_gradiants));

        end

        % For Thermal Diffusivity (a = v/b)
        function getDiffusivityConstant(obj)

            disp('Getting Diffusivity Constant')

            constants = nan([1, length(obj.fitted_temperatures)]);

            for i=1:length(constants)

                % Getting the temperature line 
                temperature_line = obj.fitted_temperatures{i};
                trimmed_temperature_line = obj.trimTemperatureLine(temperature_line);

                distances = (1:length(trimmed_temperature_line)).*obj.pxSize;

                pFit = polyfit(distances, log(trimmed_temperature_line), 1);
                % pFit = polyfit(distances, trimmed_temperature_line, 2);

                constants(i) = abs(pFit(1));

            end


            set(obj, 'diffusivity_contstants',  abs(constants));
            set(obj, 'average_diffusivity_contstant', mean(obj.diffusivity_contstants));
            set(obj, 'std_dev_diffusivity_contstant', std(obj.diffusivity_contstants));

        end


    end

    methods (Access = public)

        % Constructor
        function obj = thermoPhysicalProperties(raw_image_array, bayer_pattern, pxSize, filtered_temperatures, start_frame, final_frame)

            % Input Variables
            % raw_image_array: (uint16)
            %   Bayer pattern image from the camera. Raw data
            % bayer_pattern: (string)
            %   Bayer pattern associated with the camera. See demosaic for
            %   more information and appropriate inputs.
            % pxSize: (1,1)
            %   The distance to pixel ratio of the camera. Be sure to know
            %   the units for plotting.

            % Protected Variabels


            if nargin==6
                % Public Variables
                obj.raw_image_array = raw_image_array;
                obj.bayer_pattern = bayer_pattern;
                obj.pxSize = pxSize;
                obj.filtered_temperatures = filtered_temperatures;
                obj.start_frame = start_frame;
                obj.final_frame = final_frame;
            end
        end


        % Fits temperature to get points along curve for other properties
        function getTemperatureIntensityRatio(obj)

            temperatures = cell2mat(obj.temperatures_for_fitting);
            intensities = cell2mat(obj.intensities_for_fitting);
            
            % , temperatures>1750
            bad_points = any([isnan(temperatures), temperatures==0, temperatures>1940], 2);

            temperatures(bad_points) = [];
            intensities(bad_points) = [];

            constants = (temperatures.^4)./intensities;

            % Setting 
            set(obj, 'fitting_constants', constants);
            set(obj, 'average_fitting_constant', mean(obj.fitting_constants));
            set(obj, 'std_dev_fitting_constant', std(obj.fitting_constants));

            % Figure for Visualization 

            temps_for_plotting = (min(temperatures):5:max(temperatures));
            ints_for_plotting = (temps_for_plotting.^4)./obj.average_fitting_constant;

            dec = 1;
            figure
            hold on 
            scatter(temperatures(1:dec:end).^4, intensities(1:dec:end), 'k.', 'DisplayName', 'Fitting Data')
            plot(temps_for_plotting.^4, ints_for_plotting, 'r--', 'DisplayName', 'Fitted Lines')
            legend()
            ylabel('Intensity [a.u.]')
            xlabel('Temperature^4 [K^4]')
            title('\epsilon~Const.')
            set(gca, 'FontSmoothing', 15)

        end

        % Fits intensity and temperature assuming emmisivity goes as T^n 
        function getFittingConstant_differentWay(obj)

            temperatures = cell2mat(obj.temperatures_for_fitting);
            intensities = cell2mat(obj.intensities_for_fitting);

            
            % , temperatures>1750
            bad_points = any([isnan(temperatures), temperatures==0, temperatures>1940], 2);

            temperatures(bad_points) = [];
            intensities(bad_points) = [];

            pFit = polyfit(log(temperatures), log(intensities), 1);

            % Make better names 
            % n = pFit(1) - 4;
            A = exp(pFit(end));

            plotting_temperatures = (min(temperatures):10:max(temperatures));
            plotting_intensities = A.*(plotting_temperatures.^pFit(1));

            dec = 1;
            figure
            hold on 
            scatter(temperatures(1:dec:end).^4, intensities(1:dec:end), 'k.', 'DisplayName', 'Fitting Data')
            plot(plotting_temperatures.^4, plotting_intensities, 'r--', 'DisplayName', 'Fitted Lines')
            legend()
            ylabel('Intensity [a.u.]')
            xlabel('Temperature^4 [K^4]')

        end

        % Getting Fitted Temperatuers from Temperature and intensity relationship
        function obj = getFittedTemperatures(obj)

            obj.fillFittingCells();

            obj.getTemperatureIntensityRatio();
            
            temperatures = cellfun(@(x) (x.*obj.average_fitting_constant).^(0.25), obj.intensities_for_fitting, 'UniformOutput',false);
            set(obj, 'fitted_temperatures', temperatures);
        end

        % Getting Fitted Temperatures 
        

        % Getting properties
        function getProperties(obj)

            obj.getFlameThickness();
            obj.getTemperatureGradient();
            obj.getDiffusivityConstant();

        end

        % For Plotting Afterwards
        function plotSingleDistribution(obj, distribution, distribution_name, x_label)

            figure
            hold on

            histogram(distribution)
            % histfit(distribution, 100, 'normal')
            title(distribution_name)
            
            ylabel('Counts [a.u.]')
            xlabel(x_label)

            set(gca, 'FontSize', 15)

        end

        function plotAllDistributions(obj)

            obj.plotSingleDistribution(obj.fitting_constants, 'Fitting Constants', 'Temperature^4/Intensity')
            obj.plotSingleDistribution(obj.flame_thickensses, 'Flame Thickness', 'Thickness [\mum]')
            obj.plotSingleDistribution(obj.temperature_gradiants, 'Temperature Gradiant', '\DeltaT/\Deltax [K/\mum]')
            obj.plotSingleDistribution(obj.diffusivity_contstants, 'Diffusivity Constant', '[1/\mum]')

        end

        function averages = getAverages(obj)

            averages.fitting_constant = obj.average_fitting_constant;
    
            % Thickness
            averages.flame_thickness = obj.average_flame_thickness;
    
            % dT/dx
            averages.temperature_gradiant = obj.average_temperature_gradiant;
    
            % Diffusivity Constant
            averages.diffusivity_contstant = obj.average_diffusivity_contstant;


        end


    end


    % Setting Functions
    methods
        function set.intensities_for_fitting(obj, val)
            if isa(val, 'cell')
                obj.intensities_for_fitting = val;
            else
                error('intensities are not cell')
            end
        end

        function set.temperatures_for_fitting(obj, val)
            if isa(val, 'cell')
                obj.temperatures_for_fitting = val;
            else
                error('temperatures are not cell')
            end
        end

        function set.fitted_temperatures(obj, val)
            if isa(val, 'cell')
                obj.fitted_temperatures = val;
            else
                error('fitted temperatures are not cell')
            end
        end

        % Flame Thickness 
        function set.flame_thickensses(obj, val)
            if isa(val, 'double')
                obj.flame_thickensses = val;
            else
                error('flame thickensss not a double')
            end
        end
        
        function set.average_flame_thickness(obj, val)
            if isa(val, 'double') || length(val) > 1
                obj.average_flame_thickness = val;
            else
                error('avg flame thickensss not a double')
            end
        end
        
        function set.std_dev_flame_thickness(obj, val)
            if isa(val, 'double') || length(val) > 1
                obj.std_dev_flame_thickness = val;
            else
                error('std flame thickensss not a double')
            end
        end

        % Temperature Gradiant 
        function set.temperature_gradiants(obj, val)
            if isa(val, 'double')
                obj.temperature_gradiants = val;
            else
                error('temperature gradiant not a double')
            end
        end
        
        function set.average_temperature_gradiant(obj, val)
            if isa(val, 'double') || length(val) > 1
                obj.average_temperature_gradiant = val;
            else
                error('avg temperature gradiant not a double')
            end
        end
        
        function set.std_dev_temperature_gradiant(obj, val)
            if isa(val, 'double') || length(val) > 1
                obj.std_dev_temperature_gradiant = val;
            else
                error('std temperature gradiant not a double')
            end
        end

        % Diffusivity Constant 
        function set.diffusivity_contstants(obj, val)
            if isa(val, 'double')
                obj.diffusivity_contstants = val;
            else
                error('diffusivity contstant not a double')
            end
        end
        
        function set.average_diffusivity_contstant(obj, val)
            if isa(val, 'double') || length(val) > 1
                obj.average_diffusivity_contstant = val;
            else
                error('avg diffusivity contstant not a double')
            end
        end
        
        function set.std_dev_diffusivity_contstant(obj, val)
            if isa(val, 'double') || length(val) > 1
                obj.std_dev_diffusivity_contstant = val;
            else
                error('std diffusivity contstant not a double')
            end
        end

    end
end
