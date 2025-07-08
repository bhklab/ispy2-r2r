#!/bin/bash
#SBATCH --job-name=ISPY2_PIPELINE
#SBATCH --mem=64G
#SBATCH -c 10              # Update: request 10 cores
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH --partition=superhimem
#SBATCH --mail-user=nasim.bondarsahebi@uhn.ca
#SBATCH -o logs/ispy2_%j.out
#SBATCH -e logs/ispy2_%j.err

#cd /cluster/home/t125555uhn/ispy2-r2r
# Use relative path to project root
cd "${HOME}/ispy2-r2r"

# Run Snakemake in dry-run mode
#pixi run python -m snakemake --cores 10 --configfile config/datasets/ISPY2.yaml --dry-run

# Run Snakemake via Pixi with 10 cores
pixi run snakemake --cores 10 --jobs 10 --configfile config/datasets/ISPY2.yaml --rerun-incomplete --keep-going

# 2597/2683 samples done
