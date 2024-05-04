function [l, s] = calculate_length(frame, raw_image_array, bayer_pattern)
    demosaiced_image = demosaic(raw_image_array(:,:,frame), bayer_pattern);
    gain = 5;
    color_image = uint8(double(demosaiced_image)*(255/4095)*gain);
    
    binary_image = imbinarize(rgb2gray(demosaiced_image), 0.0039);
    % imshow(binary_image);
    % hold on

    cc = bwconncomp(binary_image);
    s = regionprops("table",cc, "Area");
    [~,idx] = sort(s.Area,"descend");
    % display(cc);
    % imshow(cc2bw(cc));
    hold on;
    filtered_binary_image = cc2bw(cc, ObjectsToKeep=idx(1));
    imshow(filtered_binary_image);
    hold on
    l = 1;
    