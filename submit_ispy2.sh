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
#pixi run snakemake --cores 10 --configfile config/datasets/ISPY2.yaml --dry-run
#pixi run python -m snakemake --cores 10 --configfile config/datasets/ISPY2.yaml --dry-run

# Run Snakemake via Pixi with 10 cores
#pixi run snakemake --cores 10 --configfile config/datasets/ISPY2.yaml --rerun-incomplete
pixi run snakemake --cores 10 --jobs 10 --configfile config/datasets/ISPY2.yaml --rerun-incomplete --keep-going


# pixi run snakemake --cores 4 --rerun-incomplete --configfile config/datasets/ISPY2.yaml
# pixi run snakemake -s workflow/Snakefile --configfile config/datasets/ISPY2.yaml --cores 10 --rerun-incomplete

# usefull command lines:
# ssh t125555uhn@h4huhnlogin1.uhnresearch.ca
# salloc -t 2:00:00 -p short                                                                                                         
# pixi run snakemake -n --cores 2 --configfile config/datasets/ISPY2.yaml
# pixi run snakemake --cores 2 --configfile config/datasets/ISPY2.yaml
#rule run_mit_index is failing 
# manully --> mkdir -p data/rawdata/TCIA_ISPY2/.imgtools/ISPY2
# pixi run snakemake --unlock
# rm -rf .snakemake
# pixi run snakemake --unlock --configfile config/datasets/ISPY2.yaml

# sbatch submit_ispy2.sh
#  ls *  | wc -l  
# scontrol show job 2658139                                                                                           
# sacct -j 2747042

# 2643/2683 (40 samples)
