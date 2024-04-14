function [front_x, front_y, back_x, back_y] = calculate_front(frame, img_row, raw_image_array, bayer_pattern)
    % front_x is more to the left than back_x
    
    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    gray = rgb2gray(demosaiced_image);

    %% Estimate where flame front is
    % 0.0039 calculated via Otsu's method from other frames
    binary = imbinarize(gray, 0.0039);
    
    % pixel value
    estimate = zeros(1, 800);
    for row = 1:800
        estimate(row) = find(binary(row, :), 1, 'last');
    end

    %% Smooth out curve
    R = double(demosaiced_image(:,:,1));

    intensity_line = R(img_row,:,1);
    smoothed_line = smooth(intensity_line);
    
    start_pixel = 1;
    end_pixel = 1280;
    
    pixels = start_pixel:end_pixel;
    pixels = pixels(:);
    
    estimate_y = smoothed_line(estimate(img_row));
    
    %% Getting coordinates of flame front
    [~, x] = findpeaks(smoothed_line, pixels);
    
    % find closest 2 peaks to binary estimate
    front_x = x(1);
    back_x_estimate = x(1);
    for pk = 1:size(x)
        if (x(pk) >= estimate(img_row))
            start = pk;
            break;
        end
        diff = x(pk) - estimate(img_row);
        if (diff > front_x - estimate(img_row))
            front_x = x(pk);
        end
    end
    
    for pk = start:size(x)
        diff = x(pk) - estimate(img_row);
        if (diff < abs(back_x_estimate - estimate(img_row)))
           back_x_estimate = x(pk);
        end
    end
    
    front_y = smoothed_line(front_x);

    % find y
    y_dist = estimate_y - smoothed_line(back_x_estimate);
    back_x_lower = round(2 * estimate(img_row) + (y_dist / 3) - (back_x_estimate));
    back_y = (smoothed_line(back_x_estimate) + smoothed_line(back_x_lower)) / 2;
    
    % find x w/ y
    smoothed_line_end = smoothed_line(estimate(img_row):1280);
    [~, back_x] = min(abs(smoothed_line_end - round(back_y)));
    
    back_x = estimate(img_row) + back_x;
    
end