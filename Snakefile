from damply import dirs as dmpdirs

# could alternatively pass this in the CLI via `--configfile $CONFIG/config.yaml`
# configfile: dmpdirs.CONFIG / "datasets" / "ISPY2.yaml"

# Load the config file
configfile: dmpdirs.CONFIG / "datasets" / "ISPY2.yaml"

COMBINED_DATA_NAME = config['DATA_SOURCE'] + "_" + config['DATASET_NAME']

#include: "scripts/radiomics/mit/run_mit.smk"
include: "scripts/radiomics/feature_extraction/run_feature_extraction.smk"

# 1. Binirize the masks
# rule binarize_masks:
#     input:
#         config="config/datasets/ISPY2.yaml"
#     output:
#         touch("logs/binarize_masks.done")
#     shell:
#         """
#         pixi run python workflow/scripts/radiomics/readii/process_masks.py --dataset ISPY2.yaml
#         touch {output}
#         """

# 2. feature extraction
rule all:
    input:
        dmpdirs.RESULTS / f"radiomics/{COMBINED_DATA_NAME}/feature_extracted.csv"

# rule all:
#     # Target rule
#     input:
#         mit_autopipeline_index=dmpdirs.PROCDATA / COMBINED_DATA_NAME / "images" / f"mit_{config['DATASET_NAME']}" / f"mit_{config['DATASET_NAME']}_index.csv",
#         mit_niftis_directory=dmpdirs.PROCDATA / COMBINED_DATA_NAME / "images" / f"mit_{config['DATASET_NAME']}",
#         feature_extraction_index_directory=dmpdirs.PROCDATA / COMBINED_DATA_NAME / "features" / f"{config['EXTRACTION']['METHOD']}",
#         feature_extraction_index_file=dmpdirs.PROCDATA / COMBINED_DATA_NAME / "features" / f"{config['EXTRACTION']['METHOD']}" / f"{config['EXTRACTION']['METHOD']}_{config['DATASET_NAME']}_index.csv"
    

# rule run_extraction_index:
#     input:
#         mit_simple_index_file=dmpdirs.PROCDATA / COMBINED_DATA_NAME / "images" / f"mit_{config['DATASET_NAME']}" / f"mit_{config['DATASET_NAME']}_index-simple.csv",
#     output:
#         feature_extraction_index_directory=directory(dmpdirs.PROCDATA / COMBINED_DATA_NAME / "features" / f"{config['EXTRACTION']['METHOD']}"),
#         feature_extraction_index_file=dmpdirs.PROCDATA / COMBINED_DATA_NAME / "features" / f"{config['EXTRACTION']['METHOD']}" / f"{config['EXTRACTION']['METHOD']}_{config['DATASET_NAME']}_index.csv"
#     params:
#         dataset=config['DATASET_NAME'],
#         method=config['EXTRACTION']['METHOD']
#     shell:
#         "python workflow/scripts/radiomics/feature_extraction/index.py --dataset {params.dataset} --method {params.method}"
