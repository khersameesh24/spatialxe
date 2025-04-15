#!/usr/bin/env python


import h5py
import numpy as np
import pandas as pd
from typing import Tuple
from pathlib import Path
from boms import run_boms


class BOMS():
    def __init__(self) -> None:
        self.epochs = 30
        self.spatial_bandwidth = 10
        self.range_bandwidth = 0.3
        self.nearest_neighbors = 30

    def run_segmentation(self, transcripts_path: Path, run_id: str) -> None:
        """
        Runs the BOMS segmentation method on the transcripts provided
        Args:
            transcripts_path(Path): path to the transcripts.csv.gz
            run_id(str): specific name for the BOMS run
        """
        # read transcripts file
        print(f"Transcript Path: ${transcripts_path}")
        x_ndarray, y_ndarray, labels = BOMS._read_transcript(transcripts_path=transcripts_path)

        # run segmentation
        modes, segmentation, count_matrix, cell_locations, coordinates = run_boms(
            x_ndarray, y_ndarray, labels, epochs=self.epochs, h_s=self.spatial_bandwidth, h_r=self.range_bandwidth, K=self.nearest_neighbors)

        # generate segmentation output
        BOMS._generate_segmentation_outs(final_segmentation=segmentation, run_id=run_id)

        # generate count matrix output
        BOMS._generate_counts_outs(count_matrix=count_matrix, run_id=run_id)

        # generate cell location output
        BOMS._generate_run_outs(outs_array=cell_locations, filename="boms_cell_locations", run_id=run_id)

        # generate modes output
        BOMS._generate_run_outs(outs_array=modes, filename="boms_modes", run_id=run_id)

        # generate coordinate output
        BOMS._generate_run_outs(outs_array=coordinates, filename="boms_coordinates", run_id=run_id)

        return None


    @staticmethod
    def _read_transcript(
            transcripts_path: Path,
            x_cord:str='x_location',
            y_cord:str='y_location',
            gene_col:str='feature_name',
        ) -> Tuple[np.ndarray, np.ndarray, np.ndarray]:
        """
        Reads the transcript.csv.gz from the xenium bundle
        into a DataFrame and extracts coordinates and labels
        Args:
            transcripts (path): Path to the transcripts.csv.gz
            x_cord (str): name of the column containing the x coordinates
            y_cord (str): name of the column containing the y coordinates
            gene_col (str): name of the column containing the labels (features)
        Returns:
            pd.Series, pd.Series, pd.Series: Extracted x, y coordinates and labels.
        """
        transcripts_df = pd.read_csv(transcripts_path,
                                    compression='gzip',
                                    usecols = [x_cord, y_cord, gene_col],
        )

        x_ndarray: np.ndarray = np.array(pd.Series(transcripts_df[x_cord]))
        y_ndarray: np.ndarray = np.array(pd.Series(transcripts_df[y_cord]))
        labels: np.ndarray = np.array(pd.Series(transcripts_df[gene_col]))

        return x_ndarray, y_ndarray, labels


    @staticmethod
    def _generate_segmentation_outs(
            final_segmentation: np.array,
            filename: str = "boms_segmentation_out",
            run_id: str = ""
        ) -> None:
        """
        Generates a .npy file from the segmentation results
        generated with BOMS run. Converts the numpy array to
        be saved as a .npy file
        Args:
        final_segmentation(np.array): segmentation array from BOMS run
        filename(str): name of the .npy file to be saved
        run_id(str): specific name for the BOMS run
        """
        if run_id:
            filename = f"{run_id}_{filename}"
        np.save(f"{filename}.npy", final_segmentation)
        print(f"Saved segmentation results to {filename} with shape {final_segmentation.shape}")

        return None


    @staticmethod
    def _generate_counts_outs(
        count_matrix: np.array,
        filename: str = "boms_counts_out",
        chunk_size: None = None,
        compression: str = "gzip",
        run_id: str = ""
    ) -> None:
        """
        Generates a .h5 file from the counts matrix generated with
        BOMS run. Converts the numpy array to
        be saved as a .h5 file
        Args:
        count_matrix(np.array): counts matrix from the BOMS run
        filename(str): name of the .h5 file to be saved
        run_id(str): specific name for the BOMS run
        """
        if run_id:
            filename = f"{run_id}_{filename}.h5"

        with h5py.File(filename, "w") as h5f:
            if chunk_size is None:
                # Auto-determine a reasonable chunk size (e.g., slicing along first axis)
                chunk_size = (min(1000, count_matrix.shape[0]),) + count_matrix.shape[1:]

            h5f.create_dataset(
                run_id,
                data=count_matrix,
                compression=compression,
                chunks=chunk_size
            )
        print(f"Saved counts matrix to {filename} with shape {count_matrix.shape}")

        return None


    @staticmethod
    def _generate_run_outs(
            outs_array: np.array,
            filename: str = "",
            run_id: str = ""
        ) -> None:
        """
        Generates a .npy file from arrays
        generated with BOMS run. Converts the numpy array to
        be saved as a .npy file
        Args:
        outs_array(np.array): segmentation array from BOMS run
        filename(str): name of the .npy file to be saved
        run_id(str): specific name for the BOMS run
        """
        if run_id:
            filename = f"{run_id}_{filename}"
        np.save(f"{filename}.npy", outs_array)
        print(f"Saved BOMS run results to {filename} with shape {outs_array.shape}")

        return None


def main() -> None:
    """
    Run boms as a nextflow module
    """
    # get input args from main.nf
    transcripts: str = "${transcripts}"
    run_id: str = "${prefix}"

    # generate process outs
    boms_executor = BOMS()
    boms_executor.run_segmentation (
        transcripts_path=transcripts,
        run_id=run_id
    )

    # generate version outs
    with open("versions.yml", "w") as f:
        f.write('"${task.process}":\\n')
        f.write(f'boms: 1.1.0"\\n')

    return None


if __name__ == "__main__":
    main()
