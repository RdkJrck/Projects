%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : DOPLNIT
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne


function [ ] = GenerateGroundTruthImages(project_paths, data_metadata)
%%%% Function GenerateGroundTruthImages
%%% Generates ground truth images for selected dataset.
%%%
%%% :param project_paths: struct project paths
%%% :param data_metadata: struct dataset metadata

    % Generate ground truth images for selected dataset
    switch data_metadata.dataset_name
        case { 'HRF_ALL', 'HRF_H', 'HRF_G', 'HRF_DR' }
            generate_groundtruth_HRF_images(project_paths, data_metadata);
        case  { 'STUDY_01', 'STUDY_02'}
            generate_groundtruth_STUDY_images(project_paths, data_metadata);
    end
end


function [ ] = generate_groundtruth_HRF_images(project_paths, data_metadata)
%%%% Function generate_groundtruth_HRF_images
%%% Generates ground truth images for HRF dataset.
%%%
%%% :param project_paths: struct project paths
%%% :param data_metadata: struct dataset metadata

    % Load needed information from arguments
    dataset_name = data_metadata.dataset_name;
    hrf_metadata_path = append(project_paths.dataset_dir, 'metadata\optic_disk_gt.xlsx');
    ground_truth_image_path = project_paths.ground_truth_dir;
    original_image_size = data_metadata.original_image_size;
    scaled_image_size = data_metadata.scaled_image_size;
    dataset_image_names = data_metadata.image_names;

    % Local variables for indexing circle parameters from ground truth table of parameters
    switch dataset_name
        case 'HRF_ALL'
            start_ind = 1;
            increment = 1;
        case 'HRF_DR'
            start_ind = 1;
            increment = 3;
        case 'HRF_G'
            start_ind = 2;
            increment = 3;
        case 'HRF_H'
            start_ind = 3;
            increment = 3;
    end

    % Get table of circle parameters
    warning('off','MATLAB:xlsread:ActiveX');  % Supresses matlabs irrelevant cry for proper excel server connection
    ground_truth_table = xlsread(hrf_metadata_path);    
    
    % Initialize meshgrid for distances    
    [xx, yy] = meshgrid(1:scaled_image_size(2), 1:scaled_image_size(1));         
    
    % Get scale between scaled and resized image    
    scale = (scaled_image_size / original_image_size);                         
    
    % Image loop
    for ind = 1:length(dataset_image_names)
        
        % Get ground truth circle parameters
        circle_params = num2cell(ground_truth_table(start_ind + ((ind - 1) * increment), [1,2,5]) * scale);
        [circle_x, circle_y, circle_diameter] = circle_params{:};
        
        % Initialize ground truth image matrix
        gt_image_matrix = zeros(scaled_image_size, 'logical');

        % Fill circle in ground truth image matrix with ones
        gt_image_matrix(sqrt((xx - circle_x).^2 + (yy - circle_y).^2 ) < ((circle_diameter / 2) - 0.5) ) = 1;
        
        % Write ground truth image
        imwrite(gt_image_matrix, append(ground_truth_image_path, 'groundTruth_', dataset_image_names{ind}, '.png'));
    end
end


function [ ] = generate_groundtruth_STUDY_images(project_paths, data_metadata)
%%%% Function generate_groundtruth_STUDY_images
%%% Generates ground truth images for STUDY datasets.
%%%
%%% :param project_paths: struct project paths
%%% :param data_metadata: struct dataset metadata
    
    % Load needed information from arguments
    dataset_name = data_metadata.dataset_name;
    study_dataset_path = append(project_paths.dataset_dir, 'images\');
    ground_truth_image_path = project_paths.ground_truth_dir;
    original_image_size = data_metadata.original_image_size;
    scaled_image_size = data_metadata.scaled_image_size;
    dataset_image_names = data_metadata.image_names;
   
    % Image loop
    for ind = 1:length(dataset_image_names)
        
        % Read contours in text file
        if dataset_name == "STUDY_01"
            contours_filepath = append(study_dataset_path, dataset_image_names{ind}(1:17),'_registered_OD_contour.txt');
            contours = textread(contours_filepath);
            % Create binary mask and fill ground truth segment with ones
            binary_mask_orig = roipoly(zeros(original_image_size(1), original_image_size(2)), contours(:,1)', contours(:,2)');
        elseif dataset_name == "STUDY_02"
            contours_filepath = append(study_dataset_path, dataset_image_names{ind}(1:19),'_registered_median.tif_OD_body_kontury_corrected.mat');
            contours = load(contours_filepath);
            contours = contours.vyslednevrcholy2;
            % Create binary mask and fill ground truth segment with ones
            binary_mask_orig = roipoly(zeros(original_image_size(1), original_image_size(2)), contours(:,1)', contours(:,2)');
        end
        % Resized mask to scaled size       
        binary_mask_scaled = imresize(binary_mask_orig, scaled_image_size);
        % Write ground truth image
        imwrite(binary_mask_scaled, append(ground_truth_image_path, 'groundTruth_', dataset_image_names{ind},'.png'));
    end

end

