function [l, g, filtered_binary_image] = calculate_length(frame, raw_image_array, bayer_pattern, scale_factor)

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
    plot(1,1,'ro', 'MarkerSize',5);
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

    done = false;


    % example grid
    %       1           2         3
    % 1 [654,798]	[655,798] [656,798]
    % 2 [654,799]	[655,799] [656,799]
    % 3 [654,800]	[655,800] [656,800]

    disp(max_h);
    disp(max_w);
    revert_pos = [curr_x, curr_y];
    last_pos = [curr_x, curr_y];

    while done == false
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
                 if x >= max_w || y>= max_h || x < 1
                     done = true;
                 end
            end
        end

        if done == true
            break;
        end
        disp(last_pos);
        % dispf([g{1,3}(1),g{1,3}(2)]);
        disp(g)
        last_x = curr_x;
        last_y = curr_y;
        % go clockwise starting right
        % if you go to {3,1} you may have to use revert_pos to avoid double
        % counting
        % TO IMPLEMENT LATER IF NEEDED: if you are are at revert_pos then start at top
        if g{1,3}(2) ~= 0
            if filtered_binary_image(g{1,3}(2),g{1,3}(1)) == 1 && not(g{1,3}(2) == last_pos(2) && g{1,3}(1) == last_pos(1))
                curr_y = curr_y - 1;
                curr_x = curr_x + 1;
                revert_pos = [curr_x, curr_y];
            elseif filtered_binary_image(g{2,3}(2),g{2,3}(1)) == 1 && not(g{2,3}(2) == last_pos(2) && g{2,3}(1) == last_pos(1))
                curr_x = curr_x + 1;
            elseif filtered_binary_image(g{3,3}(2),g{3,3}(1)) == 1 && not(g{3,3}(2) == last_pos(2) && g{3,3}(1) == last_pos(1))
                curr_x = curr_x + 1;
                curr_y = curr_y + 1;
            elseif filtered_binary_image(g{3,2}(2),g{3,2}(1)) == 1 && not(g{3,2}(2) == last_pos(2) && g{3,2}(1) == last_pos(1))
                curr_y = curr_y + 1;
            elseif filtered_binary_image(g{3,1}(2),g{3,1}(1)) == 1 && not(g{3,1}(2) == last_pos(2) && g{3,1}(1) == last_pos(1))
                curr_x = curr_x - 1;
                curr_y = curr_y + 1;
            elseif filtered_binary_image(g{2,1}(2),g{2,1}(1)) == 1 && not(g{2,1}(2) == last_pos(2) && g{2,1}(1) == last_pos(1))
                curr_x = curr_x - 1;
            elseif filtered_binary_image(g{1,1}(2),g{1,1}(1)) == 1 && not(g{1,1}(2) == last_pos(2) && g{1,1}(1) == last_pos(1))
                curr_y = curr_y - 1;
                curr_x = curr_x - 1;
            elseif filtered_binary_image(g{1,2}(2),g{1,2}(1)) == 1 && not(g{1,2}(2) == last_pos(2) && g{1,2}(1) == last_pos(1))
                curr_y = curr_y - 1;
            end
        else 
            if filtered_binary_image(g{2,3}(2),g{2,3}(1)) == 1 && not(g{2,3}(2) == last_pos(2) && g{2,3}(1) == last_pos(1))
                curr_x = curr_x + 1;
            elseif filtered_binary_image(g{3,3}(2),g{3,3}(1)) == 1 && not(g{3,3}(2) == last_pos(2) && g{3,3}(1) == last_pos(1))
                curr_x = curr_x + 1;
                curr_y = curr_y + 1;
            elseif filtered_binary_image(g{3,2}(2),g{3,2}(1)) == 1 && not(g{3,2}(2) == last_pos(2) && g{3,2}(1) == last_pos(1))
                curr_y = curr_y + 1;
            elseif filtered_binary_image(g{3,1}(2),g{3,1}(1)) == 1 && not(g{3,1}(2) == last_pos(2) && g{3,1}(1) == last_pos(1))
                curr_x = curr_x - 1;
                curr_y = curr_y + 1;
            elseif filtered_binary_image(g{2,1}(2),g{2,1}(1)) == 1 && not(g{2,1}(2) == last_pos(2) && g{2,1}(1) == last_pos(1))
                curr_x = curr_x - 1;
            end
        end
        last_pos = [last_x, last_y];
        l = l+1;
    end

    l = l * 1.7 / scale_factor;