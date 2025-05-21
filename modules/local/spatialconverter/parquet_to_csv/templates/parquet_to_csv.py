#!/usr/bin/env python

import pandas as pd

if __name__ == '__main__':
    print("[START]")

    ext = "${extension}" if "${extension}" else ".csv"
    df = pd.read_parquet("${transcripts}")

    if ext == ".csv":
        output="${transcripts}".replace(".parquet",".csv")
        df.to_csv(f"{output}", index=False)

    if ext == ".gz":
        output="${transcripts}".replace(".parquet",".csv.gz")
        df.to_csv(f"{output}", compression='gzip', index=False)

    #Output version information
    with open("versions.yml", "w") as f:
        f.write('"${task.process}":\\n')
        f.write(f'spatialconverter: "v0.0.1"\\n')

    print("[FINISH]")

