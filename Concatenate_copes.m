% Creating the ds.samples matrix from multiple cope files, from both runs,
% for one subject

% Set specific processed data Results path for one subject.
results_data_path = [ 'C:\Users\User\Desktop\WMtask_Dataset\' ...
                       '100307_3T_tfMRI_WM_preproc\' ...
                       '100307\MNINonLinear\Results\' ];

% Setup area. This is what you change to perform different analyses.
% Choice of cope's to be included, their labels etc.
% Can be generalized to all and any of the 30 pe's.
cope_idx_mat = [ 19 20 21 22 ];
run_idx_mat = {'LR' 'RL'};

labels_dict  = dictionary( 19, 'Body'   ,...
                           20, 'Face'   ,...
                           21, 'Place'  ,...
                           22, 'Tool'  );

targets_dict = dictionary( 19, 1  ,...
                           20, 2  ,...
                           21, 3  ,...
                           22, 4 );

% Pre-allocate cells for each cope.
str_storage_mat = cell((numel(cope_idx_mat)*numel(run_idx_mat)),1);
storage_cell_idx = 1;

% Go through all runs, LR and RL.
for j = 1:numel(run_idx_mat)
    chunk_idx = j;
    for i = cope_idx_mat(1):cope_idx_mat(numel(cope_idx_mat))
        % Choose specific cope file
        runspec = cell2mat(['/tfMRI_WM_' run_idx_mat(j) '_hp200_s4.feat\stats']);
        filespec = ['/cope' num2str(i) '.nii.gz'];
        ds_var = cosmo_fmri_dataset( [results_data_path runspec filespec] );

        % Set the sample attributes for said cope.
        ds_var.sa.targets = targets_dict(i);
        ds_var.sa.labels  = labels_dict(i);
        ds_var.sa.chunks  = chunk_idx;

        % Store cope dataset in storage matrix.
        str_storage_mat{storage_cell_idx} = ds_var;
        storage_cell_idx = storage_cell_idx + 1;
    end
end

% Define final dataset structure.
ds.samples    = [];
ds.sa.targets = [];
ds.sa.labels  = [];
ds.sa.chunks  = [];

% Concatenate cope's into final dataset.
for i = 1:(numel(cope_idx_mat)*numel(run_idx_mat))
    ds.samples    = [ds.samples; str_storage_mat{i}.samples];

    ds.sa.targets = [ds.sa.targets; str_storage_mat{i}.sa.targets];
    ds.sa.labels  = [ds.sa.labels; str_storage_mat{i}.sa.labels];
    ds.sa.chunks  = [ds.sa.chunks; str_storage_mat{i}.sa.chunks];
end

% Sanity checks
ds2 = cosmo_fmri_dataset('C:\Users\User\Desktop\WMtask_Dataset\100307_3T_tfMRI_WM_preproc\100307\MNINonLinear\Results\tfMRI_WM_RL_hp200_s4.feat\stats\cope22.nii.gz');
assert(isequal(ds_var.samples,ds2.samples))
assert(isequal(ds_var.samples,ds.samples(8,:)))

% Display Data
cosmo_disp(ds)