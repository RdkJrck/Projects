%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

    % Run script to show results
    clear all 
    clc
    results = append(pwd,'\results\');
    path.gt = 'ground_truth_images\';
    path.preproc = 'preprocessed_images\';
    path.seg = 'preprocessed_images\';
    % File subfix struct
    sub.test = '_test_metrics.csv';
    sub.sol = '_found_solution_parameters.csv';
    sub.train = '_train_log.csv';
    % Methods 
    methods = {'ThreshMorph', 'HoughCircle','MaxLinRotHoughCircle','RegionGrow','MorphBatEllipse'} ;
    methods_czech = {'Prahování', 'Hough','Morfologie a Hough','NarůstáníOblasti','Netopýří algoritmus'} ;
    % Datasets
    datasets = { 'HRF_ALL\', 'STUDY_01\', 'STUDY_02\'};
    % Number of optimalized variable
    nVar = [5 4 7 6 5];
    % Alocate Training solution matrix
    train_sol = zeros([5 11 length(methods) length(datasets) ]);
    % Define row of AVG (depends on number of folds)
    row_of_avg = 6;
    
    for meth_ind = 1:length(methods)
        for data_ind = 1:length(datasets)
            clear train_log
            % Read training log
            train_log = readmatrix(append(results, datasets{data_ind},methods{meth_ind},sub.train));
            % Get AVG of training log
            train_log_avg(:,meth_ind,data_ind) = train_log(row_of_avg,2:end);
            % Read training solution matrix
            temp = readmatrix(append(results,datasets{data_ind},methods{meth_ind},sub.sol));
            [rows cols] = size(temp);
            train_sol(1:rows,1:cols,meth_ind,data_ind) = round(temp,3);
            % Read test metrics matrix
            test_mat(:,:,meth_ind,data_ind) = readmatrix(append(results,datasets{data_ind},methods{meth_ind},sub.test));

            % Calculate metrics of each fold
            for fold_ind = 1:size(train_sol,1)
                % Store mean of OL for each fold
                train_sol(fold_ind, nVar(meth_ind)+1,meth_ind,data_ind) = round(mean(test_mat(test_mat(:,1,meth_ind,data_ind) == fold_ind,4,meth_ind,data_ind)),3);
                % Store std of OL for each fold
                train_sol(fold_ind,nVar(meth_ind)+2,meth_ind,data_ind) = round(std(test_mat(test_mat(:,1,meth_ind,data_ind) == fold_ind,4,meth_ind,data_ind)),3);
                % Store median of OL for each fold
                train_sol(fold_ind,nVar(meth_ind)+3,meth_ind,data_ind) = round(median(test_mat(test_mat(:,1,meth_ind,data_ind) == fold_ind,4,meth_ind,data_ind)),3);
                % Store mean time of each fold
                train_sol(fold_ind,nVar(meth_ind)+4,meth_ind,data_ind) = round(mean(test_mat(test_mat(:,1,meth_ind,data_ind) == fold_ind,7,meth_ind,data_ind)),3);
            end
            % Store params and metrics of each fold
            writematrix(train_sol(:,1:nVar(meth_ind)+4,meth_ind,data_ind),append(results,datasets{data_ind},methods{meth_ind},sub.sol));
        end
    end
    % Ploting results 
    
    % Define size of figure subplot
    m = 3;
    n = 2;
    col = 5;
    % Plot figure
    figure('Name','Segmentation results','NumberTitle','off');

    subplot(m,n,1)
    % Images HRF
    set = 1;
    boxplot_mat = [test_mat(:,col,1,set) test_mat(:,col,2,set) test_mat(:,col,3,set) test_mat(:,col,4,set) test_mat(:,col,5,set) ];
    boxplot(boxplot_mat,'Notch','on','Labels',methods_czech)
    %title('Uspěšnost metod na HRF datasetu')
    ylabel('DICE[-]')
    subplot(m,n,2)
    % Plot HRF training
    plot(train_log_avg(:,1,set),'DisplayName','ThreshMorph')
    hold on 
    plot(train_log_avg(:,2,set),'DisplayName','HoughCircle')
    plot(train_log_avg(:,3,set),'DisplayName','MaxLinRotHoughCircle')
	plot(train_log_avg(:,4,set),'DisplayName','RegionGrow')
    plot(train_log_avg(:,5,set),'DisplayName','MorphBatEllipse')
    hold off
   % title('Průběh trenovaní jednotllivých metod na HRF')
    xlabel('Počet iterací genetickeho algoritmu')
    ylabel('Překryv [-]')
    legend('Location','southeast')

    subplot(m,n,3)
    % Images STUDY01
    set = 2;
    boxplot_mat = [test_mat(:,col,1,set) test_mat(:,col,2,set) test_mat(:,col,3,set) test_mat(:,col,4,set) test_mat(:,col,5,set) ];
    boxplot(boxplot_mat,'Notch','on','Labels',methods_czech)
   % title('Uspěšnost metod na STUDY 1 datasetu')
    ylabel('DICE[-]')
    subplot(m,n,4)
    % Plot STUDY01 training
    plot(train_log_avg(:,1,set),'DisplayName','ThreshMorph')
    hold on 
    plot(train_log_avg(:,2,set),'DisplayName','HoughCircle')
    plot(train_log_avg(:,3,set),'DisplayName','MaxLinRotHoughCircle')
	plot(train_log_avg(:,4,set),'DisplayName','RegionGrow')
    plot(train_log_avg(:,5,set),'DisplayName','MorphBatEllipse')
    hold off
   % title('Průběh trenovaní jednotllivých metod na STUDY 1')
    xlabel('Počet iterací genetickeho algoritmu')
    ylabel('Překryv [-]')
    legend('Location','southeast')

    subplot(m,n,5)
    % Images STUDY02
    set = 3;
    boxplot_mat = [test_mat(:,col,1,set) test_mat(:,col,2,set) test_mat(:,col,3,set) test_mat(:,col,4,set) test_mat(:,col,5,set) ];
    boxplot(boxplot_mat,'Notch','on','Labels',methods_czech)
   % title('Uspěšnost metod na STUDY 2 datasetu')
    ylabel('DICE[-]')
    subplot(m,n,6)
    % Plot STUDY02 training
    plot(train_log_avg(:,1,set),'DisplayName','ThreshMorph')
    hold on 
    plot(train_log_avg(:,2,set),'DisplayName','HoughCircle')
    plot(train_log_avg(:,3,set),'DisplayName','MaxLinRotHoughCircle')
	plot(train_log_avg(:,4,set),'DisplayName','RegionGrow')
    plot(train_log_avg(:,5,set),'DisplayName','MorphBatEllipse')
    hold off
    %title('Průběh trenovaní jednotllivých metod na STUDY 2')
    xlabel('Počet iterací genetickeho algoritmu')
    ylabel('Překryv [-]')
    legend('Location','southeast')
