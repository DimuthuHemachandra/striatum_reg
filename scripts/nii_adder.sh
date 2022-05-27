#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32000
#SBATCH --time=24:00:00
#SBATCH --job-name=niiadder
#SBATCH --account=ctb-akhanf

template=$1

work_dir=$2

subj_list=$3


x=1

fslmaths $template -bin ${work_dir}/binarized_out.nii.gz

#using a copy of the binarized mask just to keep the original

cp ${work_dir}/binarized_out.nii.gz ${work_dir}/copy_binarized_out.nii.gz


#This loop adds all the masks into one and divide by number of files to get an average to be used as a common mask
for subj in `sed '1d'  $subj_list`

do
	sub_path=${work_dir}/${subj}
	fslmaths ${sub_path}/propagated_labels.nii.gz -bin ${sub_path}/binarized_propagated_labels.nii.gz
	fslmaths ${sub_path}/binarized_propagated_labels.nii.gz -add ${work_dir}/copy_binarized_out.nii.gz ${work_dir}/copy_binarized_out.nii.gz
	echo $(( x++ ))

	mkdir -p ${sub_path}/LH
	mkdir -p ${sub_path}/RH

	for slices in `ls ${sub_path}/registered_slices`
	do 
	
	
		name=${slices##*/}
		ID=${name%.nii.gz}

		./scripts/divider.sh ${sub_path}/registered_slices/$slices ${sub_path}/LH/${name}_lh.nii.gz ${sub_path}/RH/${name}_rh.nii.gz

	done

	#tar cf - ${subj}/registered_slices | pigz -0 -p 32 > ${subj}/registered_slices.tar.gz
	#tar cf - ${subj}/registered_slices | pigz -0 -p 32 > ${subj}/registered_slices.tar.gz
	#rm -rf ${sub_path}/registered_slices
	

	
done

#division by number of files to get average. (Voxels will have a value of 1 if they overlap with the template)
fslmaths ${work_dir}/copy_binarized_out.nii.gz -div $x ${work_dir}/new_mask.nii.gz

#dividing the common mask into L and R
./scripts/divider.sh ${work_dir}/new_mask.nii.gz ${work_dir}/new_mask_lh.nii.gz ${work_dir}/new_mask_rh.nii.gz


#This loop will divide all the slices into lh and rh. Could have included in transform.sh instead here.

#for subj in `sed '1d'  participants.tsv`

#do

	#mkdir -p ${subj}/LH
	#mkdir -p ${subj}/RH

	#for slices in `ls ${subj}/registered_slices`
	#do 
	
	
		#name=${slices##*/}
		#ID=${name%.nii.gz}

		#./divider.sh ${subj}/registered_slices/$slices ${subj}/LH/${name}_lh.nii.gz ${subj}/RH/${name}_rh.nii.gz

	#done

	#tar cf - ${subj}/registered_slices | pigz -0 -p 32 > ${subj}/registered_slices.tar.gz
	#tar cf - ${subj}/registered_slices | pigz -0 -p 32 > ${subj}/registered_slices.tar.gz
	#rm -rf ${subj}/registered_slices
	#rm -rf ${subj}/slices

#done
