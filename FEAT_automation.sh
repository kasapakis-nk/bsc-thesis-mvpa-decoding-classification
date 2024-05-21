#!/bin/bash

# Setting Home directory. 
# This dir includes the 'fMRI' folder, the mask files and the 'og_design' dir,
# where the original, manually created design_LR.fsf file is saved.

home_dir="/mnt/c/Users/User/Desktop/HCP_WM_Datasets"
cd $home_dir
og_design_dir="og_design"

# Setup area. Orieantaions array and subject list.
# Later make subjects wildcards, not array.

orientations=('LR' 'RL')
subj_list=('100307' '100408') #2 subs for testing.

# Pre for-loop part has been created so that:
# You manually design and save any subject *.fsf file and the rest is automatic.
# Which subject you choose and which orientation does not matter.

# INSTRUCTIONS
# Original .fsf file must be named "design_LR/RL.fsf" or error is thrown.
# Original .fsf file must be saved in "og_design_dir" directory. 

# Read the subject_id based on which
# *.fsf file was originally created.
cd $og_design_dir

design_fn=$(find -name "*.fsf")
des_temp=${design_fn/[-.]}
des_temp=$(echo $des_temp | tr -d '/')
str_temp=$(grep -i "/mnt/c/Users/User/Desktop/HCP_WM_Datasets/fmri/*" $des_temp)
echo $str_temp | grep -Eo '[0-9]+' > /dev/null
str_temp=$(echo $str_temp | grep -Eo '[0-9]+')

og_subject_id=${str_temp:0:6}

# Read which orientation was conducted manually and
# create the second .fsf file.
if [[ $design_fn == *LR* ]]; then
	cp design_LR.fsf ./design_RL.fsf
	sed -i "s|LR|RL|g" design_RL.fsf
	cd ..
elif [[ $design_fn == *RL* ]]; then
	cp design_RL.fsf ./design_LR.fsf
	sed -i "s|RL|LR|g" design_LR.fsf
	cd ..
else
	echo $'\n'Original design.fsf file was not named properly.
	echo Name must be "design_LR.fsf" or "design_RL.fsf" respectively.$'\n'
	exit
fi

# Go through all subjects.
for subj in "${subj_list[@]}"
do

	echo "===> Starting processing of subject $subj"$'\n'

	# Copy and edit original design files to match current subject.
	cd $og_design_dir 
	cp design_LR.fsf ../fmri/$subj
	cp design_RL.fsf ../fmri/$subj
	cd ../fmri/$subj

	sed -i "s|${og_subject_id}|${subj}|g" design_LR.fsf
	sed -i "s|${og_subject_id}|${subj}|g" design_RL.fsf

	# Begin FEAT analysis.
	echo "===> Starting FEAT for LR orientation"$'\n'
	date +"%T"
	feat design_LR.fsf
	date +"%T"$'\n'
	
	# Optional: Open report_log with corresponding browser when analysis is over.
	cd tfMRI_WM_LR_hp200_s4.feat
	firefox report_log.html
	#google-chrome report_log.html
	cd ..
	
	echo "===> Starting FEAT for RL orientation"$'\n'
	date +"%T"
	feat design_RL.fsf
	date +"%T" $'\n'
	
	cd tfMRI_WM_RL_hp200_s4.feat
	firefox report_log.html
	#google-chrome report_log.html

	# Reset path for for loop to work properly.
	cd $home_dir
	
done

# IGNORE BELOW
    # for ori_id in "${orientations[@]}"
	# do
    #    subrun="tfMRI_WM_$ori_id"
    #    echo $subrun



    #   echo $subj
	# done