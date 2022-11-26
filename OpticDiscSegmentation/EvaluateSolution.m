%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

function  [ segmentation_metrics, solutions_parameters] = EvaluateSolution(experiment_metadata)
    %%%% Function evaluate segmentation metrices
    method = experiment_metadata.method;
    cross_val_fold_number = experiment_metadata.cross_val_fold_number;
    image_names = experiment_metadata.data_metadata.image_names;
    % Read test indexes
    test_ids_per_fold = readmatrix([ experiment_metadata.project_paths.results_dir method '_test_ids.csv']);
    % Read solutions parametrs
    solutions_parameters = readmatrix([ experiment_metadata.project_paths.results_dir method '_found_solution_parameters.csv']);
    % Get directory
    segmentations_dir = experiment_metadata.project_paths.segmentations_dir;
    % Alocate metric matrix
    segmentation_metrics = zeros(length(image_names), 6+size(solutions_parameters,2));
    [ fold_size, method_number_of_params ] = size(solutions_parameters);
    % Start evaluate solution by folds
    for fold_ind = 1:cross_val_fold_number
        fold_test_ids = test_ids_per_fold(fold_ind, :);
        fold_test_ids(fold_test_ids == 0) = [];
        fold_params = solutions_parameters(fold_ind,:);
        for ind = 1:length(fold_test_ids)
            test_id = fold_test_ids(ind);
            
            % Segment image and measure segmentation time
            tic;
            segmentation_mask = segment_image(experiment_metadata, fold_params, test_id);
            method_time = toc;
            % Get ground truth mask
            gt_mask = load_gt_mask(experiment_metadata, test_id);
            % Evaluate solution
            [accuracy, overlap, dice_score, centroids_euclid_distance] = evaluate_segmentation_image(segmentation_mask, gt_mask);
            % Write metrics
            segmentation_metrics(test_id, 1) = fold_ind;
            segmentation_metrics(test_id, 2) = accuracy;
            segmentation_metrics(test_id, 3) = overlap;
            segmentation_metrics(test_id, 4) = dice_score;
            segmentation_metrics(test_id, 5) = centroids_euclid_distance;
            segmentation_metrics(test_id, 6) = method_time;
            segmentation_metrics(test_id, 7:end) = fold_params;
            % Display info for user
            disp(append("Saving segmented image ", image_names{test_id}));
   
            % Draw mask borders into proprocessed image
            image_filepath = append(experiment_metadata.project_paths.preprocessed_dir, image_names{test_id}, '_preprocessed_image.png');
            preprocessed_image = imread(image_filepath);
            [red, green, blue] = deal(preprocessed_image);
            green(edge(gt_mask)) = 255;
            red(edge(gt_mask)) = 0;
            blue(edge(gt_mask)) = 0;
            red(edge(segmentation_mask)) = 255;
            blue(edge(segmentation_mask)) = 0;
            green(edge(segmentation_mask)) = 0;
            mask_comparsion(:,:,1) = red;
            mask_comparsion(:,:,2) = green;
            mask_comparsion(:,:,3) = blue;
           imwrite(mask_comparsion, append(segmentations_dir, image_names{test_id}, "_", method,'_mask_comparsion.png'));
            % Write segmented image
            imwrite(segmentation_mask, append(segmentations_dir, image_names{test_id}, "_", method,'_segmentated_image.png'));
        end
    end
end

function [accuracy, overlap, dice_score, centroids_euclid_distance ] = evaluate_segmentation_image(segmentation_mask, gt_mask)
    %%%% Function evaluates metrics of segmentation
    % Evaluate confusion matrix
    [TP, FP, TN, FN] = evaluate_confusion_matrix(segmentation_mask, gt_mask);
    % Evaluate metrics
    accuracy = (TP + TN) / (TP + FP + TN + FN);
    overlap = TP /(TP + FN + FP);
    dice_score = (2 * TP) / ( (2 * TP) + FN + FP);
    % Evaluate distance of centoids
    seg_mask_region_props = regionprops(segmentation_mask, 'centroid');
    gt_mask_region_props = regionprops(gt_mask, 'centroid');
    if length(seg_mask_region_props) ~= 1
        centroids_euclid_distance = max(size(segmentation_mask));
    else
        centroids_euclid_distance = sqrt(sum((seg_mask_region_props.Centroid - gt_mask_region_props.Centroid) .^ 2));
    end
end
function [TP, FP, TN, FN] = evaluate_confusion_matrix(segmentation_mask, gt_mask)
    %%%% Function evaluate confusion matrix
        % Sumury image
        sum_of_masks = segmentation_mask + gt_mask;         
        % Substract image
        substraction_of_masks = segmentation_mask - gt_mask;
        % Count pixels
        TP = sum(sum_of_masks(:) == 2);
        FP = sum(substraction_of_masks(:) == 1);
        TN = sum(sum_of_masks(:) == 0);
        FN = sum(substraction_of_masks(:) == -1);                                                                                   
end

function [ segmentation_mask ] = segment_image(experiment_metadata, fold_best_params, test_id)
    %%%% Function segments image with specific method
    switch experiment_metadata.method
        case "MorphBatEllipse"
            [ segmentation_mask ] =  BatAlgoMethod(experiment_metadata, fold_best_params, test_id);
        case "ThreshMorph"
            [ segmentation_mask ] =  ThreshMorphMethod(experiment_metadata, fold_best_params, test_id);
        case "RegionGrow"
            [ segmentation_mask ] =  RegionGrowMethod(experiment_metadata, fold_best_params, test_id);
        case "HoughCircle"
            [ segmentation_mask ] =  HoughCircleMethod(experiment_metadata, fold_best_params, test_id);
        case "MaxLinRotHoughCircle"
            [ segmentation_mask ] =  MaxLinRotHoughCircleMethod(experiment_metadata, fold_best_params, test_id);
    end
end

function [gt_mask] = load_gt_mask(experiment_metadata, image_id)
    % Function loads ground truth mask
    image_name = experiment_metadata.data_metadata.image_names(image_id);
    gt_mask = logical(imread(append(experiment_metadata.project_paths.ground_truth_dir, 'groundTruth_',  image_name{1}, '.png')));
end
