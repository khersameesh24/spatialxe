//
// Runs proseg for the xenium format and proseg2baysor to generate cell ploygons
//

include { PROSEG            } from '../../modules/local/proseg/run/main'
include { PROSEG2BAYSOR     } from '../../modules/local/proseg/proseg2baysor/main'

workflow PROSEG_RUN_PROSEG2BAYSOR {

    take:

    ch_transcripts // channel: [ val(meta), [ "transcripts.csv.gz" ] ]

    main:

    ch_versions = Channel.empty()

    // run proseg with the xenium format
    PROSEG ( ch_transcripts )
    ch_versions = ch_versions.mix( PROSEG.out.versions )


    // run proseg-to-baysor on the data generated with the proseg run
    PROSEG2BAYSOR ( PROSEG.out.cell_polygons_2d, PROSEG.out.transcript_metadata )
    ch_versions = ch_versions.mix( PROSEG2BAYSOR.out.versions )

    emit:

    cell_polygons_2d      = PROSEG.out.cell_polygons_2d        // channel: [ val(meta), [ "cell-polygons.geojson.gz" ] ]
    expected_counts       = PROSEG.out.expected_counts         // channel: [ [ "expected-counts.csv.gz" ] ]
    cell_metadata         = PRPSEG.out.cell_metadata           // channel: [ [ "cell-metadata.csv.gz" ] ]
    transcript_metadata   = PROSEG.out.transcript_metadata     // channel: [ [ "transcript-metadata.csv.gz" ] ]
    gene_metadata         = PROSEG.out.gene_metadata           // channel: [ [ "gene-metadata.csv.gz" ] ]
    rates                 = PROSEG.out.rates                   // channel: [ [ "rates.csv.gz" ] ]
    cell_polygons_layers  = PROSEG.out.cell_polygons_layers    // channel: [ [ "cell-polygons-layers.geojson.gz" ] ]
    cell_hulls            = PROSEG.out.cell_hulls              // channel: [ [ "cell-hulls.geojson.gz" ] ]
    union_cell_polygons   = PROSEG.out.union_cell_polygons     // channel: [ [ "union-cell-polygons.geojson.gz" ] ]

    xr_polygons           = PROSEG2BAYSOR.out.xr_polygons      // channel: [ val(meta), [ "xr-cell-polygons.geojson" ] ]
    xr_metadata           = PROSEG2BAYSOR.out.xr_metadata      // channel: [ [ "xr-transcript-metadata.csv" ] ]

    versions = ch_versions                                     // channel: [ versions.yml ]
}

