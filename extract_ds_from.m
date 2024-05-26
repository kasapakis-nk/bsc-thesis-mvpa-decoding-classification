function ds = extract_ds_from(home_dir, varargin)%selected_copes, selected_runs

% Set default values.
defaults.selected_copes = 1:8;
defaults.selected_runs = {'LR' 'RL'};

if nargin == 1
    % Checking if home_dir was input correctly.
    if isstring(~home_dir)
        error('home_dir must be a string representing the path of the fmri folder.')
    end
    selected_copes = defaults.selected_copes;
    selected_runs  = defaults.selected_runs;
end

if nargin == 2
    % Checking if selected_copes was input correctly.
    selected_copes = varargin{1};
    error_if_not_ok = is_selected_copes_invalid(selected_copes);
    if isnan(str2double(error_if_not_ok))
        error(error_if_not_ok)
    end
    selected_runs = defaults.selected_runs;
end

if nargin == 3
    % Checking if selected_runs was input correctly.
    selected_runs = varargin{2};
    error_if_not_ok = is_selected_runs_invalid(selected_runs);
    if isnan(str2double(error_if_not_ok))
        error(error_if_not_ok)
    end
    selected_runs = {convertStringsToChars(selected_runs)};
    selected_copes = varargin{1};
end


% Code Body.
labels_dict  = dictionary( 1, 'Body'  , 5, 'Body' , ... %1-4 are 2bk_
    2, 'Face'  , 6, 'Face' , ... %5-8 are 0bk_
    3, 'Place' , 7, 'Place', ...
    4, 'Tool'  , 8, 'Tool');

targets_dict = dictionary( 1, 1  , 5, 1 , ...
    2, 2  , 6, 2 , ...
    3, 3  , 7, 3 , ...
    4, 4  , 8, 4);

chunks_dict  = dictionary( 1, 1  , 5, 2 , ... %chunk 1 is LR_2bk
    2, 1  , 6, 2 , ... %chunk 2 is LR_0bk
    3, 1  , 7, 2 , ... %chunk 3 is RL_2bk
    4, 1  , 8, 2);     %chunk 4 is RL_0bk

% Extract subjects list into output: "subj_list".
subj_dir_files = dir([home_dir '/fmri']);
subj_dir_files_count = numel(subj_dir_files);
subj_list = cell(1,subj_dir_files_count);
subj_count=0;

for flag=1:subj_dir_files_count
    % Condition for subj_dir_file to be a valid subj folder.
    % Checks if it contains any number in its name.
    subj_condition = (numel(regexp(subj_dir_files(flag).name,'\w\d'))~=0);
    if subj_condition
        subj_list(subj_count + 1) = {subj_dir_files(flag).name};
        subj_count = subj_count + 1;
    end
end
subj_list = subj_list(~cellfun(@isempty,subj_list) == 1);

% Extract and add .sa to each cope.
selected_cope_count = numel(selected_copes);
run_count = numel(selected_runs);
cope_storage = cell((selected_cope_count*run_count),1);
cope_total_count = 0;

% Go through all subjects.
chunks_count = 0;
for subj_id = 1:subj_count
    run_increment = 0;
    % Go through all chosen runs.
    for run_id = 1:run_count
        % Go through all chosen copes.
        for flag = 1:selected_cope_count
            cope_id = selected_copes(flag);
            % Read specific cope file.
            runspec = cell2mat(['/fmri/' subj_list(subj_id) '/tfMRI_WM_' selected_runs(run_id) '_hp200_s4.feat/stats']);
            filespec = ['/cope' num2str(cope_id) '.nii.gz'];
            ds_temp = cosmo_fmri_dataset( [home_dir runspec filespec] );

            % Set the sample attributes for chosen cope.
            ds_temp.sa.targets = targets_dict(cope_id);
            ds_temp.sa.labels  = labels_dict(cope_id);
            ds_temp.sa.chunks  = chunks_dict(cope_id) + run_increment + chunks_count;

            % Store data from each cope, seperately, in storage matrix.
            % Unnecessary step for function file.
            cope_storage{cope_total_count + 1} = ds_temp;
            cope_total_count = cope_total_count + 1;
        end
        run_increment = run_increment + run_count;
    end
    chunks_count = chunks_count + (run_count * 2);
end

% Concatenate cope's into final dataset.
ds = cosmo_stack(cope_storage(1:numel(cope_storage)));

% Display Data.
cosmo_disp(ds)

% Sanity checks.
% Regarding ds
assert(isequal(cosmo_check_dataset(ds),1))
assert(isequal(ds_temp.samples,ds.samples(size(ds.samples,1),:)))
target_count = numel(unique(ds.sa.targets));
if target_count == 4
    assert(isequal(ds.sa.labels,repmat(["Body";"Face";"Place";"Tool"],chunks_count,1)))
    assert(isequal(ds.sa.targets,repmat((1:4)',chunks_count,1)))
    assert(isequal(ds.sa.chunks,reshape(bsxfun(@plus, zeros(4,1), 1:chunks_count),[cope_total_count,1])))
end


%Nested functions below.

    function error_if_not_ok = is_selected_copes_invalid(selected_copes)
        error_if_not_ok = [];
        if ~isnumeric(selected_copes)
            error_if_not_ok = ('selected_copes must be a 1xN number array.');
        elseif numel(selected_copes) > 8
            error_if_not_ok = ('selected_copes numel must not exceed 8.');
        else
            for j = 1:numel(selected_copes)
                if selected_copes(j)>8
                    error_if_not_ok = ['selected_copes element at index ' num2str(j) ' is greater than 8.'];
                elseif selected_copes(j)<1
                    error_if_not_ok = ['selected_copes element at index ' num2str(j) ' is less than 1.'];
                end
            end
        end
    end

    function error_if_not_ok = is_selected_runs_invalid(selected_runs)
        error_if_not_ok = [];
        if ~ischar(selected_runs) & ~isstring(selected_runs)
            error_if_not_ok = ('selected_runs must be a character vector or string.');
        elseif numel(selected_runs) ~= 2
            error_if_not_ok = ('selected_runs must be either "LR" or "RL".');
        elseif ~strcmp(selected_runs,'LR') & ~strcmp(selected_runs,'RL')
            error_if_not_ok = ('selected_runs must be either "LR" or "RL".');
        end
    end

end