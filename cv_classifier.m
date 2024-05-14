% Post analysis dataset.
extract_dataset;
% Post mask dataset.
ffa_mask_application;

% Classifier with cross validation below.

% Partition different targets into different ds.
ds_storage_targets = cell(numel(unique(msk_ds.sa.targets)),1);

for target_idx = 1:numel(ds_storage_targets)
    target_msk = msk_ds.sa.targets == target_idx;
    ds_storage_targets{target_idx} = cosmo_slice(msk_ds,target_msk,1);
end

% Partition each target_only_ds into different runs.
for target_idx = 1:numel(ds_storage_targets)
    ds_temp = ds_storage_targets{target_idx};
    chunk_partitions = cosmo_nfold_partitioner(ds_temp.sa.chunks);
    assert(isequal(cosmo_check_partitions(chunk_partitions,ds_temp),1))
end

% Setting train and test variables for FACE target only. Can be scaled to
% all 4 targets, or 4x(2bk + 0bk).
face_idx = 2;
for partition_idx = 1:numel(chunk_partitions.train_indices)
    train_ds = cosmo_slice(ds_storage_targets{face_idx},chunk_partitions.train_indices{partition_idx});
    train_samples = train_ds.samples;
    train_targets = train_ds.sa.targets;
    test_ds = cosmo_slice(ds_storage_targets{face_idx},chunk_partitions.test_indices{partition_idx});
    test_samples = test_ds.samples;
end

% Use classification.
pred_libsvm = cosmo_classify_libsvm(train_samples,train_targets,test_samples);

% Check accuracy.
expected_targets = test_ds.sa.targets;

fprintf('\nPredicted Expected\n');
fprintf('    %d        %d\n',pred_libsvm,expected_targets)

acc_libsvm = mean(expected_targets==pred_libsvm);
fprintf('\nlibsvm classifier accuracy: %d\n',acc_libsvm)