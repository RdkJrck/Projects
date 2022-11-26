%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%% Set method, dataset and number of folds    %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Set method for project run
% method = 'ThreshMorph';
 method = 'MorphBatEllipse';
% method = 'MaxLinRotHoughCircle';
% method = 'RegionGrow';
 %method = 'HoughCircle';

% Set dataset for project run
% dataset_name = 'STUDY_01';
% dataset_name = 'HRF_ALL';
% dataset_name = 'STUDY_02';    

% Set number of crossvalidation folds
cross_val_fold_number = 5;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%              Set project run  options                  %%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

op.training = false; % Run training phase 
op.use_raw = false; % Use raw data for run
op.gen_gt = false; % Generate ground truth images



%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%        Run segmentation                                %%%%
% %%%%%%%%%%%%%%%%%%%%%%%%%%%%

 RunProject(dataset_name,method, cross_val_fold_number,op);

function [ ] = RunProject(dataset_name, method, cross_val_fold_number,op)
    %%%% Function runs optinal training and evaluates segmentations
    %%  :param dataset_name: name of segmented dataset
    %%  :param method: method of segmentation
    %%  :param cross_val_fold_number: number of folds of crossvalidation
    %%  :return training: Option for training phase
    
    % Initialize project metadata
    experiment_metadata = InitProject(method, dataset_name, cross_val_fold_number);
    
    
    if op.gen_gt == true % If user want generato ground truth
        
    % Generate and save ground truth images
    GenerateGroundTruthImages(experiment_metadata.project_paths, experiment_metadata.data_metadata);
    
    end
    
    
    if op.use_raw  true == true % If user want use raw data for run
        
        % Preprocess and save dataset images     
        PreprocessData(experiment_metadata, experiment_metadata.data_metadata);

    end
    
    % Initialize logger object for logging project outputs
    logger = LoggerClass(experiment_metadata);
    
    % Run training via genetic algorithm
    if op.training == true

        % Find best parameters for selected segmentation method using GA
        [ best_solutions_parameters, best_cost_generation_values ] = GAOptimalization(experiment_metadata);

        % Save best cost values per generation from training
        logger.save_training_log(best_cost_generation_values);

        % Save best found params per fold from training
        logger.save_found_solution_params(best_solutions_parameters);

    end
    
    % Evaluate best found parameters for selected method on test fold images 
    [segmentation_test_metrics] = EvaluateSolution(experiment_metadata);
    
    % Save performance metrics from evaluation
    logger.save_test_metrics(segmentation_test_metrics);
    
end