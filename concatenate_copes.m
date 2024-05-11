% Creating the ds.samples matrix from multiple cope files, from both runs,
% for one subject

% Set specific processed data Results path for one subject.
results_data_path = [ 'C:\Users\User\Desktop\WMtask_Dataset\' ...
                       '100307_3T_tfMRI_WM_preproc\' ...
                       '100307\MNINonLinear\Results\' ];

% Setup area. This is what you change to perform different analyses.
% Choice of cope's to be included, their labels etc.
% Can be generalized to all and any of the 30 pe's.
selected_copes = 19:22;
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
cope_storage_mat = cell((numel(selected_copes)*numel(run_idx_mat)),1);
storage_cell_idx = 1;

% Go through all runs, LR and RL.
for chunk_idx = 1:numel(run_idx_mat)
    for cope_idx = selected_copes(1):selected_copes(numel(selected_copes))
        % Choose specific cope file
        runspec = cell2mat(['/tfMRI_WM_' run_idx_mat(chunk_idx) '_hp200_s4.feat/stats']);
        filespec = ['/cope' num2str(cope_idx) '.nii.gz'];
        ds_temp = cosmo_fmri_dataset( [results_data_path runspec filespec] );

        % Set the sample attributes for said cope.
        ds_temp.sa.targets = targets_dict(cope_idx);
        ds_temp.sa.labels  = labels_dict(cope_idx);
        ds_temp.sa.chunks  = chunk_idx;

        % Store cope dataset in storage matrix.
        cope_storage_mat{storage_cell_idx} = ds_temp;
        storage_cell_idx = storage_cell_idx + 1;
    end
end

% Concatenate cope's into final dataset.
ds = cosmo_stack(cope_storage_mat(1:numel(cope_storage_mat)));

% Display Data.
cosmo_disp(ds)

% Sanity checks.
assert(isequal(cosmo_check_dataset(ds),1))
ds_check = cosmo_fmri_dataset('C:\Users\User\Desktop\WMtask_Dataset\100307_3T_tfMRI_WM_preproc\100307\MNINonLinear\Results\tfMRI_WM_RL_hp200_s4.feat\stats\cope22.nii.gz');
assert(isequal(ds_temp.samples,ds_check.samples))
assert(isequal(ds_temp.samples,ds.samples(size(ds.samples,1),:)))

assert(isequal(ds.sa.labels,repmat(["Body";"Face";"Place";"Tool"],2,1)))
assert(isequal(ds.sa.targets,repmat((1:4)',2,1)))
assert(isequal(ds.sa.chunks,[ones(4,1);ones(4,1)+1]))
