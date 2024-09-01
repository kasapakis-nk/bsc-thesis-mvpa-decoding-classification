% Input of this file is the output ds from any extract_ds.m file
home_dir = 'C:/Users/User/Desktop/HCP_WM_Datasets';
%ds = extract_ds_from(home_dir);

% Read mask, apply it, remove 0s and display masked ds.
ffa_msk = cosmo_fmri_dataset([ home_dir '/ffa_msk.nii' ]);
msk_indeces = find(ffa_msk.samples);
msk_ds = cosmo_slice(ds,msk_indeces,2);
msk_ds = cosmo_remove_useless_data(msk_ds);

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

%{ 
This is not squared, includes negative values
targets_upa_means = [sum(targets_ds_storage{1}.samples(1:size(targets_ds_storage{1}.samples,1))/size(targets_ds_storage{1}.samples,1)), ...
                     sum(targets_ds_storage{2}.samples(1:size(targets_ds_storage{1}.samples,1))/size(targets_ds_storage{1}.samples,1)), ...
                     sum(targets_ds_storage{3}.samples(1:size(targets_ds_storage{1}.samples,1))/size(targets_ds_storage{1}.samples,1)), ...
                     sum(targets_ds_storage{4}.samples(1:size(targets_ds_storage{1}.samples,1))/size(targets_ds_storage{1}.samples,1)), ...
                     ];
%}

targets_upa_means = [sum((targets_ds_storage{1}.samples(1:size(targets_ds_storage{1}.samples,1)).^2))/size(targets_ds_storage{1}.samples,1), ...
                     sum((targets_ds_storage{2}.samples(1:size(targets_ds_storage{1}.samples,1)).^2))/size(targets_ds_storage{1}.samples,1), ...
                     sum((targets_ds_storage{3}.samples(1:size(targets_ds_storage{1}.samples,1)).^2))/size(targets_ds_storage{1}.samples,1), ...
                     sum((targets_ds_storage{4}.samples(1:size(targets_ds_storage{1}.samples,1)).^2))/size(targets_ds_storage{1}.samples,1), ...
                     ];

disp(targets_upa_means)

% Bar plot
bar(targets_upa_means)
title('Average Signal Magnitude - 4C - FFA');
ylabel('Signal Strength (a.u.)')
labels = {'Body' 'Face' 'Place' 'Tool'};
set(gca,'xticklabel',labels)