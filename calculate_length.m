function [l,filtered_mat] = calculate_length(frame, raw_image_array, bayer_pattern, scale_factor)

    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    binary_image = imbinarize(rgb2gray(demosaiced_image));
    
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
    %imshow(filtered_mat);
    %hold on
    % convert mat into yx coords            
    % 
    flame_front = bwtraceboundary(filtered_mat, [1,find(filtered_mat(1,:) ,1,'last')], 'S');
    % remove duplicate

    %segment the flame front into lines

    % Stuff for circle that doesn't change 
    angle = linspace(0,2*pi,360);   % Angle 
    xv = cos(angle)';               % Unscaled X Coordinates
    yv = sin(angle)';               % Unscaled Y Coordinates
  
    idx = 1;
    %length = round((max(flame_front(:,1))-min(flame_front(:,1)))/5);
    %disp(length);
    length = scale_factor;
    pos = flame_front(idx,:);
    distance = length;

    while idx < height(flame_front)

        center = flame_front(idx,:);
        x_circle = round(xv*length + center(2));
        y_circle = round(yv*length + center(1));
        %plot(x_circle,y_circle,'r');
        %hold on
        % display(idx);
        [in,on] = inpolygon(flame_front(:,2),flame_front(:,1),x_circle,y_circle);
        % out of the points in IN, choose point in the direction of largest
        % IDX

        disp("IGOTHERE")
        %idx = find(in==1, 1, 'last');
        pos = [pos; flame_front(idx,:)];
        if (size(pos)>1)  
            distance = sqrt((pos(end-1,1) - pos(end,1))^2 + (pos(end-1,2) - pos(end,2))^2);
        end
        % distance = pdist([pos(end-1);pos(end)],'euclidean');
        % plot([pos(end-1,2),pos(end,2)],[pos(end-1,1),pos(end,1)],'b','LineWidth',2);
        % hold on
        % plot(center(2),center(1),'ro','MarkerSize',4);
        % hold on
        l = l + distance;
        
        disp("IGOTHERE222")
        disp(idx)
        disp(flame_front(idx,:))
        disp(height(flame_front))
    end

    l=l+length;