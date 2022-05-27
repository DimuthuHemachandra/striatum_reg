#!/bin/bash
#SBATCH --ntasks=1
#SBATCH --cpus-per-task=8
#SBATCH --mem=32000
#SBATCH --time=24:00:00
#SBATCH --job-name=makecsv
#SBATCH --account=ctb-akhanf

source ~/py3/bin/activate

python transformer.py








