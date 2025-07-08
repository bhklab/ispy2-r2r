# ============================
# Radiomics Feature Extraction Snakemake Workflow using unified Python script
# ============================

# Load configuration
# configfile: dmpdirs.CONFIG / "datasets" / "ISPY2.yaml"

# Import required modules
from damply import dirs as dmpdirs
import pandas as pd
import os


# -----------------------------
# Metadata setup
# -----------------------------
COMBINED_DATA_NAME = config["DATA_SOURCE"] + "_" + config["DATASET_NAME"]

# Load mit_index metadata CSV
mit_index_file = (
    dmpdirs.PROCDATA
    / COMBINED_DATA_NAME
    / "images"
    / f"mit_{config['DATASET_NAME']}"
    / f"mit_{config['DATASET_NAME']}_index-simple.csv"
)

# Read and filter metadata
df = pd.read_csv(mit_index_file)
df = df[~df["filepath"].str.startswith("ROI_")]
# df["PatientName"] = df["filepath"].str.extract(r'^(ISPY2-\d{6}_\d{4})')
df["PatientName"] = df["filepath"].str.extract(r'^([A-Z0-9\-]+_\d{4})')


# Subset for MR and SEG
df_mr = df[df["ImageID"] == "MR"]
df_seg = df[df["ImageID"] == "GTV"]

# Merge MR and SEG by patient
merged = pd.merge(df_mr, df_seg, on="PatientName", suffixes=("_MR", "_SEG"))

# Map full file paths per patient
path_table = pd.DataFrame([
    {
        "patient": str(row["PatientName"]),
        "mr_path": str(dmpdirs.PROCDATA / str(COMBINED_DATA_NAME) / "images" /f"mit_{config['DATASET_NAME']}" / str(row["filepath_MR"]) ),
        "seg_path": str(dmpdirs.PROCDATA / str(COMBINED_DATA_NAME) / "images" /f"processed_{config['DATASET_NAME']}" / str(row["PatientName"]) /
        Path(str(row["filepath_SEG"])).parent.name / "bin_GTV.nii.gz"
        )
    }
    for _, row in merged.iterrows()
])

paths = {
    row["patient"]: {"mr_path": row["mr_path"], "seg_path": row["seg_path"]}
    for _, row in path_table.iterrows()
}

# For testing, only use first patient
patients = list(paths.keys())

# -----------------------------
# Rule 1: Crop MR and SEG
# -----------------------------
rule crop_mri_seg:
    input:
        MR_input=lambda wc: paths[wc.patient]["mr_path"],
        SEG_input=lambda wc: paths[wc.patient]["seg_path"]
    output:
        Cropped_MR=dmpdirs.PROCDATA / f"{COMBINED_DATA_NAME}/images/mit_{config['DATASET_NAME']}/{{patient}}/Cropped_MR_Mask/Cropped_MR.nii.gz",
        Cropped_Binary_Mask=dmpdirs.PROCDATA / f"{COMBINED_DATA_NAME}/images/mit_{config['DATASET_NAME']}/{{patient}}/Cropped_MR_Mask/Cropped_Binary_Mask.nii.gz"
    shell:
        """
        QT_QPA_PLATFORM=offscreen pixi run python workflow/scripts/radiomics/feature_extraction/preprocessing.py crop_mri_seg \
        --mr {input.MR_input} \
        --seg {input.SEG_input} \
        --out-mr {output.Cropped_MR} \
        --out-mask {output.Cropped_Binary_Mask}
        """

        
# -----------------------------
# Rule 2: Apply N4 bias correction to cropped MR
# -----------------------------
rule MR_bias_correct:
    input:
        Cropped_MR=dmpdirs.PROCDATA / f"{COMBINED_DATA_NAME}/images/mit_{config['DATASET_NAME']}/{{patient}}/Cropped_MR_Mask/Cropped_MR.nii.gz"
    output:
        BiasCorrected_Cropped_MR=dmpdirs.PROCDATA / f"{COMBINED_DATA_NAME}/images/mit_{config['DATASET_NAME']}/{{patient}}/Cropped_MR_Mask/BiasCorrected_Cropped_MR.nii.gz"
    shell:
        """
        QT_QPA_PLATFORM=offscreen pixi run python workflow/scripts/radiomics/feature_extraction/preprocessing.py MR_bias_correct \
        --input {input.Cropped_MR} \
        --output {output.BiasCorrected_Cropped_MR}
        """


# -----------------------------
# Rule 3: Extract radiomic features
# -----------------------------
rule extract_feature:
    input:
        BiasCorrected_Cropped_MR=dmpdirs.PROCDATA / f"{COMBINED_DATA_NAME}/images/mit_{config['DATASET_NAME']}/{{patient}}/Cropped_MR_Mask/BiasCorrected_Cropped_MR.nii.gz",
        Cropped_Binary_Mask= dmpdirs.PROCDATA / f"{COMBINED_DATA_NAME}/images/mit_{config['DATASET_NAME']}/{{patient}}/Cropped_MR_Mask/Cropped_Binary_Mask.nii.gz"
    params:
        pyradiomics_param_file_path="/cluster/home/t125555uhn/ispy2-r2r/config/pyradiomics/pyradiomics_original_all_features.yaml"
    output:
        feature_row=dmpdirs.PROCDATA / f"{COMBINED_DATA_NAME}/features/tmp_{{patient}}.csv"
    shell:
        """
        QT_QPA_PLATFORM=offscreen pixi run python workflow/scripts/radiomics/feature_extraction/preprocessing.py extract_feature \
        --image {input.BiasCorrected_Cropped_MR} \
        --mask {input.Cropped_Binary_Mask} \
        --param {params.pyradiomics_param_file_path} \
        --output {output.feature_row}
        """


# -----------------------------
# Rule 5: Merge features from all patients
# -----------------------------
rule merge_features:
    output:
        dmpdirs.RESULTS / f"radiomics/{COMBINED_DATA_NAME}_features.csv"
    shell:
        """
        mkdir -p $(dirname {output})
        files=$(ls {dmpdirs.PROCDATA}/{COMBINED_DATA_NAME}/features/tmp_*.csv 2>/dev/null || true)

        if [ -n "$files" ]; then
            QT_QPA_PLATFORM=offscreen pixi run python workflow/scripts/radiomics/feature_extraction/preprocessing.py merge_features \
                --inputs $files \
                --output {output}
        else
            echo "No input CSVs found. Creating empty file: {output}"
            echo "" > {output}
        fi
        """

