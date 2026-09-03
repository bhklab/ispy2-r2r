#!/bin/bash
#SBATCH --job-name=ISPY2_run_mit
#SBATCH --mem=1248G
#SBATCH -t 23:59:59
#SBATCH -c 78
#SBATCH -N 1
#SBATCH -D /cluster/home/t125555uhn/ispy2-r2r
#SBATCH --partition=superhimem
#SBATCH --mail-user=nasim.bondarsahebi@uhn.ca
#SBATCH --mail-type=START,FAIL,END
#SBATCH --output="/cluster/home/t125555uhn/ispy2-r2r/logs/%A-%x.out"

USERNAME="t125555uhn"
source /cluster/home/$USERNAME/.bashrc

cd /cluster/home/$USERNAME/ispy2_r2r

INPUT_DIR=/cluster/projects/radiomics/PublicDatasets/srcdata/Breast/TCIA_ISPY2/ISPY2/
OUTPUT_DIR=/cluster/projects/radiomics/PublicDatasets/procdata/Breast/TCIA_ISPY2/images/mit_ISPY2

pixi run imgtools autopipeline $INPUT_DIR $OUTPUT_DIR \
	--modalities MR,SEG \
    --roi-match-map  Tumor:VOLSER_Analysis_Mask \
    --roi-strategy MERGE \
    --filename-format "{{PatientID}}_{{SampleNumber}}/{{Modality}}_{{SeriesInstanceUID}}/{{ImageID}}.nii.gz" \