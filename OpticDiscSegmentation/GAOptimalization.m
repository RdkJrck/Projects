%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne


function [ best_solutions_parameters, best_cost_generation_values ] = GAOptimalization(experiment_metadata)
%%%% Function optimize method via genetic algorithm
%%
%%  :param experiment_metadata: structure with project metadata
%%  :return best_solutions_parameters: cell with parameters of best individual of all
%%  :return best_cost_generation_values: best individual cost value from each generation

    % Load needed information from metadata
    cross_val_fold_number = experiment_metadata.cross_val_fold_number;

    % Allocate space for outputs
    [ best_solutions_parameters, best_cost_generation_values ] = deal(cell([cross_val_fold_number 1]));
    
    % Initialize starting population
    [start_best_individual, start_population] = create_population(experiment_metadata.ga_config, experiment_metadata.method);
    disp("Created fixed starting population for all folds ");    

    
    disp("START OF GA ALGORITHM");
    % For each testing fold find best solution parameters on images from remaining of folds
    for fold_ind = 1:cross_val_fold_number
        disp(append("START OF FOLD ", num2str(fold_ind)));
        % Run genetic algorithm to find best parameters for selected method
        [ best_solutions_parameters{fold_ind}, best_cost_generation_values{fold_ind}] = run_ga_on_fold(experiment_metadata, start_best_individual, start_population, fold_ind);
        disp(append("END OF FOLD ", num2str(fold_ind)));
    end
end


function [best_individual_params, generation_best_cost_vector] = run_ga_on_fold(experiment_metadata, start_best_individual, start_population, fold_ind)
    %%%% Function runs Genetic algorithm on each test fold
    %%  :param experiment_metadata: structure with project metadata
    %%  :param start_best_individual: best individual in start population
    %%  :param start_population: start population
    %%  :param fold_ind: number of fold
    %%  :return best_solutions_parameters: cell with parameters of best individual of all
    %%  :return best_cost_generation_values: best individual cost value from each generation
    % Get GA configuration    
    ga_config = experiment_metadata.ga_config;

    % Get utils class for parameter conversion
    utils = UtilsClass();
   
    % Evaluate starting population
    disp("Evaluate starting population")
    [best_individual, population] = evaluate_population(experiment_metadata, fold_ind, start_best_individual, start_population);

    % Initialize best cost value for each generation
    generation_best_cost_vector = nan(1, ga_config.Generations);
    
    % Generation loop
    for generation_id = 1:ga_config.Generations
        
        disp(append("Start of generation ", num2str(generation_id)));
        % Get probabilities for roulette crossover
        population_probs = get_individual_probs(ga_config, population);
        
        disp(append("Generate offspring ", num2str(generation_id)));
        
        % Create offspring
        offspring_population = create_offspring(ga_config, population, population_probs);
        disp(append("Mutate offspring ", num2str(generation_id)));
        
        % Mutate offspring
        offspring_population = mutate_offspring(ga_config, offspring_population);
                
        disp(append("Evaluate offspring ", num2str(generation_id)));
        disp(append("Best individual before evaluation has cost value: ", num2str(best_individual.cost_value)));
        
        % Evaluate offspring
        [best_individual offspring_population] = evaluate_population(experiment_metadata, fold_ind, best_individual, offspring_population);

        % Merge parents and offspring and remove weak
        population = create_new_generation(population, offspring_population);
        
        % Save best cost from this generation
        generation_best_cost_vector(generation_id) = best_individual.cost_value;

        disp(['Generation ' num2str(generation_id) ' end, best cost is ' num2str(generation_best_cost_vector(generation_id))]);
    end
    
    % Convert found solution params from normalized to parametrized space 
    best_individual_params = utils.norm2para(ga_config, best_individual.params);
end

function [ best_individual, population ] = create_population(ga_config, method)
    %%%% Function creats population for specific method
    % Initialize best solution starting value
    best_individual = struct();
    best_individual.params = [];
    best_individual.cost_value = -inf;

    population = repmat(struct(), ga_config.nPop, 1);

    for i = 1:ga_config.nPop
        % IF ITS FIRST INDIVIDUAL
        if i == 1 
            % FIRST INDIVIDUAL IS X0
            population(i).params = ga_config.x0;
        else
            % GENERATE RANDOM SOLUTION
            population(i).params = generate_params(ga_config, method);
        end
    end
end

function [ new_params ] = generate_params(ga_config, method);
    %%%% Function generates intial population for specific method
    new_params = rand(ga_config.VarSize);
    % Sort specific params
    switch method
        case "MorphBatEllipse"
            new_params(1:2) = sort(new_params(1:2));
            new_params(3:4) = sort(new_params(3:4));
         case "ThreshMorph"
             new_params(1:2) = sort(new_params(1:2));
         case "RegionGrow"
             new_params(1:2) = sort(new_params(1:2));
             new_params(4:5) = sort(new_params(4:5));
        case "HoughCircle"
            new_params(2:3) = sort(new_params(2:3));
        case "MaxLinRotHoughCircle"
            new_params(1:2) = sort(new_params(1:2));
            new_params(5:6) = sort(new_params(3:4));
    end
end

function [ population_probs ] = get_individual_probs(ga_config, population)
    %%%% Function computes probability of each individual in population
        population_cost_vect = [population.cost_value];
        population_cost_avg = mean(population_cost_vect);
        % Scale cost vector
        if population_cost_avg ~= 0
            population_cost_vect = population_cost_vect / population_cost_avg;
        end
        % Compute probability
        population_probs = exp(ga_config.beta * population_cost_vect);
