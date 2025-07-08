#!/bin/bash
#SBATCH --job-name=ACRIN-6698_PIPELINE
#SBATCH --mem=64G
#SBATCH -c 10              
#SBATCH -n 1
#SBATCH -t 24:00:00
#SBATCH --partition=superhimem
#SBATCH --mail-user=nasim.bondarsahebi@uhn.ca
#SBATCH -o logs/ispy2_%j.out
#SBATCH -e logs/ispy2_%j.err

# Project root
cd "${HOME}/ispy2-r2r"

# Run Snakemake via Pixi with 10 cores
pixi run snakemake --cores 10 --jobs 10 --configfile config/datasets/ACRIN-6698.yaml --rerun-incomplete --keep-going

# Note: 929/987  samples done

