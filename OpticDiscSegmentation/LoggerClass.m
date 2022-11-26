%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : DOPLNIT
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne


classdef LoggerClass
%%%% Class LoggerClass
%%  Class responsible for saving results into files.

    properties
        training_log_fold_ids_column
        training_log_header
        training_log_filename
        solution_params_filename
        test_metrics_filename
        image_names
    end
    
    methods
        function logger = LoggerClass(experiment_metadata)
        %%%% Class constructor
        %%  Initializes object attributes and returns class object.
        %%
        %%  :param experiment_metadata: structure with project metadata
        %%  :return logger: instance of class LoggerClass
            
            % Load needed information from metadata
            method = experiment_metadata.method;
            cross_val_fold_number = experiment_metadata.cross_val_fold_number;
            project_paths = experiment_metadata.project_paths;
            
            % Create training log fold column
            logger.training_log_fold_ids_column = [num2str([1:cross_val_fold_number]'); "Mean"];
            
            % Create training log header
            logger.training_log_header = "FoldId";
            for i = 1:experiment_metadata.ga_config.Generations
                logger.training_log_header(i + 1) = "Generation " + num2str(i);
            end
            
            % Prepare filepaths for results
            logger.training_log_filename = [ project_paths.results_dir method '_train_log.csv'];
            logger.solution_params_filename = [ project_paths.results_dir method '_found_solution_parameters.csv'];
            logger.test_metrics_filename = [ project_paths.results_dir method '_test_metrics.csv'];
            
            % Have image names
            logger.image_names = experiment_metadata.data_metadata.image_names;

            % Write test indexes
            writematrix(experiment_metadata.data_metadata.test_ids_per_fold,[ project_paths.results_dir method '_test_ids.csv']);

        end

        function [ ] = save_training_log(self, best_cost_generation_values)
        %%%% Function save_training_log
        %%  Saves GA training log of best cost per generation.
        %%
        %%  :param best_cost_generation_values: best individual cost value from each generation

            best_cost_generation_values = cell2mat(best_cost_generation_values);
            best_cost_generation_values(end + 1, :) = mean(best_cost_generation_values);
            generation_best_cost_values_arr = [self.training_log_fold_ids_column, best_cost_generation_values];
            
            training_log_cost_table = splitvars(table(generation_best_cost_values_arr));
            training_log_cost_table.Properties.VariableNames = self.training_log_header';
            writetable(training_log_cost_table, self.training_log_filename, 'Delimiter', ',', 'QuoteStrings', true);

        end

        function [ ] = save_found_solution_params(self, solutions_params)
            %%%% Function save_found_solution_params
            %%  Saves solution parameters.
            %%
            %%  :param solutions_params: cell that stores parameters

            writecell(solutions_params, self.solution_params_filename, 'Delimiter', ',');
        
        end

        function [ ] = save_test_metrics(self, segmentation_test_metrics)
        %%%% Function save_test_metrics
        %%  Saves performance metrics from evaluation of best solutions on their respective test folds ids.
        %%
        %%  :param segmentation_test_metrics: best found solution performance metrics

            % Create image name column     
            ImageName = [];
            FoldId = [];
            for image_id = 1:size(segmentation_test_metrics, 1)
                 FoldId = [FoldId; segmentation_test_metrics(image_id, 1)];
                 ImageName = [ImageName; string(self.image_names{image_id})];
            end
            
            
            % Compute means of metrics across test folds            
            segmentation_test_metrics = segmentation_test_metrics(:, 2:end);
            segmentation_test_metrics(end + 1, :) = mean(segmentation_test_metrics);
            segmentation_test_metrics(end + 1, :) = median(segmentation_test_metrics(1:end - 1, :));
            segmentation_test_metrics(end + 1, :) = std(segmentation_test_metrics(1:end - 2, :));
            
            % Create table metric columns
            FoldId = [FoldId; "-"; "-"; "-"];
            ImageName = [ImageName; "Mean"; "Median"; "STD"];
            Accuracy = round(segmentation_test_metrics(:,1), 3);
            Overlap = round(segmentation_test_metrics(:,2), 3);
            DiceScore = round(segmentation_test_metrics(:,3), 3);
            CentroidEuDist = round(segmentation_test_metrics(:,4), 3);
            MethodTime = round(segmentation_test_metrics(:,5), 3);
            % Make results table
            test_results_table = table(FoldId, ImageName, Accuracy, Overlap,DiceScore, CentroidEuDist, MethodTime);
            % Write test results table into csv file
            writetable(test_results_table, self.test_metrics_filename, 'Delimiter', ',', 'QuoteStrings', true);
    
        end
    end
end
%             % Store parametrs
%             switch method
%                 case "MorphBatEllipse"
%                     HistogramDolniPrah = round(segmentation_test_metrics(:,6), 3);
%                     HistogramHorniPrah = round(segmentation_test_metrics(:,7), 3);
%                     MorfologieSporniLimit = round(segmentation_test_metrics(:,8), 3);
%                     MorfologieHorniLimit = round(segmentation_test_metrics(:,9), 3);
%                     MorfologieKrok = round(segmentation_test_metrics(:,10), 3);
%                     test_results_table = table(FoldId, ImageName, Accuracy, Overlap,...
%                         DiceScore, CentroidEuDist, MethodTime,HistogramDolniPrah,HistogramHorniPrah,...
%                         MorfologieSporniLimit,MorfologieHorniLimit,MorfologieKrok);
%                 case "ThreshMorph"
%                     PrumerovaciMaska = round(segmentation_test_metrics(:,6), 3);
%                     MedianFiltr = round(segmentation_test_metrics(:,7), 3);
%                     Prah = round(segmentation_test_metrics(:,8), 3);
%                     RadiusOtevreni = round(segmentation_test_metrics(:,9), 3);
%                     FiltrovanaPlocha = round(segmentation_test_metrics(:,10), 3);
%                     test_results_table = table(FoldId, ImageName, Accuracy, Overlap,...
%                     DiceScore, CentroidEuDist, MethodTime, PrumerovaciMaska,MedianFiltr,...
%                      Prah,RadiusOtevreni,FiltrovanaPlocha); 
%                 case "RegionGrow"
%                     HistogramDolniPrah = round(segmentation_test_metrics(:,6), 3);
%                     HistogramHorniPrah = round(segmentation_test_metrics(:,7), 3);
%                     VahaAdaptivnihoPrahu = round(segmentation_test_metrics(:,8), 3);
%                     MorfologieSporni = round(segmentation_test_metrics(:,9), 3);
%                     MorfologieHorni= round(segmentation_test_metrics(:,10), 3);
%                     MorfologieKrok = round(segmentation_test_metrics(:,11), 3);
%                     test_results_table = table(FoldId, ImageName, Accuracy, Overlap,...
%                     DiceScore, CentroidEuDist, MethodTime, HistogramDolniPrah,HistogramHorniPrah,...
%                      VahaAdaptivnihoPrahu,MorfologieSporni,MorfologieHorni,MorfologieKrok); 
%                 case "HoughCircle"
%                      CannySigma = round(segmentation_test_metrics(:,6), 3);
%                      SpodniRadius = round(segmentation_test_metrics(:,7), 3);
%                      HorniRadius = round(segmentation_test_metrics(:,8), 3);
%                      KrokRadia = round(segmentation_test_metrics(:,9), 3);
%                      test_results_table = table(FoldId, ImageName, Accuracy, Overlap,...
%                     DiceScore, CentroidEuDist, MethodTime, CannySigma,SpodniRadius,...
%                      HorniRadius,KrokRadia); 
%                 case "MaxLinRotHoughCircle"
%                     HistogramDolniPrah = round(segmentation_test_metrics(:,6), 3);
%                     HistogramHorniPrah = round(segmentation_test_metrics(:,7), 3);
%                     DelkaOperatoru = round(segmentation_test_metrics(:,8), 3);
%                     CannySigma = round(segmentation_test_metrics(:,9), 3);
%                     SpodniRadius = round(segmentation_test_metrics(:,10), 3);
%                     HorniRadius = round(segmentation_test_metrics(:,11), 3);
%                     KrokRadia = round(segmentation_test_metrics(:,12), 3);
%                     test_results_table = table(FoldId, ImageName, Accuracy, Overlap,...
%                     DiceScore, CentroidEuDist, MethodTime, HistogramDolniPrah,HistogramHorniPrah,...
%                     DelkaOperatoru,CannySigma,SpodniRadius,HorniRadius,KrokRadia); 
%             end