end

function [ offspring_population ] = create_offspring(ga_config, population, population_probs)
    %%%% Function selects parrent via roulette wheel and generates offsprings via uniform crossover
    % Initialize Offspring Population
    offspring_population = repmat(struct(), ga_config.nC / 2, 2);

    % CROSSOVER
    for k = 1:ga_config.nC / 2
        
        % Roulette Wheel Parent Selection
        p1_ind = find(rand*sum(population_probs) <= cumsum(population_probs), 1, 'first');
        p2_ind = find(rand*sum(population_probs) <= cumsum(population_probs), 1, 'first');
        p1 = population(p1_ind);
        p2 = population(p2_ind);

        % PERFORM CROSSOVER
        alpha = rand( size(p1.params));
        offspring_population(k, 1).params = alpha .* p1.params + (1 - alpha) .* p2.params;
        offspring_population(k, 2).params = alpha .* p2.params + (1 - alpha) .* p1.params;
    end
    
    % Flatten offspring dual columns into single vector of individuals
    offspring_population = offspring_population(:);
end

function [ best_individual, population ] = evaluate_population(experiment_metadata, fold_ind, best_individual, population)
    %%%% Function evaluate population
    for i = 1:size(population,1)
        population(i).cost_value = cost_function(experiment_metadata, fold_ind, population(i).params);
        disp(append("Invidual ", num2str(i), " has current evaluated cost ", num2str(population(i).cost_value)));        
        if population(i).cost_value > best_individual.cost_value
            disp("And is better than current best");
            best_individual = population(i);
        end
    end
end 

function [cost_value] = cost_function(experiment_metadata, fold_ind, params)
    %%%% Function handles cost function for each method
    % READ PROJECT INFO
    method = experiment_metadata.method;
    ga_config = experiment_metadata.ga_config;
    fold_train_ids = experiment_metadata.data_metadata.train_ids_per_fold(fold_ind, :);
    fold_train_ids(fold_train_ids == 0) = [];

    % CONVERT PARA
    utils = UtilsClass;
    params = utils.norm2para(ga_config, params);
    % Generate score matrix
    score = zeros([length(fold_train_ids) 1]);
    fold_results = repmat(struct(), length(fold_train_ids), 1);
    
    for ind = 1:length(fold_train_ids)

        train_id = fold_train_ids(ind);

        switch method
            case 'MorphBatEllipse'
                [ segmented_mask ] = BatAlgoMethod(experiment_metadata, params, train_id);
            case 'ThreshMorph'
                [ segmented_mask ] = ThreshMorphMethod(experiment_metadata, params, train_id);
            case "RegionGrow"
                [ segmented_mask ] = RegionGrowMethod(experiment_metadata, params, train_id);
            case "HoughCircle"
                [ segmented_mask ] = HoughCircleMethod(experiment_metadata, params, train_id);
            case "MaxLinRotHoughCircle"
                [ segmented_mask ] = MaxLinRotHoughCircleMethod(experiment_metadata, params, train_id);
        end
        % Get ground truth mask for specific dataset
        [gt_mask] = load_gt_mask(experiment_metadata, train_id);
        sum_of_masks = segmented_mask + gt_mask;          
        substraction_of_masks = segmented_mask - gt_mask;
                                                                                                
        % CALCULATE REGION SIZE
        TP = sum(sum_of_masks(:) == 2);
        FN = sum(substraction_of_masks(:) == -1);                                                                                          
        FP = sum(substraction_of_masks(:) == 1);
                                                                                                   
        % CALCULATE SEGMENTATION MATRICES 
        score(ind) = TP /(TP + FN + FP);  
    end
    % Cost value - mean of overleap
    cost_value = mean(score(:));
end

function [gt_mask] = load_gt_mask(experiment_metadata, image_id)
    %%%% Funkcion reads ground truth mask
    image_name = experiment_metadata.data_metadata.image_names(image_id);
    ground_truth_dir = experiment_metadata.project_paths.ground_truth_dir;
    gt_mask = logical(imread(append(ground_truth_dir, 'groundTruth_',  image_name{1}, '.png')));
end


function [ offspring_population ] = mutate_offspring(ga_config, offspring_population)
    %%%% Function performs mulation of offspring
    for ind = 1:ga_config.nC     
        mutated_invididual_params = offspring_population(ind).params;
        % PERFORM MUTATION
        flag = (rand(size(mutated_invididual_params)) < ga_config.mu);
        r = randn(size(mutated_invididual_params));
        offspring_population(ind).params(flag) = mutated_invididual_params(flag) + ga_config.mu + ga_config.sigma * r(flag);

        % CHECK SPACE BOUNDARIES
        offspring_population(ind).params(offspring_population(ind).params < 0) = 0;
        offspring_population(ind).params(offspring_population(ind).params > 1) = 1;
    end

end

function [ new_population ] = create_new_generation(population, offspring_population)
    %%%% Function generates new generation
    % MERGE POPULATION
    merged_population = [population; offspring_population];
    
    % SORT POPULATION
    [~, sorted_indices] = sort([merged_population.cost_value], 'descend');
    sorted_population = merged_population(sorted_indices);
  
    % REMOVE EXTRA INDIVIDUALS
    new_population = sorted_population(1:length(population));     
end

