import click
from pathlib import Path
from damply import dirs
import pandas as pd
from readii.io.loaders.general import loadImageDatasetConfig
import SimpleITK as sitk
from highdicom import seg
import numpy as np
from readii.utils import logger

def binarize_ispy_seg_tumor(dicom_mask_file : Path) -> np.ndarray:
    """Convert I-SPY DICOM Seg pixel array from multi-value to binarized array with the tumor voxels = 1, background = 0."""

    mask = seg.segread(dicom_mask_file)

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

        bin_mask_file_path = dirs.PROCDATA / images_path / f"processed_{dataset_name}" / Path(mask_row['filepath']).parent / "bin_GTV.nii.gz"
        bin_mask_file_path.parent.mkdir(parents=True, exist_ok=True)

        sitk.WriteImage(sitk.GetImageFromArray(binarized_pixel_array), bin_mask_file_path)
        
    return


if __name__ == '__main__':
    process_ispy_masks()