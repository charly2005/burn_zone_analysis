function [l, s] = calculate_length(frame, raw_image_array, bayer_pattern)
    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    % gain = 5;
    % color_image = uint8(double(demosaiced_image)*(255/4095)*gain);
    
    binary_image = imbinarize(rgb2gray(demosaiced_image), 0.0039);
    % imshow(binary_image);
    % hold on

    % bw to cc then cc to bw
    cc = bwconncomp(binary_image);
    s = regionprops("table",cc, "Area");
    [~,idx] = sort(s.Area,"descend");
    % display(cc);
    % imshow(cc2bw(cc));
    hold on;
    filtered_binary_image = cc2bw(cc, ObjectsToKeep=idx(1));
    imshow(filtered_binary_image);
    hold on

    % there are some black dots in the region
    % such as near the bottom of frame 20
    
    
    % move in a 3 x 3 grid

    l = 1;
    g = cell(3,3);
    max_h = size(raw_image_array, 1);
    max_w = size(raw_image_array, 2);
    row = filtered_binary_image(1,:,1);
    
    % start at top and move down
    curr_x = find(row,1,'last');
    curr_y = 1;
    g(2,2) = [curr_x, curr_y];

    while true
        % build grid
        for i = 1:3
            % 1 = down, 2 = mid, 3 = top
            y_shift = i-2;
            for j = 1:3
                % 1 = left, 2 = mid, 3 = right
                 x_shift = j-2;
                 x = curr_x + x_shift;
                 y = curr_x + y_shift;
                 g(i,j) = [x,y];
                 
            end
        end

        % implement traversing
        

        % break if reach end
        if g{3,2}(1) == 0
            break;
        end

        l = l+1;
    end