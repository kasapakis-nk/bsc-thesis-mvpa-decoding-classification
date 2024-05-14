% Create mask for ffa.
vol_coords = cosmo_vol_coordinates(ds);
ffa_center = [40; -52; -20];
radius = 50;

delta_ijk = vol_coords - ffa_center;
distance_from_ffa_center = sum(delta_ijk.^2,1);

ffa_mask = distance_from_ffa_center <= radius^2;

% Apply mask and display masked ds.
msk_ds = cosmo_slice(ds,ffa_mask,2);
% Attempting to reduce features so classification will be faster (doable).
% Not sure if correct practice.
msk_ds = cosmo_remove_useless_data(msk_ds);
cosmo_disp(msk_ds)

% Sanity check.
assert(isequal(cosmo_check_dataset(msk_ds),1))
