%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne


function [ experiment_metadata ] = InitProject(method, dataset_name, cross_val_fold_number)
%%%% Function InitProject
%%  Initializes experiment_metadata structure which holds essential information 
%%  about selected method and dataset. It also prepares data for training and evaluation
%%  of selected method.        
%%
%%  :param dataset_name: selected dataset
%%  :param method: selected method
%%  :param cross_val_fold_number: number of cross validation folds
%%  :return experiment_metadata: structure with project metadata

    % Initialize experiment metadata structure and its basic variables
    experiment_metadata = struct();
    experiment_metadata.method = method;
    experiment_metadata.dataset_name = dataset_name;
    experiment_metadata.cross_val_fold_number = cross_val_fold_number;

    % Prepare project data and GA configuration for searching parameters of selected method
    experiment_metadata.project_paths = initialize_paths(experiment_metadata);
    experiment_metadata.data_metadata = initialize_data_metadata(experiment_metadata);
    experiment_metadata.ga_config = create_genetic_algorithms_config(experiment_metadata);
    
    % If selected method is Bat algorithm, add additional configuration for Bat algorithm 
    if method == "MorphBatEllipse"
        experiment_metadata.ba_config = create_bat_algo_config();    
    end

end


function [ project_paths ] = initialize_paths(experiment_metadata)
%%%% Function initialize_paths
%%  Initializes project_paths structure which holds information about
%%  filepaths essential for project. This includes paths to images to be
%%  loaded or generated, and project results (found parameters for
%%  selected method, GA training logs, evaluation metrics).  
%%  
%%  :param experiment_metadata: structure with project metadata
%%  :return project_paths: structure with project paths    

    % Load needed information from metadata
    dataset_name = experiment_metadata.dataset_name;
    
    % Create empty structure
    project_paths = struct();
    
    % Add path to selected dataset
    switch dataset_name
        case { 'HRF_ALL', 'HRF_H', 'HRF_G', 'HRF_DR' }                    
            project_paths.dataset_dir = append(pwd, '\datasets\HRF\');
        case  { 'STUDY_01', 'STUDY_02'}
            project_paths.dataset_dir = append(pwd, '\datasets\study_dataset\', experiment_metadata.dataset_name, '\');
    end
    
    % Add paths to generated images, found parameters and results
    project_paths.results_dir = append(pwd, '\results\', dataset_name, '\');
    project_paths.ground_truth_dir = append(project_paths.results_dir, 'ground_truth_images\');
    project_paths.preprocessed_dir = append(project_paths.results_dir, 'preprocessed_images\');
    project_paths.segmentations_dir = append(project_paths.results_dir, 'segmented_images\');
%     project_paths.training_solutions_dir = append(results_dir, 'training_solutions\');
%     project_paths.training_logs_dir = append(results_dir, 'training_logs\');
%     project_paths.test_metrics_dir = append(results_dir, 'test_metrics\');

end


function [ data_metadata ] = initialize_data_metadata(experiment_metadata)
%%%% Function prepare_data
%%  Initializes data_metadata structure which holds information about
%%  selected dataset and division of images into train and
%%  test sets of individual cross validation folds.
%%  
%%  :param experiment_metadata: structure with project metadata
%%  :return data_metadata: structure with data's metadata

    % Initialize dataset specific image sizes and filenames
    data_metadata = get_dataset_specifics(experiment_metadata);
    data_metadata.image_names = get_dataset_image_names(experiment_metadata);

    % Generate cross validation folds image indices
    [ testset_matrix, trainset_matrix ] = set_cross_val_fold_indices(experiment_metadata, data_metadata);
    data_metadata.test_ids_per_fold = testset_matrix;
    data_metadata.train_ids_per_fold = trainset_matrix;
    
end


function [ data_metadata ] = get_dataset_specifics(experiment_metadata)
%%%% Function get_dataset_specifics
%%  Initializes data_metadata structure which holds information about
%%  selected dataset specific preprocessing settings or specific dataset mask.  
%%  
%%  :param experiment_metadata: structure with project metadata
%%  :return data_metadata: structure with data's metadata    

    % Load needed information from experiment metadata
    dataset_name = experiment_metadata.dataset_name;

    % Intialize empty structure
    data_metadata = struct();
    data_metadata.dataset_name = dataset_name;
    
    % Add dataset specific preprocessing information   
    switch dataset_name
        case { 'HRF_ALL', 'HRF_H', 'HRF_G', 'HRF_DR' }                    
            data_metadata.original_image_size = [2336 3504];
            data_metadata.scaled_image_size = [389 584];
            data_metadata.rgb_ratio = [.75 .25 .00];
            data_metadata.dataset_mask = make_hrf_mask(data_metadata.scaled_image_size);
            data_metadata.bf_filter_size = 69;
        case  'STUDY_01'
            data_metadata.original_image_size = [480 640];
            data_metadata.scaled_image_size = [96 128];
            data_metadata.dataset_mask = make_study_mask(data_metadata.scaled_image_size);
        case  'STUDY_02'
            data_metadata.original_image_size = [770 1000];
            data_metadata.scaled_image_size = [96 128];
            data_metadata.dataset_mask = make_study_mask(data_metadata.scaled_image_size);
    end
    data_metadata.bf_filter_size = 69;
end


function [ mask ] = make_hrf_mask(image_size)
%%%% Function generates image mask for HRF dataset.
%%     
%%   :param image_size: size of scaled HRF image
%%   :return image_size: image mask for HRF dataset

    % Alocate mask matrix
    mask = false(image_size(1), image_size(2));
    % Make x and y direction meshgrid of image size
    [col row] = meshgrid(1:image_size(2), 1:image_size(1));
    % Set radius to 5/12 of image rows
    radius = floor((5 / 12) * image_size(2));
    % Get binary mask for dataset
    mask = (row - (image_size(1) / 2)).^2 + (col - (image_size(2) / 2)).^2 <= radius.^2;

end


function [mask] = make_study_mask(image_size)
%%%% Function generates image mask for STUDY dataset.
%%     
%%   :param image_size: size of scaled STUDY image
%%   :return image_size: image mask for STUDY dataset

    % Define border thickness in pixels
    mask_border = 10;
    % Matrix of ones of size without borders
    mask = true(image_size(1) - (2 * mask_border), image_size(2) - (2 * mask_border));
    % Pad broders with zero values
    mask = padarray(mask, [mask_border mask_border], false, 'both');

end


function [ image_names ] = get_dataset_image_names(experiment_metadata)
%%%% Function get_dataset_image_names
%%  Initializes data_metadata structure which holds information about
%%  selected dataset specific preprocessing settings or specific dataset mask.
%%
%%   :param experiment_metadata: size of scaled STUDY image
%%   :return image_names: image mask for STUDY dataset

    % Load needed information from experiment metadata
    dataset_name = experiment_metadata.dataset_name;
    dataset_dir = experiment_metadata.project_paths.dataset_dir;

    % Select dataset images to be loaded subfix
    switch dataset_name
        case 'HRF_ALL'
            read_subfix = '*.jpg';
            remove_subfix = '.jpg';
        case 'HRF_H'
            read_subfix = '*h.jpg';
            remove_subfix = '.jpg';
        case 'HRF_G'
            read_subfix = '*g.jpg';
            remove_subfix = '.jpg';
        case 'HRF_DR'
            read_subfix = '*dr.jpg';
            remove_subfix = '.jpg';
        case {'STUDY_01', 'STUDY_02'}
            read_subfix = '*registered.avi_average_image.tif';
            remove_subfix = '_registered.avi_average_image.tif';
    end
    
    % Read image filenames
    dir_struct = dir(append(dataset_dir, 'images\', read_subfix));
    image_filenames = {dir_struct.name}';
    
    % Remove redundant files by subfixes 
    image_names = erase(image_filenames, remove_subfix);

end

function [testset_matrix, trainset_matrix] = set_cross_val_fold_indices(experiment_metadata, data_metadata)
%%%% Function set_cross_val_fold_indices
%%  Divides images into individual folds and prepares test and training sets for cross validation. 
%%
%%   :param experiment_metadata: structure with project metadata
%%   :param data_metadata: structure with data's metadata
%%   :return testset_matrix: matrix - containing for each fold row of his ids (used for testing)
%%   :return trainset_matrix: matrix - containing for each fold row of other folds ids (used for training)

    % Load needed information from experiment metadata
    cross_val_fold_number = experiment_metadata.cross_val_fold_number;
    image_names = data_metadata.image_names;
    scaled_image_size = data_metadata.scaled_image_size;

    % Check if number of folds is lower than number of dataset images
    number_of_images = length(image_names);
    if number_of_images < cross_val_fold_number
        error("Number of images must be greater than number of cross validation folds");
    end
    
    % Create random permutation of image ids and compute number of images per each fold as a vector
    permutation = randperm(number_of_images);
    images_per_fold_vector = repmat(floor(number_of_images / cross_val_fold_number), cross_val_fold_number, 1);
    if rem(number_of_images, cross_val_fold_number) > 0
        images_per_fold_vector(1:rem(number_of_images, cross_val_fold_number)) = images_per_fold_vector(1:rem(number_of_images, cross_val_fold_number)) + 1;
    end
    
    % Initialize output matrices
    testset_matrix = zeros(cross_val_fold_number, max(images_per_fold_vector));
    trainset_matrix = zeros(cross_val_fold_number, number_of_images - min(images_per_fold_vector));

    % Fill matrices with image ids
    for i = 1:cross_val_fold_number
        if i == 1
            testset_matrix(i, 1:images_per_fold_vector(i)) = permutation(1:images_per_fold_vector(1:i)); 
            trainset_matrix(i, 1:number_of_images-images_per_fold_vector(i)) = permutation(images_per_fold_vector(1:i) + 1:end);
        elseif i < cross_val_fold_number && i > 1
            testset_matrix(i, 1:images_per_fold_vector(i)) = permutation(sum(images_per_fold_vector(1:i-1)) + 1:sum(images_per_fold_vector(1:i)));
            trainset_matrix(i, 1:number_of_images - images_per_fold_vector(i)) = [permutation(1:sum(images_per_fold_vector(1:i-1))), permutation(sum(images_per_fold_vector(1:i)) + 1:end)];
        elseif i == cross_val_fold_number
            testset_matrix(i, 1:images_per_fold_vector(i)) = permutation(end - images_per_fold_vector(i) + 1:end);
            trainset_matrix(i, 1:number_of_images - images_per_fold_vector(i)) = permutation(1: end - images_per_fold_vector(i));
        end
    end

end

function [ ga_config ] = create_genetic_algorithms_config(experiment_metadata)
%%%% Function create_genetic_algorithms_config
%%  Creates genetic algorithm configuration structure. Configuration is method specific.
%%
%%  :param experiment_metadata: structure with project metadata
%%  :return ga_config: structure with genetic algorithm configuration
    
    % Load needed information from experiment metadata
    method = experiment_metadata.method;
    
    % Utility object with method for conversion of parameters from parametric to normalized space
    utils = UtilsClass();
    
    % Initialize genetic algorithm configuration empty structure
    ga_config = struct();

    % Add method specific parameter search space into configuration
    switch method
        case "MorphBatEllipse"
            ga_config.lower_bound = [ 0 0 4 4 4 ];                        % Lower boundaries of search space
            ga_config.upper_bound = [ 255 255 22 22 18 ];       % Upper boundaries of search space
            ga_config.odd_params = [ 0 0 0 0 0 ];                         % Index vector of odd params
            ga_config.even_params = [ 0 0 0 1 1 ];                        % Index vector of even params
            ga_config.round_params = [ 1 1 1 1 1 ];                      % Index vector of integer params
            ga_config.nVar = 5;                                                        % Number of optimized params
            ga_config.x0 = utils.para2norm(ga_config, [ 128 190 4 16 4 ]); % X_0 entity

        case "ThreshMorph"
           ga_config.lower_bound = [ 3 3 0 3 100 ];                     % Lower boundaries of search space
            ga_config.upper_bound = [ 30 30 1 30 2000 ];           % Upper boundaries of search space
            ga_config.odd_params = [ 0 0 0 0 0 ];                           % Index vector of odd params
            ga_config.even_params = [ 1 1 0 0 0 ];                         % Index vector of even params
            ga_config.round_params = [ 1 1 0 1 1 ];                       % Index vector of integer params
            ga_config.nVar = 5;                                                         % Number of optimized params
            ga_config.x0 = utils.para2norm(ga_config, [ 10 20 0.6 10 200 ]); % X_0 entity
        
        case "RegionGrow"
            ga_config.lower_bound = [ 0 0 0.05 4 4 4 ];                  % Lower boundaries of search space
            ga_config.upper_bound = [ 255 255 0.95 22 22 18 ];  % Upper boundaries of search space
            ga_config.odd_params = [ 0 0 0 0 0 0 ];                         % Index vector of odd params
            ga_config.even_params = [ 0 0 0 0 0 0 ];                        % Index vector of even params
            ga_config.round_params = [ 1 1 0 1 1 1 ];                      % Index vector of integer params
            ga_config.nVar = 6;                                                            % Number of optimized params
            ga_config.x0 = utils.para2norm(ga_config, [ 128 200 0.2 4 16 4 ]); % X_0 entity
            
        case "HoughCircle"
            ga_config.lower_bound = [ 1 10 10 1 ];                          % Lower boundaries of search space
            ga_config.upper_bound = [ 20 50 50 5 ];                        % Upper boundaries of search space
            ga_config.odd_params = [ 0 0 0 0 ];                                 % Index vector of odd params
            ga_config.even_params = [ 0 0 0 0 ];                               % Index vector of even params
            ga_config.round_params = [ 1 1 1 1 ];                             % Index vector of integer params
            ga_config.nVar = 4;                                                            % Number of optimized params
            ga_config.x0 = utils.para2norm(ga_config, [ 6 20 40 2]); % X_0 entity
        case "MaxLinRotHoughCircle"
            ga_config.lower_bound = [ 0 0 5 1 10 10 1 ];                % Lower boundaries of search space
            ga_config.upper_bound = [ 255 255 30 20 40 40 5 ];  % Upper boundaries of search space
            ga_config.odd_params = [ 0 0 0 0 0 0 0];                       % Index vector of odd params
            ga_config.even_params = [ 0 0 0 0 0 0 0];                     % Index vector of even params
            ga_config.round_params = [ 1 1 1 1 1 1 1 ];                  % Index vector of integer params
            ga_config.nVar = 7;                                                           % Number of optimized params
            ga_config.x0 = utils.para2norm(ga_config, [128 200 15 6 20 40 2]); % X_0 entity
            
    end

    % Add GA configuration setting that is used by all methods
    ga_config.nPop = 50;                                           % Starting population size
    ga_config.Generations = 10;                                % Number of generations
    ga_config.VarSize = [1, ga_config.nVar];           % Number of searched parameters 
    ga_config.VarMin = 0;                                          % Normalized space lower bound
    ga_config.VarMax = 1;                                          % Normalized space upper bound
    ga_config.sigma = 0.3;                                         % Mutation step                                    
    ga_config.beta = 2;                                               % Beta of probability
    ga_config.pC = 0.2;                                              % Parent to child ratio 
    ga_config.nC = round(ga_config.pC * ga_config.nPop / 2) * 2;   % Number of offspring
    ga_config.mu = 0.1;                                              % Mutation probability

end


function [ ba_config ] = create_bat_algo_config()
%%%% Function create_bat_algo_config
%%  Creates bat algorithm configuration structure.
%%
%%  :return ba_config: structure with bat algorithm configuration

    ba_config = struct();                                          % BA struct alocation
    ba_config.population_size = 20;                      % Size of population
    ba_config.num_of_iter = 10;                             % Numer of iterations
    ba_config.loudness_beta = 0.9;                       % Loudnes factor
    ba_config.pulse_rate_sigma = 0.9;                  % Pulse rate factor
    ba_config.freq_min = 0;                                     % Minimum of generated freq
    ba_config.freq_max = 2;                                    % Maximum of generated freq

end

