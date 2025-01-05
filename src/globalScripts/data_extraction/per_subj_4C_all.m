% Analysis per subject. 16 samples at a time.
% Extraction required. Run extract_ds_4C.m
home_dir = 'C:/Users/User/Desktop/HCP_WM_Datasets';

% Read mask, apply it, remove 0s and display masked ds.
ffa_msk = cosmo_fmri_dataset([ home_dir '/ffa_msk.nii' ]);
msk_indeces = find(ffa_msk.samples);
msk_ds = cosmo_slice(ds,msk_indeces,2);
msk_ds = cosmo_remove_useless_data(msk_ds);

subj_count = 20;
fold_count = 4;
test_ratio = 0.2;
max_fold_count = 4;

pred_libsvm = cell(subj_count, 1);
pred_libsvm_logical =  cell(subj_count,1);
acc_libsvm_per_fold = cell(subj_count,1);

inc_1=1;
inc_2=16;
for subj_id=1:20
    % train 1 2 3 test 4
    ds_temp = cosmo_slice(msk_ds,inc_1:inc_2);
    train_ds = cosmo_slice(ds_temp,1:12);
    train_samples = train_ds.samples;
    train_targets = train_ds.sa.targets;

    test_ds = cosmo_slice(ds_temp,13:16);
    test_samples = test_ds.samples;
    expected_targets = test_ds.sa.targets;

    pred_libsvm{subj_id}.fold_one = cosmo_classify_libsvm(train_samples,train_targets,test_samples);
    pred_libsvm_logical{subj_id}.fold_one = pred_libsvm{subj_id}.fold_one == expected_targets;

    acc_libsvm_per_fold{subj_id}.fold_one = sum(pred_libsvm_logical{subj_id}.fold_one / numel(pred_libsvm_logical{subj_id}.fold_one));

    inc_1 = inc_1 + 16;
    inc_2 = inc_2 + 16;
end

inc_1=1;
inc_2=16;
for subj_id=1:20
    % train 1 2 4 test 3
    ds_temp = cosmo_slice(msk_ds,inc_1:inc_2);
    train_ds = cosmo_slice(ds_temp,[1:8,13:16]);
    train_samples = train_ds.samples;
    train_targets = train_ds.sa.targets;

    test_ds = cosmo_slice(ds_temp,9:12);
    test_samples = test_ds.samples;
    expected_targets = test_ds.sa.targets;

    pred_libsvm{subj_id}.fold_two = cosmo_classify_libsvm(train_samples,train_targets,test_samples);
    pred_libsvm_logical{subj_id}.fold_two = pred_libsvm{subj_id}.fold_two == expected_targets;

    acc_libsvm_per_fold{subj_id}.fold_two = sum(pred_libsvm_logical{subj_id}.fold_two / numel(pred_libsvm_logical{subj_id}.fold_two));

    inc_1 = inc_1 + 16;
    inc_2 = inc_2 + 16;
end

inc_1=1;
inc_2=16;
for subj_id=1:20
    % train 1 3 4 test 2
    ds_temp = cosmo_slice(msk_ds,inc_1:inc_2);
    train_ds = cosmo_slice(ds_temp,[1:4,9:16]);
    train_samples = train_ds.samples;
    train_targets = train_ds.sa.targets;

    test_ds = cosmo_slice(ds_temp,5:8);
    test_samples = test_ds.samples;
    expected_targets = test_ds.sa.targets;

    pred_libsvm{subj_id}.fold_three = cosmo_classify_libsvm(train_samples,train_targets,test_samples);
    pred_libsvm_logical{subj_id}.fold_three = pred_libsvm{subj_id}.fold_three == expected_targets;

    acc_libsvm_per_fold{subj_id}.fold_three = sum(pred_libsvm_logical{subj_id}.fold_three / numel(pred_libsvm_logical{subj_id}.fold_three));

    inc_1 = inc_1 + 16;
    inc_2 = inc_2 + 16;
end

inc_1=1;
inc_2=16;
for subj_id=1:20
    % train 1 3 4 test 2
    ds_temp = cosmo_slice(msk_ds,inc_1:inc_2);
    train_ds = cosmo_slice(ds_temp,5:16);
    train_samples = train_ds.samples;
    train_targets = train_ds.sa.targets;

    test_ds = cosmo_slice(ds_temp,1:4);
    test_samples = test_ds.samples;
    expected_targets = test_ds.sa.targets;

    pred_libsvm{subj_id}.fold_four = cosmo_classify_libsvm(train_samples,train_targets,test_samples);
    pred_libsvm_logical{subj_id}.fold_four = pred_libsvm{subj_id}.fold_four == expected_targets;

    acc_libsvm_per_fold{subj_id}.fold_four = sum(pred_libsvm_logical{subj_id}.fold_four / numel(pred_libsvm_logical{subj_id}.fold_four));

    inc_1 = inc_1 + 16;
    inc_2 = inc_2 + 16;
end

mean_acc_per_subj = zeros(subj_count,1);
for subj_id = 1:20
    mean_acc_per_subj(subj_id) = (acc_libsvm_per_fold{subj_id}.fold_one   + ...
                       acc_libsvm_per_fold{subj_id}.fold_two   + ...
                       acc_libsvm_per_fold{subj_id}.fold_three + ...
                       acc_libsvm_per_fold{subj_id}.fold_four)/4;
end


%{

% Data Storage
% ffa data
column_labels = {'subj_id' 'acc_mean_ffa'}; %add std? for 4 data points??

writecell(column_labels,'classification_results.xlsx','Sheet','4C_per_subj','Range','A1:B1')
writematrix(mean_acc_per_subj,'classification_results.xlsx','Sheet','4C_per_subj','Range','B2')
subj_id = (1:20)';
writematrix(subj_id,'classification_results.xlsx','Sheet','4C_per_subj','Range','A2')

% ppa data
column_labels = {'subj_id' 'acc_mean_ppa'}; %add std? for 4 data points??

writecell(column_labels,'classification_results.xlsx','Sheet','4C_per_subj','Range','E1:F1')
writematrix(mean_acc_per_subj,'classification_results.xlsx','Sheet','4C_per_subj','Range','F2')
subj_id = (1:20)';
writematrix(subj_id,'classification_results.xlsx','Sheet','4C_per_subj','Range','E2')

%}