  
#!/bin/bash



ID=${labels##*-}
img=$1

#compute ROIs for MNI left/right hemi
dimx=`fslval ${img} dim1`
halfx=$(echo "scale=0; $dimx/2" | bc)


roi_left="0 ${halfx} 0 -1 0 -1 0 -1"
roi_right="$(($halfx+1)) -1 0 -1 0 -1 0 -1"

#echo "roi_left $roi_left"
#echo "roi_right $roi_right"

#mask with left/right  ROI:
fslmaths $img -roi $roi_left $2
fslmaths $img -roi $roi_right $3





