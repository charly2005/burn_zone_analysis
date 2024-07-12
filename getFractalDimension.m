function [s,n,r,b] = getFractalDimension(frame, raw_image_array, bayer_pattern)
    gain=5;
    demosaiced_img = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    eight_bit_img = uint8(double(demosaiced_img).*(255/4095).*gain);
    % figure;
    % imshow(eight_bit_img);
    gray_img = rgb2gray(eight_bit_img);
    binary_img = imbinarize(gray_img); 
    p = log(max(size(binary_img)))/log(2);
    p = ceil(p);
    binary_img = imresize(binary_img, [2^p, 2^p]);
    im_height = size(binary_img, 1);
    im_width = size(binary_img, 2);

    max_h = im_height;
    max_w = im_width;
    cc = bwconncomp(~binary_img);
    s = regionprops("table",cc, "Area");
    [~,idx] = sort(s.Area,"descend");
    filtered_binary_image = ~cc2bw(cc, ObjectsToKeep=idx(1));
    % figure;
    % imshow(filtered_binary_image);
    % hold on
    B = bwboundaries(filtered_binary_image, 4);
    perim = B{1};
    min_height = min(perim(:,1));
    max_height = max(perim(:,1));
    
    % Upper point
    temp_perim = perim;
    rmv = perim(:,1)~=max_height;
    temp_perim(rmv,:) = [];
    max_pos = max(temp_perim(:,2));
    upper_idx = find(perim(:,1)==max_height & perim(:,2)==max_pos);
    % If you're at the starting point it'll give you a double point
    if length(upper_idx)>1
        upper_idx = min(upper_idx);
    end
    
    % Lower point
    temp_perim = perim;
    rmv = perim(:,1)~=min_height;
    temp_perim(rmv,:) = [];
    min_pos = max(temp_perim(:,2));
    lower_idx = find(perim(:,1)==min_height & perim(:,2)==min_pos);
    % If you're at the starting point it'll give you a double point
    if length(lower_idx)>1
        lower_idx = min(lower_idx);
    end
    
    % Doing this since I'm not sure how the perimeter is drawn. Not
    % sure if it starts from one point in particluar every time. Easier
    % to make sure.
    if upper_idx > lower_idx
        perim = perim(lower_idx:upper_idx,:);
        singleFlameFront = perim;
    elseif lower_idx > upper_idx
        perim = perim(upper_idx:lower_idx,:);
        singleFlameFront = perim;
    end
    
    flame_front = unique(singleFlameFront, 'rows', 'stable');
    b = zeros(2048, 2048);
    for i = 1:height(flame_front)
        b(flame_front(i,1), flame_front(i,2)) = 1;
    end
    % figure
    % imshow(b);
    % hold on

    n = zeros(1, p+1);
    for i = 0:p
        for y = 1:2^i:max_h-2^i + 1
            for x = 1:2^i:max_w-2^i + 1
                box_x = [x, x+2^i];
                box_y = [y, y+2^i];
                % hard coded inpolygon
                % in = [];
                % for j = 1:height(flame_front)
                %     if (flame_front(j,1) < box_y(2) && flame_front(j,1) > box_y(1) ...
                %             && flame_front(j,2) < box_x(2) && flame_front(j,2) > box_x(1))
                %         in = [1];
                %         break;
                %     end
                % end
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
    %s=-gradient(log(n))./gradient(log(r));
    %figure
    %semilogx(r, s, 's-');
    %xlabel('r, box size'); ylabel('- d ln n / d ln r, local dimension');
    %title('box dimension');
    % s = mean(s);

    % alternate method for n different values of r
    % exact same as linear regression w/ polyfit(x,y,1)
    nsumxy = 0;
    nsumx2 = 0;
    sumx = 0;
    sumy = 0;

    % exclude first 2
    r = r(3:end);
    n = n(3:end);

    % figure
    % plot(log(1./r),log(n),'o');
    % hold on
    % t = "Frame " + frame;
    % title(t);
    % hold on
    y = log(n);
    x = log(1./r);

    for i = 1:width(y)
        nsumxy = nsumxy + (y(i) * x(i));
        sumx = sumx + x(i);
        sumy = sumy + y(i);
        nsumx2 = nsumx2 + x(i)^2;
    end
    nsumxy = nsumxy * width(n);
    nsumx2 = nsumx2 * width(n);
    s = (nsumxy - sumx*sumy)/(nsumx2 - sumx^2);
        

