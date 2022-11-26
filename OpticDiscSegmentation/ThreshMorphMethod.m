%%%%       Bakalarska práce - Segmentace optickeho disku v obrazových datech sitnice
%%%%        Autor prace : Radek Juracek
%%%%        Vedouci prace : Ing. Jan Odstrcilik, Ph.D.
%%%%        Datum odevzdani : 27.5.2022
%%%%        Ustav : Ustav biomedicinského inženyrstvi
%%%%        Fakulta : Fakulta elektrotechniky a kominikacnich technologii
%%%%        Vysoke uceni technicke v Brne

function [ final_segmentated_mask ] = ThreshMorphMethod(experiment_metadata, method_params, image_id)
    %%%% Function ThreshMorphMethod
    %%%% Segments image by tresholding and morfological opening
    %%%% 
    %%%% :param experiment_metadata: struct experiment metadata
    %%%% :param params: vector of parametrs
    %%%% :param ind: index of segmented image

    image_name = experiment_metadata.data_metadata.image_names{image_id};
    dataset_mask = experiment_metadata.data_metadata.dataset_mask;
    preprocessed_dir = experiment_metadata.project_paths.preprocessed_dir;

    % Get each optimized parameter from params vector

    avg_filter_size = method_params(1);
    med_filter_size = method_params(2);
    treshold = method_params(3);
    open_radius = method_params(4);
    filter_area = method_params(5);
    
    % Read preprocessed image
    image_filepath = append(preprocessed_dir, image_name, '_preprocessed_image.png');
    preprocessed_image = imread(image_filepath);

    % Average filtering
    avg_mask = ones([avg_filter_size avg_filter_size]) ./ avg_filter_size^2;
    avg_filt_image = imfilter(preprocessed_image, avg_mask);

    % Median filtering
    med_filt_image = medfilt2(avg_filt_image, [med_filter_size med_filter_size]);

    % Tresholding
    binary_image = imbinarize(med_filt_image, treshold );

    % Morfological open on binary
    open_image = imopen(binary_image, strel('disk', open_radius, 0));

    % Filter blob in binary image by size of area
	filt_by_area_image = bwareaopen(open_image, filter_area);

    % Apply ConvexHull
	final_segmentated_mask = bwconvhull(filt_by_area_image);
end

