function [l, s, filtered_binary_image, g] = calculate_length(frame, raw_image_array, bayer_pattern, scale_factor)

    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    binary_image = imbinarize(rgb2gray(demosaiced_image), 0.0039);
    binary_image = imresize(binary_image, scale_factor);

    % bw to cc then cc to bw
    cc = bwconncomp(binary_image);
    s = regionprops("table",cc, "Area");
    [~,idx] = sort(s.Area,"descend");
    filtered_binary_image = cc2bw(cc, ObjectsToKeep=idx(1));
    imshow(filtered_binary_image);
    hold on

    % there are some black dots in the region
    % such as near the bottom of frame 20
    
    
    % move in a 3 x 3 grid

    l = 1;
    g = cell(3,3);
    max_h = size(filtered_binary_image, 1);
    max_w = size(filtered_binary_image, 2);
    row = filtered_binary_image(1,:,1);
    
    % start at top and move down
    curr_x = find(row,1,'last');
    curr_y = 1;
    g{2,2} = [curr_x, curr_y];

    not_done = true;

    while not_done
        % build grid
        for i = 1:3
            % 1 = down, 2 = mid, 3 = top
            y_shift = i-2;
            for j = 1:3
                % 1 = left, 2 = mid, 3 = right
                 x_shift = j-2;
                 x = curr_x + x_shift;
                 y = curr_y + y_shift;
                 g{i,j} = [x,y];
                 if x >= max_w || y>= max_h
                     not_done = false;
                 end
                 % disp(g{i,j});
            end
        end
        % implement traversing
        curr_y = curr_y + 1;
        curr_x = curr_x + 1;
        
        l = l+1;
    end

    l = l * 1.7 / scale_factor;