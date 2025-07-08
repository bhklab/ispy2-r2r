#!/usr/bin/env python3

# This unified script includes multiple:
# - crop_mri_seg: Crop MR and SEG mask 
# - MR_bias_correct: Apply N4ITK bias field correction
# - extract_feature: Extract radiomics features using PyRadiomics
# - merge_features: Merge feature CSVs from multiple patients

import argparse
import SimpleITK as sitk
import numpy as np
import pandas as pd
import sys
import os
from readii.feature_extraction import singleRadiomicFeatureExtraction


# ------------------------------
# Step 1: Crop MRI using SEG mask
# ------------------------------
def crop_mri_seg(args):
    """
    Crop an MRI scan using a corresponding segmentation Binirized (SEG) mask.
    Outputs:
        - Cropped MRI image
    """
    if not os.path.exists(args.mr):
        raise FileNotFoundError(f"MR image not found: {args.mr}")
    if not os.path.exists(args.seg):
        raise FileNotFoundError(f"SEG image not found: {args.seg}")
    
    mr = sitk.ReadImage(args.mr)
    seg = sitk.ReadImage(args.seg)

    # Convert to arrays
    mr_array = sitk.GetArrayFromImage(mr)
    binary_mask_arr = sitk.GetArrayFromImage(seg)

    # Crop the size of mr to the siz eof the mask 
    # mask_array = seg_array[]
    cropped_mr_array = mr_array[:binary_mask_arr.shape[0]]
    
    # Convert binary mask array back to a SimpleITK image
    binary_mask = sitk.GetImageFromArray(binary_mask_arr)
    cropped_mr = sitk.GetImageFromArray(cropped_mr_array)

    # Copy metadata
    cropped_mr.SetSpacing(mr.GetSpacing())
    cropped_mr.SetOrigin(mr.GetOrigin())
    cropped_mr.SetDirection(mr.GetDirection())
    binary_mask.SetSpacing(seg.GetSpacing())
    binary_mask.SetOrigin(seg.GetOrigin())
    binary_mask.SetDirection(seg.GetDirection())
    # Save results
    sitk.WriteImage(cropped_mr, args.out_mr)
    sitk.WriteImage(binary_mask, args.out_mask)


# ------------------------------
# Step 2: Bias correction using N4ITK
# ------------------------------
def MR_bias_correct(args):
    """
    Apply N4 bias field correction to an MRI image.
    Output:
        - Bias-corrected MRI image
    """
    # Convert image to float32 
    img = sitk.Cast(sitk.ReadImage(args.input), sitk.sitkFloat32)

    # Apply N4 Bias Field Correction
    corrected = sitk.N4BiasFieldCorrectionImageFilter().Execute(img)
    sitk.WriteImage(corrected, args.output)

# ------------------------------
# Step 3: Radiomics Feature Extraction
# ------------------------------
def extract_feature(args):
    """
    Extract radiomics features from a preprocessed MRI and binary mask using PyRadiomics.
    Output:
        - A single-row CSV containing extracted features
    """
    image = sitk.ReadImage(args.image)
    mask = sitk.ReadImage(args.mask)

    # Check if the mask has any label == 1
    mask_array = sitk.GetArrayFromImage(mask)
    if not np.any(mask_array == 1):
        print(f"[SKIP] No label 1 found in mask: {args.mask}")
        # Make sure the folder exists
        os.makedirs(os.path.dirname(args.output), exist_ok=True)
        # Write empty file to correct path (tmp_{patient}.csv)
        pd.DataFrame().to_csv(args.output, index=False)
        sys.exit(0)

    # Run PyRadiomics feature extraction
    radiomic_features_dict = singleRadiomicFeatureExtraction(image, mask, args.param, randomSeed=10)
    pd.DataFrame([radiomic_features_dict]).to_csv(args.output, index=False)

# def extract_feature(args):
#     import traceback
#     import shutil

#     try:
#         image = sitk.ReadImage(args.image)
#         mask = sitk.ReadImage(args.mask)

