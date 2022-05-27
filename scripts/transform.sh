#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32000
#SBATCH --time=24:00:00
#SBATCH --job-name=transform
#SBATCH --account=ctb-akhanf


#for subj in `sed '1d'  participants.tsv`

#do
#$subj=$1

sub_path=$1

img_4d=$2   #home/dimuthu1/scratch/PPMI_project2/derivatives/diffparc_dev/work/${sub_ID}/bedpost.CIT168_striatum_cortical/connMap.4d.nii.gz
seed_img=$3  #/home/dimuthu1/scratch/PPMI_project2/derivatives/diffparc_dev/work/${sub_ID}/bedpost.CIT168_striatum_cortical/seed_dtires.nii.gz
template=$4


mkdir -p $sub_path/registered_slices
mkdir -p $sub_path/slices

fslsplit $img_4d ${sub_path}/slices/3d -t

reg_aladin -ref $template -flo $seed_img -res $sub_path/new_image_affine_result.nii.gz -aff $sub_path/new_image_affine_matrix.txt

reg_f3d -ref $template -flo $seed_img  -res $sub_path/new_image_nrr_result.nii.gz -aff $sub_path/new_image_affine_matrix.txt -cpp $sub_path/new_image_nrr_cpp.nii.gz

reg_resample -ref $template -flo $seed_img -res $sub_path/propagated_labels.nii.gz -cpp $sub_path/new_image_nrr_cpp.nii.gz -inter 0



for labels in `ls ${sub_path}/slices`
	do 
	
	
	name=${labels##*/}
	ID=${name%.nii.gz}
	echo $ID
	
	
	#bash divider.sh ${sub_ID}/slices/$labels ${sub_ID}/lh/l_${ID} ${sub_ID}/rh/r_${ID}
	
	reg_resample -ref $template -flo ${sub_path}/slices/$labels -res $sub_path/registered_slices/${ID}_propagated.nii.gz -cpp $sub_path/new_image_nrr_cpp.nii.gz -inter 0
	


	done

#removing the slices to save memory
rm -rf ${sub_path}/slices


