#!/usr/bin/env python

"""Provide functions to write spatialdata object from segmentation format."""

import sys
import spatialdata
from spatialdata_io import xenium

def main():
    print("[START]")

    input_path = "${bundle}"
    output_path = "."
    outputfolder = "${outputfolder}"

    format = "${params.format}"

    if ( format == "xenium" ):
        sd_xenium_obj = xenium(
            input_path,
            cells_as_circles=True,
            nucleus_boundaries=True,
            transcripts=True,
            morphology_mip=True,
            morphology_focus=True,
            n_jobs="${task.cpus}",
        )
        print(sd_xenium_obj)
        sd_xenium_obj.write(f"{output_path}/{outputfolder}")
    else:
        sys.exit("[ERROR] Format not found")

    #Output version information
    with open("versions.yml", "w") as f:
        f.write('"${task.process}":\\n')
        f.write(f'spatialdata: "{spatialdata.__version__}"\\n')

    print("[FINISH]")

if __name__ == "__main__":
    main()
