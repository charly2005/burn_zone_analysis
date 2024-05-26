function [s,n,r, filtered_mat] = getFractalDimension(frame, raw_image_array, bayer_pattern)

    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    gain = 5;
    color_image = uint8(double(demosaiced_image)*(255/4095)*gain);
    gray_image = rgb2gray(color_image);
    binary_image = imbinarize(gray_image);
    % imshow(binary_image);
    p = log(max(size(binary_image)))/log(2);
    p = ceil(p);
    binary_image = imresize(binary_image, [2^p, 2^p]);
    % bw to cc then cc to bw 
    cc = bwconncomp(~binary_image);
    s = regionprops("table",cc, "Area");
    [~,idx] = sort(s.Area,"descend");
    filtered_binary_image = ~cc2bw(cc, ObjectsToKeep=idx(1));
    
    max_h = size(filtered_binary_image, 1);
    max_w = size(filtered_binary_image, 2);
    mat = zeros(max_h,max_w);

    % start at top and move down
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

    % % convert mat into yx coords            
    flame_front = zeros(mat_s.Area(idx(1)),2);
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
    % split into boxes of size n x n, up to p x p
    n = zeros(1, p+1);
    for i = 0:p
        for y = 1:2^i:max_h
            for x = 1:2^i:max_w
                box_x = [x, x+2^i];
                box_y = [y, y+2^i];
                [in,~] = inpolygon(flame_front(:,2),flame_front(:,1),box_x, box_y);
                if ~isempty(find(in==1,1,'first'))
                    n(i+1) = n(i+1) + 1;
                end
            end
        end
        if n(i+1) == 0
            n(i+1) = 1;
        end
    end

    r = 2.^(0:p);
    s=-gradient(log(n))./gradient(log(r));
    semilogx(r, s, 's-');
    xlabel('r, box size'); ylabel('- d ln n / d ln r, local dimension');
    title('box-count');
    % alternative
    % p = polyfit(log(1./r),log(n),1);
    % s = p(1);
    s = mean(s);


