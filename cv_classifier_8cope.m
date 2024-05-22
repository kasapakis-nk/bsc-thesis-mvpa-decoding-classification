% Input of this file is the output ds from any extract_ds.m file

%extract_ds_8cope;

home_dir = 'C:/Users/User/Desktop/HCP_WM_Datasets';

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

% Classification with cross validation below.

% Partition different targets into different ds.
ds_storage_targets = cell(numel(unique(msk_ds.sa.targets)),1);

for target_idx = 1:numel(ds_storage_targets)
    target_msk = msk_ds.sa.targets == target_idx;
    ds_storage_targets{target_idx} = cosmo_slice(msk_ds,target_msk,1);
end

% % OUTPUT: ds_storage_targets 4x1 cell. Each cell has 80x1 samples.
% % Same targets, different chunks.

% Partition each target_only_ds into different runs.
fold_count = 100; %Maximum fold_count -> nchoosek(320,80)
test_ratio = 0.25;
test_count = 20;
train_count = 60;
samples_per_target = 80;

chunk_partitions_storage = cell(numel(ds_storage_targets),1); %Pre allocate 4 cells 4x1

for target_idx = 1:numel(chunk_partitions_storage)
    ds_temp = ds_storage_targets{target_idx};
    chunk_partitions_storage{target_idx} = cosmo_independent_samples_partitioner(ds_temp, ...
                                                                                'fold_count', fold_count, ...
                                                                                'test_ratio', test_ratio, ...
                                                                                'max_fold_count', 1000);
    assert(isequal(cosmo_check_partitions(chunk_partitions_storage{target_idx},ds_temp),1))
end

% % OUTPUT:chunk_partitions_storage 4x1 cell. Each cell has 1 structure.
% % Each structure has:
% % 50 .train_indices cells with 60 chunk numbers in each cell.
% % 50 .test_indices  cells with 20 chunk numbers in each cell.

pred_libsvm = cell(fold_count, test_count*4); %50x80
pred_libsvm_logical = cell(fold_count, test_count*4); %50x80 
sep_train_ds = cell(4,1);
sep_test_ds  = cell(4,1);

% % Add balance partitions. Check partitions.

% Performing classification for all folds.
for partition_idx = 1:fold_count
    % Slicing target_only_ test_ds and train_ds based on partitions.
    for i=1:4
    sep_train_ds{i} = cosmo_slice(   ds_storage_targets{i}, ...
                                     chunk_partitions_storage{i}.train_indices{partition_idx}  );
    sep_test_ds{i}  = cosmo_slice(   ds_storage_targets{i}, ...
                                     chunk_partitions_storage{i}.test_indices{partition_idx}   );
    end
    % Concatenating all partitioned target_only_ds. 
    % into one fully partitioned ds.
    train_ds = cosmo_stack(sep_train_ds(1:4));
    test_ds = cosmo_stack(sep_test_ds(1:4));
    
    train_samples = train_ds.samples;
    train_targets = train_ds.sa.targets;
    test_samples = test_ds.samples;

    % Use classifier for each partition.
    pred_libsvm{partition_idx} = cosmo_classify_libsvm(train_samples,train_targets,test_samples);

    % Accuracy data.
    expected_targets = test_ds.sa.targets;
    for i=1:80
        if pred_libsvm{partition_idx}(i)~=expected_targets(i)
            pred_libsvm_logical{partition_idx}(i) = 0;
        else
            pred_libsvm_logical{partition_idx}(i) = 1; 
        end
    end
end

% Calculate accuracy.

acc_libsvm_per_partition = zeros(80,1);
for j=1:fold_count
    for i=1:80
        acc_libsvm_per_partition(i) = numel(find(pred_libsvm_logical{j}(i)) / numel(pred_libsvm_logical{j}(i)));
    end
end

%Display accuracy.
acc_libsvm_mean = sum(acc_libsvm_per_partition(1:80)/80);
disp([num2str((acc_libsvm_mean * 100),3) '%']);
% fprintf('\nlibsvm classifier,with cv at %d folds, accuracy is : %d\n',fold_count,acc_libsvm_mean)

% Relative accuracy is based on 25% being the lowest performance.
acc_libsvm_mean_relative = (acc_libsvm_mean/0.25);
disp(acc_libsvm_mean_relative)
%fprintf('\nlibsvm classifier,with cv at %d folds, relative accuracy is : %d\n',fold_count,acc_libsvm_mean_relative)

% IGNORE BELOW
%fprintf('\nPredicted Expected\n');
%fprintf('    %d        %d\n',pred_libsvm,expected_targets)
%fprintf('\nlibsvm classifier accuracy: %d\n',acc_libsvm)