#         # Check if the mask has any label == 1
#         mask_array = sitk.GetArrayFromImage(mask)
#         if not np.any(mask_array == 1):
#             print(f"[SKIP] Empty mask for: {args.mask}")
#             raise ValueError("No label 1 found in mask.")

#         # Run PyRadiomics feature extraction
#         radiomic_features_dict = singleRadiomicFeatureExtraction(
#             image, mask, args.param, randomSeed=10
#         )

#         if not radiomic_features_dict or not isinstance(radiomic_features_dict, dict):
#             raise ValueError("Radiomic feature extraction returned None or invalid.")

#         pd.DataFrame([radiomic_features_dict]).to_csv(args.output, index=False)

#     except Exception as e:
#         print(f"[ERROR] Skipping patient due to failure: {e}")
#         traceback.print_exc()

#         # ⏭️ Move patient directory to needs_review
#         try:
#             # assumes output is .../features/tmp_{patient}.csv
#             patient_id = os.path.basename(args.output).replace("tmp_", "").replace(".csv", "")
#             features_root = os.path.dirname(os.path.dirname(args.output))
#             patient_dir = os.path.join(features_root, patient_id)
#             review_dir = os.path.join(features_root, "needs_review", patient_id)

#             os.makedirs(os.path.dirname(review_dir), exist_ok=True)
#             if os.path.exists(patient_dir):
#                 shutil.move(patient_dir, review_dir)
#                 print(f"[INFO] Moved {patient_id} to needs_review folder.")
#         except Exception as move_err:
#             print(f"[WARNING] Could not move patient folder: {move_err}")

#         sys.exit(1)

# ------------------------------
# Step 4: Merge all per-patient features
# ------------------------------
def merge_features(args):
    """
    Merge multiple CSV files (one per patient) into a single CSV.
    Output:
        - Merged CSV containing all patients' features
    """
    #dfs = [pd.read_csv(f) for f in args.inputs]
    dfs = [pd.read_csv(f) for f in args.inputs if os.path.getsize(f) > 0]
    pd.concat(dfs, ignore_index=True).to_csv(args.output, index=False)
    

# ------------------------------
# Argument parser with subcommands
# ------------------------------
def main():
    parser = argparse.ArgumentParser(description="Radiomics Workflow Utility")
    subparsers = parser.add_subparsers(dest="command", required=True)

    # Subcommand: Crop MRI
    p_crop = subparsers.add_parser("crop_mri_seg", help="Crop MRI using SEG mask")
    p_crop.add_argument("--mr", required=True, help="Path to MR image (NIfTI)")
    p_crop.add_argument("--seg", required=True, help="Path to SEG image (NIfTI)")
    p_crop.add_argument("--out-mr", required=True, help="Output path for cropped MR image")
    p_crop.add_argument("--out-mask", required=True, help="Output path for binary mask")
    p_crop.set_defaults(func=crop_mri_seg)

    # Subcommand: N4 Bias Correction
    p_bias = subparsers.add_parser("MR_bias_correct", help="Apply N4ITK bias correction")
    p_bias.add_argument("--input", required=True, help="Input cropped MR image (NIfTI)")
    p_bias.add_argument("--output", required=True, help="Output path for bias-corrected MR image")
    p_bias.set_defaults(func=MR_bias_correct)

    # Subcommand: Radiomics Feature Extraction
    p_feat = subparsers.add_parser("extract_feature", help="Extract radiomics features")
    p_feat.add_argument("--image", required=True, help="Bias-corrected MR image path")
    p_feat.add_argument("--mask", required=True, help="Binary mask path")
    p_feat.add_argument("--param", required=True, help="Path to PyRadiomics YAML config")
    p_feat.add_argument("--output", required=True, help="Output path for CSV feature row")
    p_feat.set_defaults(func=extract_feature)

    # Merge Feature CSVs
    p_merge = subparsers.add_parser("merge_features", help="Merge multiple per-patient feature CSVs")
    p_merge.add_argument("--inputs", nargs="+", required=True, help="List of CSV files to merge")
    p_merge.add_argument("--output", required=True, help="Output merged CSV")
    p_merge.set_defaults(func=merge_features)

    args = parser.parse_args()
    args.func(args)

if __name__ == "__main__":
    main()
