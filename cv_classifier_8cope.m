% Input of this file is the output ds from any extract_ds.m file
home_dir = 'C:/Users/User/Desktop/HCP_WM_Datasets';
ds = extract_ds_from(home_dir);

% Read mask, apply it, remove 0s and display masked ds.
ffa_msk = cosmo_fmri_dataset([ home_dir '/ffa_msk.nii' ]);
msk_indeces = find(ffa_msk.samples);
msk_ds = cosmo_slice(ds,msk_indeces,2);
msk_ds = cosmo_remove_useless_data(msk_ds);
cosmo_disp(msk_ds)

% Sanity check.
assert(isequal(cosmo_check_dataset(msk_ds),1))
assert(isequal(msk_ds.sa.chunks,ds.sa.chunks))
assert(isequal(msk_ds.sa,ds.sa))

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
fold_count = 200;
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
end


% Display accuracy.
acc_libsvm_mean = sum(acc_libsvm_per_fold)/fold_count;
disp([newline newline 'Classifier lib_svm, with cross-validation at ' num2str(fold_count) ' folds,' ...
      newline 'with a ' num2str((1-test_ratio)*100) '/' num2str(test_ratio * 100) ' train/test split,' ...
      newline 'predicted targets with a mean accuracy of ' num2str([num2str((acc_libsvm_mean * 100),3) '%']) '.']);

% Relative accuracy is based on 25% being the lowest performance.
% 4 is optimal, 1 is equivalent to random guessing.
% Only accurate for all four target analyses.
acc_libsvm_mean_relative = (acc_libsvm_mean/(1/target_count));
disp([newline 'Mean relative accuracy is: ' num2str(acc_libsvm_mean_relative,3) ]);

max_folds = find(acc_libsvm_per_fold == max(acc_libsvm_per_fold));
min_folds = find(acc_libsvm_per_fold == min(acc_libsvm_per_fold));

if numel(max_folds) == 1 & numel(min_folds) == 1
disp([newline 'Best performance occured at fold ' num2str(find(acc_libsvm_per_fold == max(acc_libsvm_per_fold))) ',' ...
      ' and it was equal to: ' [num2str(max(acc_libsvm_per_fold) * 100,3) '%']    ]);
disp([newline 'Worst performance occured at fold ' num2str(find(acc_libsvm_per_fold == min(acc_libsvm_per_fold))) ',' ...
      ' and it was equal to: ' [num2str(min(acc_libsvm_per_fold) * 100,3) '%']    ]);
else
    disp([newline 'More than one folds achieved maximum or minimum accuracies.' ...
          newline 'Check "max_folds" and "min_folds" arrays to identify them.'])
end

% Clear clutter variables.
clutter_vars = { 'ds_temp' 'ffa_msk' 'fold_id' 'max_fold_count' 'msk_indeces' 'partitions_storage' 'samples_per_target' ...
                 'target_id' 'target_msk' 'targets_ds_storage' 'test_ds' 'test_ds_temp' 'test_samples' 'train_ds' ...
                 'train_ds_temp' 'train_samples' 'train_targets' };
for flag=1:numel(clutter_vars)
    clear(clutter_vars{flag})
end
clear flag; clear clutter_vars;

% TO DO:
% Include data about what the success% was from the actual human subjects.
% Means the ceiling is not 100%, shows how successful the classifer is,
% compared to humans. Ideally we have seperate acc for 2bk, 0bk and mean.

% Include some sort of graph showing acc for every fold.
% Maybe include a straight line denoting mean accuracy at the end.