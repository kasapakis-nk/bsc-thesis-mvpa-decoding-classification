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

% OUTPUT: targets_ds_storage 4x1 cell array.
% Each cell has a struct with 80 x Features samples.
% All samples have the same target, different chunks.

% Partition each targets_ds into different runs.
% Maximum possible fold_count == nchoosek(320,80)

chosen_fold_count=[250,500,750,1000,1250,1500,1750,2000,2250,2500,2750,3000];

acc_mat = zeros(numel(chosen_fold_count),1);
std_mat = zeros(numel(chosen_fold_count),1);
final_mat = zeros(numel(chosen_fold_count),5);
box_plot_accs_per_fold_count = zeros(3000,numel(chosen_fold_count));
for i = 1:numel(chosen_fold_count)

    tic_time = tic;

    fold_count = chosen_fold_count(i);
    test_ratio = 0.2;
    max_fold_count = 5000;

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

        box_plot_accs_per_fold_count(fold_id,i) = acc_libsvm_per_fold(fold_id);
    end


    % Display accuracy.
    acc_libsvm_mean = sum(acc_libsvm_per_fold)/fold_count;
    std_libsvm = std(acc_libsvm_per_fold,1);

    acc_mat(i,1) = acc_libsvm_mean * 100;
    std_mat(i,1) = std_libsvm * 100;

    final_mat(i,1) = 19; %subj_count; %19 is including the 0% acc outlier.
    final_mat(i,2) = fold_count;
    final_mat(i,3) = acc_libsvm_mean;
    final_mat(i,4) = std_libsvm;
    final_mat(i,5) = toc(tic_time);

    disp([num2str(i) '/' num2str(numel(chosen_fold_count)) ' completed.' newline])
end

disp(['fold_count fold_count acc_mean std analysis_time' newline])
for j=1:numel(chosen_fold_count)
    disp([num2str(final_mat(j,1)) ' ' num2str(final_mat(j,2)) ' ' num2str([num2str((final_mat(j,3) * 100),3) '%']) ' ' num2str([num2str((final_mat(j,4) * 100),3) '%']) ' ' num2str([num2str(final_mat(j,5),2) 's']) newline ])
end

acc_avg_over_analyses = (sum(final_mat(1:numel(chosen_fold_count),3)) / numel(chosen_fold_count));
disp(['Average accuracy over ' num2str(numel(chosen_fold_count)) ' analyses was ' num2str([num2str((acc_avg_over_analyses * 100),3) '%']) '.'])

% Data Storage
box_col_labels = cell(1,12);
l = 1;
for k = 250:250:3000
    box_col_labels(1,l) = {['fold_count_' num2str(k)]};
    l=l+1;
end
column_labels = {'subj_count' 'fold_count' 'acc_mean' 'std' 'analysis_time (s)'};

writecell(box_col_labels,'classif_res_ppa.xlsx','Sheet','4C_fold_HN','Range','A16')
writematrix(box_plot_accs_per_fold_count,'classif_res_ppa.xlsx','Sheet','4C_fold_HN','Range','A17')

writecell(column_labels,'classif_res_ppa.xlsx','Sheet','4C_fold_HN','Range','A1:E1')
writematrix(final_mat,'classif_res_ppa.xlsx','Sheet','4C_fold_HN','Range','A2')
writematrix(acc_avg_over_analyses,'classif_res_ppa.xlsx','Sheet','4C_fold_HN','Range','G2')
writematrix('overall_acc_mean','classif_res_ppa.xlsx','Sheet','4C_fold_HN','Range','G1')