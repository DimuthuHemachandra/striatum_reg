#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32000
#SBATCH --time=24:00:00
#SBATCH --job-name=niiadder
#SBATCH --account=ctb-akhanf


sub_path=$1



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
rm -rf ${sub_path}/registered_slices
	

	
