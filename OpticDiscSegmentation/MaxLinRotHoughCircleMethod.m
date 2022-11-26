%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

function [ final_segmentated_image ] = MaxLinRotHoughCircleMethod(experiment_metadata, params, image_id)
    %%%% Function CircHoughSegmentation
    %%%% Segments image by rotaiting linear max variance morfological operator and circular Hough Transform
    %%%% 
    %%%% :param experiment_metadata: struct experiment metadata
    %%%% :param params: vector of parametrs
    %%%% :param ind: index of segmented image
    
    % Check method params
    if params(1)<params(2) | params(5)<params(6)
        preprocessed_dir = experiment_metadata.project_paths.preprocessed_dir;
        data_metadata = experiment_metadata.data_metadata;

        image_name = data_metadata.image_names{image_id};
        dataset_mask = data_metadata.dataset_mask;
        x_size = data_metadata.scaled_image_size(1);
        y_size = data_metadata.scaled_image_size(2);

        % Get each optimized parameter from params vector
        hist_lower_bound = params(1);
        hist_upper_bound = params(2);
        morph_lin_lenght = params(3);
        canny_sigma_const = params(4);
        radius_low_bound = params(5);
        radius_high_bound = params(6);
        radius_step = params(7);

        % Read preprocessed image
        image_filepath = append(preprocessed_dir, image_name, '_preprocessed_image.png');
        preprocessed_image = imread(image_filepath);
        
        % Restrict image histogram low and high values
        preprocessed_image(dataset_mask == true & preprocessed_image < hist_lower_bound) = hist_lower_bound;
        preprocessed_image(dataset_mask == true & preprocessed_image > hist_upper_bound) = hist_upper_bound; 

        % Apply max variance closing with linera rotation structure element
        [ morphed_image ] = max_of_lin_rot_close_operator(preprocessed_image, morph_lin_lenght);

        % Find Edges
        image_edges = edge(morphed_image, 'Canny',[ ], canny_sigma_const);
        image_edges(dataset_mask == false) = 0;

        % Get vectors of edges position in x and y direction
        [x_edges, y_edges] = find(image_edges == true);

        % Define vector of searched radiuses
        radius_vect = radius_low_bound:radius_step:radius_high_bound;

        % Define Hough space
        hough_space = zeros(x_size, y_size, length(radius_vect));

        % Compute Hough space
        for i = 1:length(x_edges);
            for k = 1:length(radius_vect);
                for line_angle = 0:2*pi/100:2*pi;
                    a = round(x_edges(i) - radius_vect(k) * cos(line_angle));
                    b = round(y_edges(i) - radius_vect(k) * sin(line_angle));
                    if (a > 0) && (b > 0) && (a < x_size) && (b < y_size);
                        hough_space(a, b, k) = hough_space(a, b, k) + 1;
                    end
                end
            end
        end

        % Find indexes of max value in Hough space
        hough_space_dims = size(hough_space);
        final_segmentated_image = zeros([x_size y_size],'logical');
        [~,t] = max(hough_space(:));
        z = ceil(t / (hough_space_dims(1) * hough_space_dims(2)));
        Temp = hough_space(:,:,z);
        try
            [y, x] = find(Temp == max(Temp(:)));
            
        % Get found radius from radius vector and position in HS
        found_radius = radius_vect(z);

        % Get segmentation mask
        [xx, yy] = meshgrid(1:hough_space_dims(2), 1:hough_space_dims(1));

        final_segmentated_image = (yy - y(1)).^2 + (xx - x(1)).^2 <= (found_radius).^2;
        catch
            final_segmentated_image = zeros(experiment_metadata.data_metadata.scaled_image_size,'logical');
        end

    else
        final_segmentated_image = zeros(experiment_metadata.data_metadata.scaled_image_size,'logical');
    end
end

function [vessless_image] = max_of_lin_rot_close_operator(input, lin_lenght)
    %%%% Vessel masking by method introduced in paper:
    %%%% Detecting the Optic Disc Boundary in Digital Fundus
    %%%% Images Using Morphological, Edge Detection, and
    %%%% Feature Extraction Techniques.
    vessless_image = zeros([size(input)]);
    % Initial vector of angles
    angle_vector = (0:15:75);
    % Initial variance space - x,y - image z - angle;
    variance_space = zeros([size(input) length(angle_vector)]);
    % Angle index
    ind = 1;
    % Initial image space - x,y - closed image z1 - angle z2 angle-90deg;
    image_space = zeros([size(input) 2 6]);
    for angle = angle_vector
        image_space(:,:,1,ind) = imclose(input,strel('line',lin_lenght,angle));
        image_space(:,:,2,ind) = imclose(input,strel('line',lin_lenght,angle+90));
        variance_space(:,:,ind) = var(image_space(:,:,:,ind), 0, 3);
        ind = ind+1;
    end
    % Find max value of max varince images on x,y postion
    [~, space_max_index] = max(variance_space,[],3);
    for y = 1:size(input,1)
        for x = 1:size(input,2)
            vessless_image(y,x) = max([image_space(y,x,1,space_max_index(y,x)) image_space(y,x,2,space_max_index(y,x))]);
        end
    end
    % Keep image in uint8 format
    vessless_image = uint8(vessless_image);
end