clear

% Dataset provided via script.
concatenate_copes;

% Create mask for ffa.
vol_coords = cosmo_vol_coordinates(ds);
ffa_center = [40; -52; -20];
radius = 50;

delta_ijk = vol_coords - ffa_center;
distance_from_ffa_center = sum(delta_ijk.^2,1);

ffa_mask = distance_from_ffa_center <= radius^2;

% Apply mask and display masked ds.
msk_ds = cosmo_slice(ds,ffa_mask,2);
cosmo_disp(msk_ds)

% Sanity check.
assert(isequal(cosmo_check_dataset(msk_ds),1))

% Classifier with cross validation.

%nfolds=numel(unique(masked_ds.sa.chunks)); IGNORE

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
    cosmo_check_partitions(chunk_partitions,ds_temp)
end

% IGNORE BELOW




%{
% Actually use classification. Only for FACES right now, no need to scale
% with just one subject.
ds_temp = ds_storage_targets{2};
ds_temp = ds_temp(1,:);
train_samples = ds_temp.samples;
%train_targets = 
%test_samples = 

%predictions = cosmo_classify_libsvm(train_samples,train_targets,test_samples);
%}