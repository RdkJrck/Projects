%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

function [ final_segmentation_mask ] = RegionGrowMethod(experiment_metadata, method_params, image_id)
    %%%% Function RegionGrowMethod
    %%%% Segments image by morfological operations and region grown
    %%%% 
    %%%% :param experiment_metadata: struct experiment metadata
    %%%% :param params: vector of parametrs
    %%%% :param ind: index of segmented image
    % Check method params
    if method_params(1)<method_params(2) | method_params(4)<method_params(5)
        image_name = experiment_metadata.data_metadata.image_names{image_id};
        dataset_mask = experiment_metadata.data_metadata.dataset_mask;
        preprocessed_dir = experiment_metadata.project_paths.preprocessed_dir;

        % Get each optimized parameter from params vector
        hist_lower_bound = method_params(1);
        hist_upper_bound = method_params(2);
        adaptative_threshold_weight = method_params(3);
        low_morf_bound = method_params(4);
        high_morf_bound = method_params(5);
        morf_step = method_params(6);
        
        % Make vector of morfologi radiuses
        morph_disc_radiuses = [low_morf_bound:morf_step:high_morf_bound];

        % Read preprocessed image
        image_filepath = append(preprocessed_dir, image_name, '_preprocessed_image.png');
        preprocessed_image = imread(image_filepath);

        % Restrict image histogram low and high values
        preprocessed_image(dataset_mask == true & preprocessed_image < hist_lower_bound) = hist_lower_bound;
        preprocessed_image(dataset_mask == true & preprocessed_image > hist_upper_bound) = hist_upper_bound; 
        % Starting image
        morphed_image = preprocessed_image;
        
        
          % Initial best values for loop
        best_objective_value_found = 0;
        best_morph_image = preprocessed_image;    
        best_binary_mask = zeros(size(preprocessed_image));
       for radius = morph_disc_radiuses
            % Apply morfological opening on closed image
            morphed_image = imopen(morphed_image, strel('disk', radius, 0));    
            % Apply morfological closing on opened image
            morphed_image = imclose(morphed_image, strel('disk', radius, 0));
             [ binary_mask ] = seed_segmentation(morphed_image, adaptative_threshold_weight);
             [ objective_value_found ] = compute_objective_func_value(morphed_image, binary_mask, dataset_mask);
             if objective_value_found > best_objective_value_found         % If is new echo higher that actual max echo
            best_objective_value_found = objective_value_found;            % Update max echo
            best_morph_image = morphed_image;
            best_binary_mask = binary_mask;
            end
       end
       
        try
            % Approx ellipse via least square method
           [ final_segmentation_mask ] = approx_ellipse(best_binary_mask);
        catch
           [ final_segmentation_mask ] = binary_mask;
        end
    else
        final_segmentation_mask = zeros(experiment_metadata.data_metadata.scaled_image_size,'logical');
    end
end

function [ ellipse_image ] = approx_ellipse(image)
    %%%% Function get boundaries in binary input image. 
    %%%%  Function aprox elipse via leastsquare from boundaries positions. 
    %%%%  Than draw elipse in binary image.
    %%%% :param image: binary input image
    
    if sum(sum(image)) == 0
        ellipse_image = image;
        return
    end

    % Get positions of boundaries in binary image 
    boundaries = cell2mat(bwboundaries(image));
    % Keep only unique one
    boundaries = unique(boundaries, 'rows');
    try
        x = boundaries(:, 2);                                                                                            
        y = boundaries(:, 1);                        
    catch
        elipse_image = zeros(size(image), 'logical');
        disp('No boundaries found in binary image')
        return
    end
    % Aprox elipse via least square method
    ellipse = FitEllipse(x, y);  % Gets struct of elipse parametrs
    % Draw elipse in binary image
    try
        ellipse_image = draw_ellipse(ellipse, image);  % Draw binary elipse image
    catch
        ellipse_image = zeros(size(image),'logical');
    end
end

