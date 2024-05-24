% Constructing the ds.samples matrix from multiple cope files, 
% from both runs, for multiple subjects.

% Setting Home directory. 
% This dir includes the 'fMRI' folder, containing all subject folders.
home_dir = 'C:/Users/User/Desktop/HCP_WM_Datasets';

% Setup area. Change to perform different analyses.
% Reccomended: Choice of cope's should be in pairs, 1+5, 2+6 etc.
% Examples: [1:3,5:7] or [2,4,6,8].
selected_copes = 1:8;
run_id_mat = {'LR' 'RL'};

labels_dict  = dictionary( 1, 'Body'  , 5, 'Body' ,... #first 4 are 2bk
                           2, 'Face'  , 6, 'Face' ,...
                           3, 'Place' , 7, 'Place',...
                           4, 'Tool'  , 8, 'Tool');

targets_dict = dictionary( 1, 1  , 5, 1 ,...
                           2, 2  , 6, 2 ,...
                           3, 3  , 7, 3 ,...
                           4, 4  , 8, 4);

chunks_dict  = dictionary( 1, 1  , 5, 2 ,... %chunk 1 is runLR 2bk, 2 is runLR 0bk, 3 is runRL 2bk, 4 is runRL 0bk
                           2, 1  , 6, 2 ,...
                           3, 1  , 7, 2 ,...
                           4, 1  , 8, 2);

% Pre-allocate cells and define flags.
cope_storage_mat = cell((numel(selected_copes)*numel(run_id_mat)),1);
storage_cell_id = 1;

subj_temp = dir([home_dir '/fmri']);
subj_temp_id=1;
subj_id_mat = cell(1,numel(subj_temp) - 2);

% Create subjects list. Keeps any folder containing any numbers in its name.
for subj_dir_file_id=1:numel(subj_temp)
    if numel(regexp(subj_temp(subj_dir_file_id).name,'\w\d'))~=0
        subj_id_mat(subj_temp_id) = {subj_temp(subj_dir_file_id).name};
        subj_temp_id = subj_temp_id + 1;
    end
end
% subj_id_mat = { '100307' '100408' }; % For testing.

% Go through all subjects.
chunks_increment = 0;
for subj_id = 1:numel(subj_id_mat)
    run_increment = 0;
    % Go through both runs, LR and RL.
    for run_idx = 1:numel(run_id_mat)
        % Go through all copes.
        for cope_idx = selected_copes(1):selected_copes(numel(selected_copes))
            % Read specific cope file.
            runspec = cell2mat(['/fmri/' subj_id_mat(subj_id) '/tfMRI_WM_' run_id_mat(run_idx) '_hp200_s4.feat/stats']);
            filespec = ['/cope' num2str(cope_idx) '.nii.gz'];
            ds_temp = cosmo_fmri_dataset( [home_dir runspec filespec] );

            % Set the sample attributes for chosen cope.
            ds_temp.sa.targets = targets_dict(cope_idx);
            ds_temp.sa.labels  = labels_dict(cope_idx);
            ds_temp.sa.chunks  = chunks_dict(cope_idx) + run_increment + chunks_increment;

            % Store cope sample in storage matrix.
            cope_storage_mat{storage_cell_id} = ds_temp;
            storage_cell_id = storage_cell_id + 1;
        end
        run_increment = run_increment + 2;
    end
    chunks_increment = chunks_increment + 4;
end

% Concatenate cope's into final dataset.
ds = cosmo_stack(cope_storage_mat(1:numel(cope_storage_mat)));

% Display Data.
cosmo_disp(ds)

% Sanity checks.
assert(isequal(cosmo_check_dataset(ds),1))
ds_check = cosmo_fmri_dataset([home_dir runspec filespec]);
assert(isequal(ds_temp.samples,ds_check.samples))
assert(isequal(ds_temp.samples,ds.samples(size(ds.samples,1),:)))

assert(isequal(ds.sa.labels,repmat(["Body";"Face";"Place";"Tool"],4*numel(subj_id_mat),1)))
assert(isequal(ds.sa.targets,repmat((1:4)',4*numel(subj_id_mat),1)))
%assert(isequal(ds.sa.chunks,[ones(4,1);ones(4,1)+1;ones(4,1)+2;ones(4,1)+3]))

% Clear clutter variables.
clutter_vars = {'chunks_increment' 'cope_idx' 'ds_check' 'ds_temp' 'run_idx' 'run_increment' 'storage_cell_id' 'subj_id' ...
                'subj_temp_id' 'subj_temp' 'subj_dir_file_id'};
for i=1:numel(clutter_vars) 
    clear(clutter_vars{i})
end
clear i; clear clutter_vars;