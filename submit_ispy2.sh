#!/bin/bash
#SBATCH --job-name=ISPY2_PIPELINE
#SBATCH --mem=64G
#SBATCH -c 10              
#SBATCH -n 1
#SBATCH -t 23:59:59
#SBATCH --partition=superhimem
#SBATCH --mail-user=nasim.bondarsahebi@uhn.ca
#SBATCH -o logs/ispy2_%j.out
#SBATCH -e logs/ispy2_%j.err

cd /cluster/home/t125555uhn/ispy2-r2r

# Run Snakemake via Pixi with 10 cores
#pixi run snakemake --cores 4 --configfile config/datasets/ISPY2.yaml
pixi run snakemake --cores 4 --rerun-incomplete --configfile config/datasets/ISPY2.yaml