function [ elipse_image ] = draw_ellipse(el, image)
%%%%  Function DrawElipse draws binary ellipse image
%%%% :param image: ellipse coordinates
    xc = el.X0_in;                                    % Row of elipse centre
    yc = el.Y0_in;                                    % Col of elipse centre
    c = sqrt((el.long_axis/2)^2-(el.short_axis/2)^2); % Calculate lenght of C axis
    % % CALCULATE FOCALS POINT POSITION
    f1 = [ yc + sin(el.phi)*c  xc+cos(el.phi)*c];     % Position of focal point after rotation
    f2 = [ yc - sin(el.phi)*c  xc-cos(el.phi)*c];     % Position of focal point after rotation
    % DRAW ELIPSE
    [xx, yy] = meshgrid(1:size(image,2),1:size(image,1));   % Make meshgrit matrix
    elipse_image = logical(zeros(size(image)));             % Alocate image array background
    elipse_image(sqrt((xx - f1(2)).^2 + (yy - f1(1)).^2 ) + sqrt((xx - f2(2)).^2 + (yy - f2(1)).^2) < el.long_axis) = 1;% Draw elipse 
end

function [ojb_value] = compute_objective_func_value(input_image, binary_image, mask);
%%%%  Objective function computes between classvariation of image
    if sum(binary_image(:)) > 0                                  % If filtred binary_image image contains blob
        class0 = input_image(binary_image  == 0 & mask == 1);    % Vector of intensity disk image in disk area
        class1 = input_image(binary_image  == 1 & mask == 1);    % Vector of intensity disk image in background
        class0_size = size(class0, 1);             % Size of intensity disk image vector - disk
        class1_size = size(class1, 1);             % Size of intensity disk image vector - background 
        u0 = mean(class0);                         % Mean of background area in disk image
        u1 = mean(class1);                             % Mean of disk area in disk image  
        w0 = class0_size / (class0_size + class1_size);  % Calculate class probability
        w1 = class1_size / (class0_size + class1_size);  % Calculate class probability          
        ojb_value = w0 * w1 * ((u0 - u1)^2);                        % Calculate echo
    else
        ojb_value = 0;
    end
end

function [ output_image ] = seed_segmentation(input_image, adaptative_threshold_weight)
    %%%%  Function seed_segmentation start region growing from max value position in image
    %%%% :param input_image: Vessless image  
    %%%% :param adaptative_threshold_weight: treshold weight
    output_image = repmat(2, size(input_image));
    input_image_size = size(input_image);
    
    % Define 8 connected neighborhood
	neighbourhood_mask = [-1 0; 1 0; 0 -1;0 1; -1 -1; -1 1; 1 -1; 1 1];

    % Find initial seed - max value in image
    [yy, ~] = max(input_image);
    
    % Find initial seed coordinates
    maximal = max(max(input_image)); 
    [x,y] = find(input_image == maximal) ;
    xp = x(1,1); 
    yp = y(1,1);
    
    positions_to_grow = [xp yp];
    output_image(xp,yp) = 1;

    % Iteration - Expasion of area
    while ~isempty (positions_to_grow)
        x = positions_to_grow(1, 1);
        y = positions_to_grow(1, 2);

        % Apply adaptive treshold
        threshold = (256 - input_image(x,y)) * adaptative_threshold_weight;
 
        for i = 1:size(neighbourhood_mask,1)

            % Calculate the neighbour coordinate
            xn = x + neighbourhood_mask(i, 1);
            yn = y + neighbourhood_mask(i, 2);

            % Check inside position of new pixel 
            if ( ...
                (xn >= 1 && yn >= 1) && ... 
                (xn <= input_image_size(1) && yn <= input_image_size(2)) && ...
                (output_image(xn,yn) == 2) ... % If position was already checked
               )
            
                difference  = abs(input_image(xp, yp) - input_image(xn, yn)); %TODO xp and yp exchange for x and y?
                
                %Compare with treshold          
                if ( difference <= threshold ) && (output_image(xn, yn) == 2)
                   output_image(xn, yn) = 1;
                   positions_to_grow = [positions_to_grow; [xn yn]];

                elseif ( difference > threshold ) && (output_image(xn, yn) == 2)
                   output_image(xn, yn) = 0;
                end

            end
        end
        positions_to_grow = positions_to_grow(2:end, :);
    end

    output_image( output_image == 2) = 0;
    output_image = logical(output_image);
end