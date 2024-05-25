% Input of this file is the output ds from any extract_ds.m file

%home_dir = 'C:/Users/User/Desktop/HCP_WM_Datasets';

% Define mask logic. 
% Here it takes a 12 voxel radius 'circle' around ppa center.
vol_coords = cosmo_vol_coordinates(ds);
ffa_center = [26; -33; -19];
radius = 12;

delta_ijk = vol_coords - ffa_center;
distance_from_ppa_center = sum(delta_ijk.^2,1);

ppa_msk = distance_from_ppa_center <= radius^2;

% Create mask and save it in home_dir as 'msk_fn'.
ds_temp = cosmo_slice(ds,1,1);
ds_temp.samples = double(ppa_msk);
msk_fn = [home_dir '/ppa_msk.nii'];
cosmo_map2fmri(ds_temp,msk_fn);

% Clear clutter variables.
clutter_vars = {'ds_temp' 'msk_fn' 'delta_ijk' 'distance_from_ppa_center' 'ppa_mask'};
for i=1:numel(clutter_vars) 
    clear(clutter_vars{i})
end
clear i; clear clutter_vars; clear ans;
