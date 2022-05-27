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



"""

rule get_matrix_m24: 
    input: 
        Right = '../derivatives/analysis/structural/connMaps/LH/sub-{subject}_ses-Month24-connMap_lh.mat',
        Left = '../derivatives/analysis/structural/connMaps/RH/sub-{subject}_ses-Month24-connMap_rh.mat'
           
    output:  
	    R_emb = '../derivatives/analysis/structural/cortex/gradients/sub-{subject}_ses-Month24/L_matrix.npy', 
	    L_emb = '../derivatives/analysis/structural/cortex/gradients/sub-{subject}_ses-Month24/R_matrix.npy',
	    
    script: 'scripts/striatum.py'


#Calculating gradients
####################################################################################
rule get_gradients_month12: 
    input: 
        matrix_files_L = expand('../derivatives/analysis/structural/cortex/gradients/sub-{subject}_ses-Month12/L_matrix.npy',subject=subjects),
        matrix_files_R = expand('../derivatives/analysis/structural/cortex/gradients/sub-{subject}_ses-Month12/R_matrix.npy',subject=subjects)

    params: month = 'month12',
            subjects = subjects,
            grad_path = config['analysis_dir']+'gradients/bs_emb/'
    output: 
            grad_sbctx_L = '../derivatives/analysis/structural/cortex/gradients/bs_emb/emb_sbctx_L_month12.pickle',
            grad_sbctx_R = '../derivatives/analysis/structural/cortex/gradients/bs_emb/emb_sbctx_R_month12.pickle',
            aligned_grad_sbctx_L = '../derivatives/analysis/structural/cortex/gradients/bs_emb/aligned_emb_sbctx_L_month12.pickle',
            aligned_grad_sbctx_R = '../derivatives/analysis/structural/cortex/gradients/bs_emb/aligned_emb_sbctx_R_month12.pickle',

    group: 'group'
    script: 'scripts/gradients_new.py'


"""
"""
rule get_surface_gradients:
	input: gradient_csv = "/home/dimuthu1/scratch/project2/derivatives/analysis/cortex/gradients/sub-{subject}/sub-{subject}_gradients.csv",
	       surf_lh = config['surf_label_lh'],
	       surf_rh = config['surf_label_rh']

	params: stat_out_path = "/home/dimuthu1/scratch/project2/derivatives/analysis/cortex/gradients/sub-{subject}/surfaces"

	output: projected_image = '/home/dimuthu1/scratch/project2/derivatives/analysis/cortex/gradients/sub-{subject}/surfaces/plotL_grad_{componant}.func.gii'

	#conda: 'cfg/bspace.yml'
	group: 'pre_align'
	shell: 'mkdir -p {params.stat_out_path} && bash scripts/get_surf {input.surf_lh} {input.surf_rh} {input.gradient_csv} {params.stat_out_path}'

rule test_group:
    input: grads_path = '../derivatives/analysis/cortex/gradients'
              
    params: subj = subjects,
            aligned_grads_path = '../derivatives/analysis/cortex/aligned_gradients'

    output: aligned_grads = expand('../derivatives/analysis/cortex/aligned_gradients/sub-{subject}_gradients.csv',subject=subjects)


    group: 'post_align'
    script: 'scripts/procrust.py'


rule get_stat:
    input: stat_lh = config['stat_path_lh'],
           stat_rh = config['stat_path_rh']
           

    params: stat_out_path = '../derivatives/analysis/cortex/hcp_stat/{subject}'

    output: stat_csv_lh = '../derivatives/analysis/cortex/hcp_stat/sub-{subject}/{subject}_hcp_stat_lh.csv',
    		stat_csv_rh = '../derivatives/analysis/cortex/hcp_stat/sub-{subject}/{subject}_hcp_stat_rh.csv'

    group: 'stat'
    script: 'scripts/hcp_stat.py'

rule get_myelin_stat:
    input: myelin_img = "/home/dimuthu1/scratch/project2/derivatives/myelin_volume/{subject}/T1wDividedByT2w.nii.gz",
           hcp_img = config['HCP_seg_nii'],
           hcp_360_labels = config['HCP_360_labels']
             

    params: stat_out_path = '/home/dimuthu1/scratch/project2/derivatives/analysis/cortex/hcp_stat/sub-{subject}'


    output: stat_csv_lh = '/home/dimuthu1/scratch/project2/derivatives/analysis/cortex/hcp_stat/sub-{subject}/sub-{subject}_mean-myelin_L.txt',
            stat_csv_rh = '/home/dimuthu1/scratch/project2/derivatives/analysis/cortex/hcp_stat/sub-{subject}/sub-{subject}_mean-myelin_R.txt'

    group: 'stat'

    resources: 
           time = 120 #30 mins

    shell: 'bash scripts/myelin_stat.sh {wildcards.subject} {input.myelin_img} {input.hcp_img} {input.hcp_360_labels} {params.stat_out_path}'






rule get_stat_plots:
    input: hcp_lh = '../derivatives/analysis/cortex/hcp_stat/sub-{subject}/{subject}_hcp_stat_lh.csv',
           hcp_rh = '../derivatives/analysis/cortex/hcp_stat/sub-{subject}/{subject}_hcp_stat_rh.csv',
           gradient = '../derivatives/analysis/cortex/aligned_gradients/sub-{subject}_gradients.csv'  

    output: lh_stat_plots = '../derivatives/analysis/cortex/hcp_stat/sub-{subject}/{subject}_hcp_all_stat_lh.png',
    		rh_stat_plots = '../derivatives/analysis/cortex/hcp_stat/sub-{subject}/{subject}_hcp_sall_stat_rh.png'

    group: 'stat'
    script: 'scripts/combine_csv.py'


rule get_group_plots:
    input: hcp_path = directory('../derivatives/analysis/cortex/hcp_stat'),
           grad_csv_path = directory('../derivatives/analysis/cortex/aligned_gradients')
              
    params: subj = subjects,
            out_path = '../derivatives/analysis/cortex/group_analysis'

    output: aligned_grads = ['../derivatives/analysis/cortex/group_analysis/group_stat_L.png','../derivatives/analysis/cortex/group_analysis/group_stat_R.png']

    group: 'group_analysis'
    script: 'scripts/group_plot.py'
"""
"""
rule import_template_seed:
    input: join(config['template_seg_dir'],config['template_seg_nii'])
    output: 'diffparc/template_masks/sub-{template}_hemi-{hemi}_desc-{seed}_mask.nii.gz'
    log: 'logs/import_template_seed/{template}_{seed}_{hemi}.log'
    group: 'pre_track'
    shell: 'cp -v {input} {output} &> {log}'


rule transform_to_subject:
    input: 
        seed = rules.import_template_seed.output,
        affine = lambda wildcards: glob(join(config['ants_template_dir'],config['ants_affine_mat'].format(**wildcards))),
        invwarp = lambda wildcards: glob(join(config['ants_template_dir'],config['ants_invwarp_nii'].format(**wildcards))),
        ref = 'diffparc/sub-{subject}/masks/lh_rh_targets_native.nii.gz'
    output: 'diffparc/sub-{subject}/masks/seed_from-{template}_{seed}_{hemi}.nii.gz'
    envmodules: 'ants'
    singularity: config['singularity_neuroglia']
    log: 'logs/transform_to_subject/{template}_sub-{subject}_{seed}_{hemi}.log'
    group: 'pre_track'
    shell:
        'antsApplyTransforms -d 3 --interpolation NearestNeighbor -i {input.seed} -o {output} -r {input.ref} -t [{input.affine},1] -t {input.invwarp} &> {log}'
    
    
rule resample_targets:
    input: 
        dwi = join(config['prepdwi_dir'],'bedpost','sub-{subject}','mean_S0samples.nii.gz'),
        targets = 'diffparc/sub-{subject}/masks/lh_rh_targets_native.nii.gz'
    params:
        seed_resolution = config['probtrack']['seed_resolution']
    output:
        mask = 'diffparc/sub-{subject}/masks/brain_mask_dwi.nii.gz',
        mask_res = 'diffparc/sub-{subject}/masks/brain_mask_dwi_resampled.nii.gz',
        targets_res = 'diffparc/sub-{subject}/masks/lh_rh_targets_dwi.nii.gz'
    singularity: config['singularity_neuroglia']
    log: 'logs/resample_targets/sub-{subject}.log'
    group: 'pre_track'
    shell:
        'fslmaths {input.dwi} -bin {output.mask} &&'
        'mri_convert {output.mask} -vs {params.seed_resolution} {params.seed_resolution} {params.seed_resolution} {output.mask_res} -rt nearest &&'
        'reg_resample -flo {input.targets} -res {output.targets_res} -ref {output.mask_res} -NN 0  &> {log}'

rule resample_seed:
    input: 
        seed = rules.transform_to_subject.output,
        mask_res = 'diffparc/sub-{subject}/masks/brain_mask_dwi_resampled.nii.gz'
    output:
        seed_res = 'diffparc/sub-{subject}/masks/seed_from-{template}_{seed}_{hemi}_resampled.nii.gz',
    singularity: config['singularity_neuroglia']
    log: 'logs/resample_seed/{template}_sub-{subject}_{seed}_{hemi}.log'
    group: 'pre_track'
    shell:
        'reg_resample -flo {input.seed} -res {output.seed_res} -ref {input.mask_res} -NN 0 &> {log}'

    
    

rule split_targets:
    input: 
        targets = 'diffparc/sub-{subject}/masks/lh_rh_targets_dwi.nii.gz',
    params:
        target_nums = lambda wildcards: [str(i) for i in range(len(targets))],
        target_seg = expand('diffparc/sub-{subject}/targets/{target}.nii.gz',target=targets,allow_missing=True)
    output:
        target_seg_dir = directory('diffparc/sub-{subject}/targets')
    singularity: config['singularity_neuroglia']
    log: 'logs/split_targets/sub-{subject}.log'
    threads: 32 
    group: 'pre_track'
    shell:
        'mkdir -p {output} && parallel  --jobs {threads} fslmaths {input.targets} -thr {{1}} -uthr {{1}} -bin {{2}} &> {log} ::: {params.target_nums} :::+ {params.target_seg}'

rule gen_targets_txt:
    input:
        target_seg_dir = 'diffparc/sub-{subject}/targets'
    params:
        target_seg = expand('diffparc/sub-{subject}/targets/{target}.nii.gz',target=targets,allow_missing=True)
    output:
        target_txt = 'diffparc/sub-{subject}/target_images.txt'
    log: 'logs/get_targets_txt/sub-{subject}.log'
    group: 'pre_track'
    run:
        f = open(output.target_txt,'w')
        for s in params.target_seg:
            f.write(f'{s}\n')
        f.close()


rule run_probtrack:
    input:
        seed_res = rules.resample_seed.output,
        target_txt = rules.gen_targets_txt.output,
        mask = 'diffparc/sub-{subject}/masks/brain_mask_dwi.nii.gz',
        target_seg_dir = 'diffparc/sub-{subject}/targets'
    params:
        bedpost_merged = join(config['prepdwi_dir'],'bedpost','sub-{subject}','merged'),
        probtrack_opts = config['probtrack']['opts'],
        out_target_seg = expand('diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}/seeds_to_{target}.nii.gz',target=targets,allow_missing=True)
    output:
        probtrack_dir = directory('diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}')
    threads: 2
    resources: 
        mem_mb = 8000, 
        time = 30, #30 mins
        gpus = 1 #1 gpu
    log: 'logs/run_probtrack/{template}_sub-{subject}_{seed}_{hemi}.log'
    shell:
        'mkdir -p {output.probtrack_dir} && probtrackx2_gpu --samples={params.bedpost_merged}  --mask={input.mask} --seed={input.seed_res} ' 
        '--targetmasks={input.target_txt} --seedref={input.seed_res} --nsamples={config[''probtrack''][''nsamples'']} ' 
        '--dir={output.probtrack_dir} {params.probtrack_opts} -V 2  &> {log}'


rule transform_conn_to_template:
    input:
        connmap_dir = 'diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}',
        affine =  lambda wildcards: glob(join(config['ants_template_dir'],config['ants_affine_mat'].format(subject=wildcards.subject))),
        warp =  lambda wildcards: glob(join(config['ants_template_dir'],config['ants_warp_nii'].format(subject=wildcards.subject))),
        ref = join(config['ants_template_dir'],config['ants_ref_nii'])
    params:
        in_connmap_3d = expand('diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}/seeds_to_{target}.nii.gz',target=targets,allow_missing=True),
        out_connmap_3d = expand('diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}_warped/seeds_to_{target}_space-{template}.nii.gz',target=targets,allow_missing=True)
    output:
        connmap_dir = directory('diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}_warped')
    envmodules: 'ants'
    singularity: config['singularity_neuroglia']
    threads: 32
    resources:
        mem_mb = 128000
    log: 'logs/transform_conn_to_template/sub-{subject}_{seed}_{hemi}_{template}.log'
    group: 'post_track'
    shell:
        'mkdir -p {output} && ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=2 parallel  --jobs {threads} antsApplyTransforms -d 3 --interpolation Linear -i {{1}} -o {{2}}  -r {input.ref} -t {input.warp} -t {input.affine} &> {log} :::  {params.in_connmap_3d} :::+ {params.out_connmap_3d}' 


rule save_connmap_template_npz:
    input:
        mask = 'diffparc/template_masks/sub-{template}_hemi-{hemi}_desc-{seed}_mask.nii.gz',
        connmap_dir = 'diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}_warped'
    params:
        connmap_3d = expand('diffparc/sub-{subject}/probtrack_{template}_{seed}_{hemi}_warped/seeds_to_{target}_space-{template}.nii.gz',target=targets,allow_missing=True),
    output:
        connmap_npz = 'diffparc/sub-{subject}/connmap/sub-{subject}_space-{template}_seed-{seed}_hemi-{hemi}_connMap.npz'
    log: 'logs/save_connmap_to_template_npz/sub-{subject}_{seed}_{hemi}_{template}.log'
    group: 'post_track'
    script: 'scripts/save_connmap_template_npz.py'

rule gather_connmap_group:
    input:
        connmap_npz = expand('diffparc/sub-{subject}/connmap/sub-{subject}_space-{template}_seed-{seed}_hemi-{hemi}_connMap.npz',subject=subjects,allow_missing=True)
    output:
        connmap_group_npz = 'diffparc/connmap/group_space-{template}_seed-{seed}_hemi-{hemi}_connMap.npz'
    log: 'logs/gather_connmap_group/{seed}_{hemi}_{template}.log'
    run:
        import numpy as np
        
        #load first file to get shape
        data = np.load(input['connmap_npz'][0])
        affine = data['affine']
        mask = data['mask']
        conn_shape = data['conn'].shape
        nsubjects = len(input['connmap_npz'])
        conn_group = np.zeros([nsubjects,conn_shape[0],conn_shape[1]])
        
        for i,npz in enumerate(input['connmap_npz']):
            data = np.load(npz)
            conn_group[i,:,:] = data['conn']
            
        #save conn_group, mask and affine
        np.savez(output['connmap_group_npz'], conn_group=conn_group,mask=mask,affine=affine)
     
rule spectral_clustering:
    input:
        connmap_group_npz = 'diffparc/connmap/group_space-{template}_seed-{seed}_hemi-{hemi}_connMap.npz'
    params:
        max_k = config['max_k']
    output:
        cluster_k = expand('diffparc/clustering/group_space-{template}_seed-{seed}_hemi-{hemi}_method-spectralcosine_k-{k}_cluslabels.nii.gz',k=range(2,config['max_k']+1),allow_missing=True)
    script: 'scripts/spectral_clustering.py'
        
"""
     
    
