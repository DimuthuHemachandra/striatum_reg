import matplotlib.pyplot as plt
import numpy as np
import pandas as pd
#from nilearn.image import load_img
#import nibabel as nib
import os
import glob
import random

import nibabel as nib


df = pd.read_table('participants.tsv')
subjects = df.participant_id.to_list() 

#subjects = ['sub-3116_ses-Month12']

mask_img_L = nib.load('new_mask_lh.nii.gz') #This image is transformed to mni space and reduced to low resolution
mask_data_L = mask_img_L.get_data()

mask_img_R = nib.load('new_mask_rh.nii.gz') #This image is transformed to mni space and reduced to low resolution
mask_data_R = mask_img_R.get_data()


for subj in subjects:


	slices_LH = glob.glob(subj+'/LH/*.nii.gz', recursive=False)
	slices_RH = glob.glob(subj+'/RH/*.nii.gz', recursive=False)

	#print(slices)

	matrix_L=[]
	matrix_R=[]
	#matrix = np.zeros((1000, 1400))
	for l,slice in enumerate(slices_LH):


		dti_img = nib.load(slice) #this is one slice of the dti 4d image transformed to mni space
		dti_data = dti_img.get_data()

		masked_dti = dti_data[mask_data_L==1]
		matrix_L.append(masked_dti)

	for l,slice in enumerate(slices_RH):


		dti_img = nib.load(slice) #this is one slice of the dti 4d image transformed to mni space
		dti_data = dti_img.get_data()

		masked_dti = dti_data[mask_data_R==1]
		matrix_R.append(masked_dti)



		


	#connectivity = np.array(matrix)
	#print(np.shape(connectivity))
	#print(val)
	np.savetxt(subj+'/'+subj+'_LH_data.csv', matrix_L, fmt='%i', delimiter=',')
	np.savetxt(subj+'/'+subj+'_RH_data.csv', matrix_R, fmt='%i', delimiter=',')
	#np.savetxt(snakemake.output.data_csv, matrix, fmt='%i', delimiter=',')
	#final_img = nib.Nifti1Image(mask_data, mask_img.affine, mask_img.header)
	#nib.save(final_img,snakemake.output.adjusted_mask) 


	
"""
def get_projections():

  img = load_img("HCP-MMP1.nii.gz")
  data = (img.get_data())
  x = np.shape(data)[0]
  y = np.shape(data)[1]
  z = np.shape(data)[2]
  R_rois = np.loadtxt("R_coords.txt")
  L_rois = np.loadtxt("L_coords.txt")
  #rois = coords.values
  R_vals = np.column_stack((R_gradient, R_rois))
  L_vals = np.column_stack((L_gradient, L_rois))


  new_img = data
  for i in range(x):
     for j in range (y):
             for k in range (z):
                 if data[i,j,k] in R_vals[:,1].tolist():
                     index = np.where(R_vals[:,1] == data[i,j,k])[0][0]
                     #print(val.index(data[i,j,k]))
                     new_img[i,j,k]=R_vals[index,0]*1000

                 elif data[i,j,k] in L_vals[:,1].tolist():
                     index = np.where(L_vals[:,1] == data[i,j,k])[0][0]
                     #print(val.index(data[i,j,k]))
                     new_img[i,j,k]=L_vals[index,0]*1000
                 else:
                     new_img[i,j,k]=3000

  final_img = nib.Nifti1Image(new_img, img.affine, img.header)
  nib.save(final_img,"final_image.nii")


get_projections()"""


