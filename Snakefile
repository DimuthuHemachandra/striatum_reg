#!/usr/bin/env python
from os.path import join
from glob import glob
import pandas as pd

configfile: 'cfg/config.yml'


#load participants.tsv file, and strip off sub- from participant_id column
df = pd.read_table(config['participants_tsv'])
subjects = df.participant_id.to_list() 
#subjects = [ s.strip('sub-') for s in subjects ]

#print(subjects)


#wildcard_constraints:
#    subject="[a-zA-Z0-9]+"

componants=['1','2','3','4']
sessions=['Month12','Month24']

sides=['L','R']

analysis_dir = config['analysis_dir']


rule all:
    input:
        reg_files = expand(analysis_dir+'{subject}/propagated_labels.nii.gz',subject=subjects),
        reg_file_last = expand(analysis_dir+'{subject}/registered_slices/3d0999_propagated_labels.nii.gz',subject=subjects),
        lh = expand(analysis_dir+'{subject}/LH/3d0999_propagated.nii.gz_lh.nii.gz',subject=subjects),
        rh = expand(analysis_dir+'{subject}/RH/3d0999_propagated.nii.gz_rh.nii.gz',subject=subjects),
        files = [analysis_dir+'new_mask_lh.nii.gz', analysis_dir+'new_mask_rh.nii.gz']
        #expand(analysis_dir+'{subject}/propagated_labels.nii.gz',subject=subjects)
        #expand('../derivatives/analysis/structural/cortex/gradients/sub-{subject}_ses-Month24/L_emb.npy',subject=subjects)
        

rule striatum_reg: 
    input: 
        template = config['template'],
        dti_4D = config['dti_img'],
        seed_img = config['seed_img']
	        
    params: 
    	subj_path = analysis_dir+'{subject}'
          
    output:  
        seed_reg = analysis_dir+'{subject}/propagated_labels.nii.gz',
        seed_reg_test = analysis_dir+'{subject}/registered_slices/3d0999_propagated_labels.nii.gz',

    group: 'participant'

    threads: 8

    resources: 
    	mem_mb = 8000, 
    	time = 120, #30 mins
    
    shell: 'bash scripts/transform.sh {params.subj_path} {input.dti_4D} {input.seed_img} {input.template}'

rule nii_divider:
    input:
        seed_img = analysis_dir+'{subject}/propagated_labels.nii.gz'
    params:
        subj_path = analysis_dir+'{subject}'
          
    output:  
        mask_L = analysis_dir+'{subject}/LH/3d0999_propagated.nii.gz_lh.nii.gz',
        mask_R = analysis_dir+'{subject}/RH/3d0999_propagated.nii.gz_rh.nii.gz'

    group: 'participant'

    threads: 8

    resources: 
        mem_mb = 8000, 
        time = 120, #30 mins

    shell: 'bash scripts/nii_divider.sh {params.subj_path} {input.seed_img}'

rule nii_add: 
    input: 
        template = config['template'],
        subj_list = config['participants_tsv'],
        seed_img = expand(analysis_dir+'{subject}/propagated_labels.nii.gz',subject=subjects)
    params: 
        work_dir = analysis_dir
          
    output:  
        mask_L = analysis_dir+'new_mask_lh.nii.gz',
        mask_R = analysis_dir+'new_mask_rh.nii.gz'

    group: 'group'
    
    shell: 'bash scripts/nii_adder.sh {input.template} {params.work_dir} {input.subj_list} {input.seed_img}'






     
    
