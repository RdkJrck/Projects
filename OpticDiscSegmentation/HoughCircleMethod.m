%%%%        Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2020
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

function [ final_segmentated_image ] = HoughCircleMethod(experiment_metadata, params, image_id)
    %%%% Function CircHoughSegmentation
    %%%% Segments image by circular Hough Transform
    %%%% 
    %%%% :param experiment_metadata: struct experiment metadata
    %%%% :param params: vector of parametrs
    %%%% :param ind: index of segmented image
    
    % Check method params
    if params(2)<params(3)
        preprocessed_dir = experiment_metadata.project_paths.preprocessed_dir;
        data_metadata = experiment_metadata.data_metadata;

        image_name = data_metadata.image_names{image_id};
        dataset_mask = data_metadata.dataset_mask;
        x_size = data_metadata.scaled_image_size(1);
        y_size = data_metadata.scaled_image_size(2);

        % Get each optimized parameter from params vector

        canny_sigma_const = params(1);
        radius_low_bound = params(2);
        radius_high_bound = params(3);
        radius_step = params(4);

        % Read preprocessed image
        image_filepath = append(preprocessed_dir, image_name, '_preprocessed_image.png');
        preprocessed_image = imread(image_filepath);

        % Find Edges
        image_edges = edge(preprocessed_image, 'Canny',[ ], canny_sigma_const);
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

        [y, x] = find(Temp == max(Temp(:)));

        % Get found radius from radius vector and position in HS
        found_radius = radius_vect(z);

        % Get segmentation mask
        [xx, yy] = meshgrid(1:hough_space_dims(2), 1:hough_space_dims(1));

        final_segmentated_image = (yy - y(1)).^2 + (xx - x(1)).^2 <= (found_radius).^2;
    else
        final_segmentated_image = zeros(experiment_metadata.data_metadata.scaled_image_size,'logical');
    end
end
