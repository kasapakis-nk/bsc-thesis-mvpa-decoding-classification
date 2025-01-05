home_dir = 'C:/Users/User/Desktop/HCP_WM_Datasets_2C';

% Extract subjects list into output: "subj_list".
subj_dir_files = dir([home_dir '/fmri']);
subj_dir_files_count = numel(subj_dir_files);
subj_list = cell(1,subj_dir_files_count);
subj_count=0;

for flag=1:subj_dir_files_count
    % Condition for subj_dir_file to be a valid subj folder.
    % Checks if it contains any number in its name.
    subj_condition = (numel(regexp(subj_dir_files(flag).name,'\w\d'))~=0);    
    if subj_condition
        subj_list(subj_count + 1) = {subj_dir_files(flag).name};
        subj_count = subj_count + 1;
    end
end
subj_list = subj_list(~cellfun(@isempty,subj_list) == 1);

% Outlier Subjects
subj_list(2) = [];
%subj_list(19) = [];

selected_copes = 1:4;
selected_runs = {'LR' 'RL'};

labels_dict  = dictionary( 1, 'Body'  , ...
                           2, 'Face'  , ...
                           3, 'Place' , ...
                           4, 'Tool' );

targets_dict = dictionary( 1, 1  , ...
                           2, 2  , ...
                           3, 3  , ...
                           4, 4 );

chunks_dict  = dictionary( 1, 1  , ... %chunk 1 is LR
                           2, 1  , ... %chunk 2 is RL
                           3, 1  , ... 
                           4, 1 );     

% End persistent variables.


chosen_subj_count = 1:19;
fold_count = 49;

acc_mat = zeros(numel(chosen_subj_count),1);
std_mat = zeros(numel(chosen_subj_count),1);
final_mat = zeros(numel(chosen_subj_count),4);
box_plot_accs_per_subj_count = zeros(fold_count,numel(chosen_subj_count));
for i = 1:numel(chosen_subj_count)

    clearvars -except home_dir subj_list box_plot_accs_per_subj_count selected_copes acc_mat std_mat selected_runs labels_dict targets_dict chunks_dict final_mat chosen_subj_count i

    % Extract and add .sa to each cope.
    selected_cope_count = numel(selected_copes);
    run_count = numel(selected_runs);
    cope_storage = cell((selected_cope_count*run_count),1);
    cope_total_count = 0;

    % Go through all subjects.
    chunks_count = 0;
    subj_count = chosen_subj_count(i);
    for subj_id = 1:subj_count
        tic_time = tic;
        run_increment = 0;
        % Go through all chosen runs.
        for run_id = 1:run_count
            % Go through all chosen copes.
            for flag = 1:selected_cope_count
                cope_id = selected_copes(flag);
                % Read specific cope file.
                runspec = cell2mat(['/fmri/' subj_list(subj_id) '/tfMRI_WM_' selected_runs(run_id) '_analyzed.feat/stats']);
                filespec = ['/cope' num2str(cope_id) '.nii.gz'];
                ds_temp = cosmo_fmri_dataset( [home_dir runspec filespec] );

                % Set the sample attributes for chosen cope.
                ds_temp.sa.targets = targets_dict(cope_id);
                ds_temp.sa.labels  = labels_dict(cope_id);
                ds_temp.sa.chunks  = chunks_dict(cope_id) + run_increment + chunks_count;

                % Store data from each cope, seperately, in storage matrix.
                cope_storage{cope_total_count + 1} = ds_temp;
                cope_total_count = cope_total_count + 1;
            end
            run_increment = run_increment + 1;
        end
        chunks_count = chunks_count + run_count;
    end

    % Concatenate cope's into final dataset.
    ds = cosmo_stack(cope_storage(1:cope_total_count));

    % Read mask, apply it, remove 0s and display masked ds.
    ppa_msk = cosmo_fmri_dataset([ home_dir '/ppa_msk.nii' ]);
    msk_indeces = find(ppa_msk.samples);
    msk_ds = cosmo_slice(ds,msk_indeces,2);
    msk_ds = cosmo_remove_useless_data(msk_ds);

    % Partition different targets into different ds.
    target_count = numel(unique(msk_ds.sa.targets));
    targets_ds_storage = cell(target_count,1);

    for target_id = 1:target_count
        target_msk = msk_ds.sa.targets == target_id;
        targets_ds_storage{target_id} = cosmo_slice(msk_ds,target_msk,1);
    end


    test_ratio = 0.2;
    if subj_count == 1
        continue
        %fold_count = 2;
    elseif subj_count == 2
        test_ratio = 0.25;
        fold_count = 4;
    elseif subj_count == 3
        test_ratio = 0.34;
        fold_count = 15;
    elseif subj_count == 4
        fold_count = 28;
    elseif subj_count == 5
        fold_count = 45;
    else
        fold_count = 49; %optimal fold_count 49
    end
    max_fold_count = 200;

    partitions_storage = cell(target_count,1);
    for target_id = 1:target_count
        ds_temp = targets_ds_storage{target_id};
        samples_per_target = numel(ds_temp.samples(:,1));
        test_count = test_ratio * samples_per_target;
        train_count = (1 - test_ratio) * samples_per_target;
        partitions_storage{target_id} = cosmo_independent_samples_partitioner(ds_temp, ...
            'fold_count', fold_count, ...
            'test_ratio', test_ratio, ...
            'max_fold_count', max_fold_count);
        assert(isequal(cosmo_check_partitions(partitions_storage{target_id},ds_temp),1))
    end

    % OUTPUT: chunk_partitions_storage 4x1 cell array.
    % Each cell has a struct with 2 attributes each.
    % Each .train_indices is a 1xfold_count cell array.
    % Each cell contains train_count numbers, indicating training chunks.
    % Each .test_indices is a 1xfold_count cell array.
    % Each cell contains test_count numbers, indicating test chunks.

    pred_libsvm = cell(fold_count, 1);
    pred_libsvm_logical =  cell(fold_count,1);
    acc_libsvm_per_fold = zeros(fold_count,1);
    train_ds_temp = cell(4,1);
    test_ds_temp  = cell(4,1);

    % Performing classification for all folds.
    for fold_id = 1:fold_count
        % Slicing target_only_ test_ds and train_ds based on partitions.
        for target_id=1:target_count
            train_ds_temp{target_id} = cosmo_slice(  targets_ds_storage{target_id}, ...
                partitions_storage{target_id}.train_indices{fold_id} );
            test_ds_temp{target_id}  = cosmo_slice(  targets_ds_storage{target_id}, ...
                partitions_storage{target_id}.test_indices{fold_id}  );
        end

        % Concatenating into final train_ds and test_ds.
        train_ds = cosmo_stack(train_ds_temp(1:target_count));
        train_samples = train_ds.samples;
        train_targets = train_ds.sa.targets;

        test_ds = cosmo_stack(test_ds_temp(1:target_count));
        test_samples = test_ds.samples;
        expected_targets = test_ds.sa.targets;

        % Train classifier and make predictions for each partition.
        pred_libsvm{fold_id} = cosmo_classify_libsvm(train_samples,train_targets,test_samples);
        pred_libsvm_logical{fold_id} = pred_libsvm{fold_id} == expected_targets;

        % Accuracy Data.
        acc_libsvm_per_fold(fold_id) = sum(pred_libsvm_logical{fold_id} / numel(pred_libsvm_logical{fold_id}));

        box_plot_accs_per_subj_count(fold_id,subj_count) = acc_libsvm_per_fold(fold_id);
    end

    % Display accuracy.
    acc_libsvm_mean = sum(acc_libsvm_per_fold)/fold_count;
    std_libsvm = std(acc_libsvm_per_fold,1);

    acc_mat(i,1) = acc_libsvm_mean * 100;
    std_mat(i,1) = std_libsvm * 100;

    final_mat(i,1) = subj_count;
    final_mat(i,2) = fold_count;
    final_mat(i,3) = acc_libsvm_mean;
    final_mat(i,4) = std_libsvm;
    final_mat(i,5) = toc(tic_time);

    disp([num2str(i) '/' num2str(numel(chosen_subj_count)) ' completed.' newline])
