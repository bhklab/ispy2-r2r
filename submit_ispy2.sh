#!/bin/bash
#SBATCH --job-name=ISPY2_PIPELINE
#SBATCH --mem=64G
#SBATCH -c 10              # Update: request 10 cores
#SBATCH -n 1
#SBATCH -t 10:00:00
#SBATCH --partition=himem
#SBATCH -o logs/ispy2_%j.out
#SBATCH -e logs/ispy2_%j.err

cd /cluster/home/t125555uhn/ispy2-r2r

# Run Snakemake via Pixi with 10 cores
#pixi run snakemake --cores 4 --configfile config/datasets/ISPY2.yaml
pixi run snakemake --cores 4 --rerun-incomplete --configfile config/datasets/ISPY2.yaml

#pixi run snakemake -s workflow/Snakefile --configfile config/datasets/ISPY2.yaml --cores 10 --rerun-incomplete

