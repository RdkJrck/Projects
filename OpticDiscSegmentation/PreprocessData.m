%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : DOPLNIT
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

function [ ] = PreprocessData(experiment_metadata, data_metadata)    
    %%%% Function PreprocessData aproximate and substracts backgound of image 
    %%%% and homogenize ilumination
    %%%% 
    %%%% :param experiment_metadata: struct experiment metadata
    %%%% :param data_metadata: struct data_metadata
    % Get metadata
    dataset_name = experiment_metadata.dataset_name;
    dataset_dir = experiment_metadata.project_paths.dataset_dir;
    preprocessed_dir = experiment_metadata.project_paths.preprocessed_dir;

    scaled_image_size = data_metadata.scaled_image_size;
    dataset_mask = data_metadata.dataset_mask;
    % For whole dataset
    for image_id = 1:length(data_metadata.image_names)

        image_name = data_metadata.image_names{image_id};
        switch dataset_name
            case { 'HRF_ALL', 'HRF_H', 'HRF_G', 'HRF_DR' }       
                    % Read original image (fullsize rgb)
                    orig_image = imread(append(dataset_dir, 'images\',  image_name, '.jpg'));
                    
                    % Get grayscale image
                    gray_scale_image = data_metadata.rgb_ratio(1) * orig_image( :, :, 1) + ...
                                       data_metadata.rgb_ratio(2) * orig_image( :, :, 2) + ...
                                       data_metadata.rgb_ratio(3) * orig_image( :, :, 3);                                           

    
            case  {  'STUDY_01',  'STUDY_02' }
    
                    % Read original image (fullsize gray)
                    gray_scale_image = imread(append(dataset_dir, 'images\', image_name,'_registered.avi_average_image.tif'));
%                     % Resize image
%                     resized_image = imresize(orig_image, scaled_image_size);
%     
%                     % Aproximate background via mean filtering
%                     image_background = imboxfilt(resized_image, data_metadata.bf_filter_size, 'NormalizationFactor', 1);                   
%                     % Substract background from image
%                     foreground_image = im2double(resized_image) - im2double(image_background);
%                     %foreground_image = imtophat(resized_image, strel('disk', data_metadata.top_hat_radius, 0));
%                     %foreground_image(dataset_mask == false) = 0;
        end

    % Resize image
    resized_image = imresize(gray_scale_image, scaled_image_size);

    % Aproximate background via mean filtering
    image_background = imboxfilt(resized_image, data_metadata.bf_filter_size);

    % Substract background from image
    foreground_image = im2double(resized_image) - im2double(image_background);
    
        % Alocate specific images of processing
        [ normalized_image, preprocessed_image ] = deal(zeros(scaled_image_size, 'uint8'));
    
        % Normalize image illumination range
        eye_values_max = max(foreground_image(dataset_mask == true));
        eye_values_min = min(foreground_image(dataset_mask));
        normalized_image_double = (foreground_image(dataset_mask == true) - eye_values_min) / (eye_values_max - eye_values_min);
        normalized_image(dataset_mask == true) = uint8(normalized_image_double * 255);
                             
        % Image histogram homogenization
        norm_image_hist = imhist(normalized_image(dataset_mask == true));
        
        % Get normalized image modus intensity
        [~, most_frequent_intensity] = max(norm_image_hist);
    
        preprocessed_image(dataset_mask == true) = normalized_image(dataset_mask == true) + (127 - most_frequent_intensity);
    
        imwrite(preprocessed_image, append(preprocessed_dir, image_name, '_preprocessed_image.png'))
    end
end
