from pathlib import Path
from damply import dirs

import numpy as np
import pandas as pd


import highdicom as hd
from pydicom.sr.codedict import codes
import pydicom

from imgtools.dicom.dicom_metadata import extract_metadata

from readii.io.loaders.general import loadImageDatasetConfig

import click
from readii.utils import logger

import SimpleITK as sitk


def construct_ispy_seg(source_images : list[pydicom.Dataset], 
                       pixel_array : np.ndarray
                      ) -> hd.seg.Segmentation:
    algorithm_identification = hd.AlgorithmIdentificationSequence(
        name='Background Threshold, PE threshold and connectivity filter',
        version='v1.0',
        family=codes.cid7162.AdaptiveFiltering
    )


    tumour_segment_description = hd.seg.SegmentDescription(
        segment_number=1,
        segment_label='Tumor',
        segmented_property_category=codes.cid7150.Tissue,
        segmented_property_type=codes.cid7151.Breast,
        algorithm_type=hd.seg.SegmentAlgorithmTypeValues.SEMIAUTOMATIC,
        algorithm_identification=algorithm_identification
    )

    tumor_dataset = hd.seg.Segmentation(
        source_images = source_images,
        pixel_array=pixel_array,
        segmentation_type=hd.seg.SegmentationTypeValues.BINARY,
        segment_descriptions=[tumour_segment_description],
        series_instance_uid=hd.UID(),
        series_number=2,
        sop_instance_uid=hd.UID(),
        instance_number=1,
        manufacturer="GE MEDICAL SYSTEMS",
        manufacturer_model_name="Signa HDxt",
        software_versions='220',
        device_serial_number='Device XYZ',
        series_description='Binarized VOLSER Analysis Mask',
        omit_empty_frames=False
    )

    return tumor_dataset


def crop_dicom_image_to_dicom_seg(dicom_image_dir : Path,
                                  dicom_mask_file: Path
                                  ) -> list[pydicom.Dataset]:
    
    # Get the list of referenced image slice IDs from the mask file
    mask_metadata = extract_metadata(dicom_mask_file)
    mask_slice_ids = mask_metadata['ReferencedSOPUIDs']

    # Get list of dicom files in the image directory
    image_files = dicom_image_dir.glob("*.dcm")

    # Read in each dicom file as a pydicom Dataset
    image_datasets = [hd.imread(str(f)) for f in image_files]

    cropped_image_datasets = []
    
    # Copy image slices/datasets that have an SOP referenced by the mask 
    for image_dicom_file in image_datasets:
        if image_dicom_file.SOPInstanceUID in mask_slice_ids:
            cropped_image_datasets.append(image_dicom_file)
    
    return cropped_image_datasets


def binarize_ispy_seg_tumor(dicom_mask_file : Path) -> np.ndarray:
    """Convert I-SPY DICOM Seg pixel array from multi-value to binarized array with the tumor voxels = 1, background = 0."""

    mask = hd.seg.segread(dicom_mask_file)

    return np.where(mask.pixel_array == 0, 1, 0).astype(np.uint8)



@click.command()
@click.option('--dataset', help='Dataset configuration file name (e.g. NSCLC-Radiomics.yaml). Must be in config/datasets.')
def process_ispy_masks(dataset):

    if dataset is None:
        message = "Dataset name must be provided."
        logger.error(message)
        raise ValueError(message)
    
    # Load in dataset configuration settings from provided file
    config_dir_path = dirs.CONFIG / 'datasets'
    dataset_config = loadImageDatasetConfig(dataset, config_dir_path)

    dataset_name = dataset_config['DATASET_NAME']
    full_data_name = f"{dataset_config['DATA_SOURCE']}_{dataset_name}"


    images_path = Path(full_data_name, "images")
    mit_index_file = dirs.PROCDATA / images_path / f"mit_{dataset_name}" / f"mit_{dataset_name}_index.csv"

    mit_index = pd.read_csv(mit_index_file)
    image_modality = dataset_config["MIT"]["MODALITIES"]["image"]
    mask_modality = dataset_config["MIT"]["MODALITIES"]["mask"]


    mask_index = mit_index[mit_index['Modality'] == mask_modality]

    for idx, mask_row in mask_index.iterrows():
        mask_file_path = dirs.RAWDATA / images_path / mask_row['folder'] / "1-1.dcm"

        binarized_pixel_array = binarize_ispy_seg_tumor(mask_file_path)

        bin_mask_file_path = dirs.PROCDATA / images_path / "processed_ISPY2" / Path(mask_row['filepath']).parent / "bin_GTV.nii.gz"
        bin_mask_file_path.parent.mkdir(parents=True, exist_ok=True)

        sitk.WriteImage(sitk.GetImageFromArray(binarized_pixel_array), bin_mask_file_path)
        
    return


if __name__ == '__main__':
    process_ispy_masks()