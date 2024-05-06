function l = calculate_length(frame, raw_image_array, bayer_pattern, scale_factor)

    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    binary_image = imbinarize(rgb2gray(demosaiced_image), 0.0039);
    binary_image = imresize(binary_image, scale_factor);
    

    binary_image = imfill(binary_image,8);
    binary_image = imfill(binary_image,8,'holes');
    % bw to cc then cc to bw 
    cc = bwconncomp(~binary_image);
    s = regionprops("table",cc, "Area");
    [~,idx] = sort(s.Area,"descend");
    filtered_binary_image = ~cc2bw(cc, ObjectsToKeep=idx(1));

    % imshow(filtered_binary_image);
    % hold on
    
    max_h = size(filtered_binary_image, 1);
    max_w = size(filtered_binary_image, 2);

   
    mat = zeros(max_h,max_w);
    % start at top and move down

    % filtered_binary_image(y,x);
    for y = 1:max_h
        row = filtered_binary_image(y,:,1);
        last = find(row,1,'last');
        first = find(row,1,'first');
        start = int16((last + first)/2);
        for x = start:max_w
            if x < max_w && x > 1
                if filtered_binary_image(y,x) == 1 && filtered_binary_image(y,x+1) == 0
                    % change on right
                    mat(y,x) = 1;
                elseif filtered_binary_image(y,x) == 1 && filtered_binary_image(y,x-1) == 0
                    % change on left
                    mat(y,x) = 1;
                end
            elseif x == max_w
                if filtered_binary_image(y,x) == 1
                    % edge case
                    mat(y,x) = 1;
                end
            end
        end
    end
    
    for x = 1:max_w
        col = filtered_binary_image(:,x,1);
        last = find(col,1,'last');
        first = find(col,1,'first');
        start = int16((last + first)/2);
        for y = start:max_h
            if y < max_h && y > 1
                if filtered_binary_image(y,x) == 1 && filtered_binary_image(y+1,x) == 0
                    % change on up
                    mat(y,x) = 1;
                elseif filtered_binary_image(y,x) == 1 && filtered_binary_image(y-1,x) == 0
                    % change on down
                    mat(y,x) = 1;
                end
            end
        end
    end
    
    mat_cc = bwconncomp(mat);
    mat_s = regionprops("table",mat_cc, "Area","Perimeter");
    [~,idx] = sort(mat_s.Area,"descend");
    filtered_mat = cc2bw(mat_cc, ObjectsToKeep=idx(1));
    imshow(filtered_mat);
    % disp(mat_s.Perimeter(1));
    l = mat_s.Perimeter(idx(1)) * 1.7 / scale_factor;