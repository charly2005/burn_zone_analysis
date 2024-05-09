function [l,filtered_mat] = calculate_length(frame, raw_image_array, bayer_pattern, scale_factor)

    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    binary_image = imbinarize(rgb2gray(demosaiced_image), 0.0039);
    
    l = 0;
    binary_image = imfill(binary_image,4);
    binary_image = imfill(binary_image,4,'holes');
    % imshow(binary_image);
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
            if y < max_h && y >= 1
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
    mat_s = regionprops("table",mat_cc, "Area");
    [~,idx] = sort(mat_s.Area,"descend");
    filtered_mat = cc2bw(mat_cc, ObjectsToKeep=idx(1));
    % imshow(filtered_mat);
    % hold on
    % convert mat into yx coords

    flame_front = zeros(mat_s.Area(idx(1)),2);
    % y, x
    % 1, 1
    idx = 1;
    for y = 1:max_h
        for x = max_w:-1:1
            if mat(y,x) == 1
                flame_front(idx,1) = y;
                flame_front(idx,2) = x;
                idx = idx+1;
            end
        end
    end

    %segment the flame front into lines

    % Stuff for circle that doesn't change 
    angle = linspace(0,2*pi,100);   % Angle 
    xv = cos(angle)';               % Unscaled X Coordinates
    yv = sin(angle)';               % Unscaled Y Coordinates
  
    idx = 1;
    length = scale_factor;
    pos = flame_front(idx,:);
    
    while idx < height(flame_front)

        center = flame_front(idx,:);
        x_circle = xv*length + center(2);
        y_circle = yv*length + center(1);
        % plot(x_circle,y_circle,'r');
        % hold on
        [in,on] = inpolygon(flame_front(:,2),flame_front(:,1),x_circle,y_circle);
        % display(idx);
        idx = find(in, 1, 'last');

        pos = [pos; flame_front(idx,:)];
        distance = sqrt((pos(end-1,1) - pos(end,1))^2 + (pos(end-1,2) - pos(end,2))^2);
        % distance = pdist([pos(end-1);pos(end)],'euclidean');

        l = l + distance;
    end