end

disp(['fold_count fold_count acc_mean std analysis_time' newline])
for j=1:numel(chosen_subj_count)
    disp([num2str(final_mat(j,1)) ' ' num2str(final_mat(j,2)) ' ' num2str([num2str((final_mat(j,3) * 100),3) '%']) ' ' num2str([num2str((final_mat(j,4) * 100),3) '%']) ' ' num2str([num2str(final_mat(j,5),2) 's']) newline ])
end

acc_avg_over_analyses = sum(final_mat(2:numel(chosen_subj_count),3)) / (numel(chosen_subj_count)-1);
disp(['Average accuracy over ' num2str(numel(chosen_subj_count)) ' analyses was ' num2str([num2str((acc_avg_over_analyses * 100),3) '%']) '.'])

% Data Storage
column_labels = {'subj_count' 'fold_count' 'acc_mean' 'std' 'analysis_time (s)'};

sunj_count_col_labels = cell(1,19);
for k = 1:19
    sunj_count_col_labels(1,k) = {['sub_count_' num2str(k)]};
end

writecell(sunj_count_col_labels,'classif_res_ppa.xlsx','Sheet','2C_box_subj_count','Range','A1')
writematrix(box_plot_accs_per_subj_count,'classif_res_ppa.xlsx','Sheet','2C_box_subj_count','Range','A2')

writecell(column_labels,'classif_res_ppa.xlsx','Sheet','2C_subj_count','Range','A1:E1')
writematrix(final_mat,'classif_res_ppa.xlsx','Sheet','2C_subj_count','Range','A2')
writematrix(acc_avg_over_analyses,'classif_res_ppa.xlsx','Sheet','2C_subj_count','Range','G2')
writematrix('overall_acc_mean_2_to_19','classif_res_ppa.xlsx','Sheet','2C_subj_count','Range','G1')