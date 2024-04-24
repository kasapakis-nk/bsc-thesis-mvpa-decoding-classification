% Set the data path.
config=cosmo_config();
data_path=fullfile(config.tutorial_data_path,'ak6','s01');

% Assign the dataset filename to a variable.
fn = fullfile(data_path, 'glm_T_stats_perrun.nii');

% Load the dataset with VT mask.
ds = cosmo_fmri_dataset(        [data_path '/glm_T_stats_perrun.nii'], ...
                        'mask', [data_path '/vt_mask.nii']);

% Remove constant features.
ds = cosmo_remove_useless_data(ds);

% Set sample attributes.
ds.sa.targets = repmat((1:6)',10,1);
ds.sa.chunks = ceil((1:60)'/6);

% Add labels as sample attributes.
classes = {'monkey';'lemur';'mallard';'warbler';'ladybug';'lunamoth'};
ds.sa.labels = repmat(classes,10,1);

% Slice into odd and even runs.
even_msk = mod(ds.sa.chunks,2) == 0;
odd_msk = mod(ds.sa.chunks,2) == 1;

ds_even = cosmo_slice(ds,even_msk);
ds_odd = cosmo_slice(ds,odd_msk);

% Slice odd and even runs, into only containing birds.

categories = ({'mallard', 'warbler'});

msk_even_birds = cosmo_match(ds_even.sa.labels,categories);
ds_even_birds = cosmo_slice(ds_even,msk_even_birds);

msk_odd_birds=cosmo_match(ds_odd.sa.labels,categories);
ds_odd_birds=cosmo_slice(ds_odd,msk_odd_birds);

% show the data
fprintf('Even data:\n')
cosmo_disp(ds_even_birds);

fprintf('Odd data:\n')
cosmo_disp(ds_odd_birds);

% Train on even, test on odd.
train_samples=ds_even_birds.samples;
train_targets=ds_even_birds.sa.targets;
test_samples=ds_odd_birds.samples;

% Use lda classification
test_pred_lda=cosmo_classify_lda(train_samples,train_targets,test_samples);

% Assign the real targets of the odd runs to a variable 'test_targets'
test_targets=ds_odd_birds.sa.targets;

% Show real and predicted labels
fprintf('\ntarget predicted\n');
disp([test_targets test_pred_lda])

% Show accuracy of lda clasification
accuracy1 = mean(test_pred_lda==test_targets);
fprintf('\nLDA birds even-odd: accuracy %.3f\n', accuracy1);

% Use naive Bayes classification
test_pred_nb=cosmo_classify_naive_bayes(train_samples,train_targets,test_samples);

% Show real and predicted labels
fprintf('\ntarget predicted\n');
disp([test_targets test_pred_nb])

% Show accuracy of nb clasification
accuracy2 = mean(test_pred_nb==test_targets);
fprintf('\nNaive Bayes birds even-odd: accuracy %.3f\n', accuracy2);