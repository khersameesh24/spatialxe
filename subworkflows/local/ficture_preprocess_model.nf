//
// Run ficture preprocess and model modules
//

include { FICTURE_PREPROCESS } from '../../modules/local/ficture/preprocess/main'
include { FICTURE            } from '../../modules/local/ficture/model/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../modules/nf-core/xeniumranger/import-segmentation/main'

workflow FICTURE_PREPROCESS_MODEL {

    take:

    ch_bundle
    ch_transcripts // channel: [ val(meta), [ "transcripts.csv.gz" ] ]
    ch_features    // channel: [ "features" ]

    main:

    ch_versions = Channel.empty()

    // run ficture preprocessing
    FICTURE_PREPROCESS ( ch_transcripts, ch_features )
    ch_versions = ch_versions.mix( FICTURE_PREPROCESS.out.versions )

    // run the ficture wrapper pipeline
    ch_features_clean = Channel.empty()
    if ( params.features ) {
        ch_features_clean = FICTURE_PREPROCESS.out.features
    }
    FICTURE (
        FICTURE_PREPROCESS.out.transcripts,
        FICTURE_PREPROCESS.out.coordinate_minmax,
        ch_features_clean
    )
    ch_versions = ch_versions.mix( FICTURE.out.versions )

    // run xeniumranger import-segmentation
    // XENIUMRANGER_IMPORT_SEGMENTATION (
    //     ch_bundle,
    //     [],
    //     [],
    //     [],
    //     ch_segmentation,
    //     BAYSOR_RUN.out.polygons2d,
    //     "microns"
    // )

    emit:

    transcripts        = FICTURE_PREPROCESS.out.transcripts         // channel: [ val(meta), [ "*processed_transcripts.tsv.gz" ] ]
    coordinate_minmax  = FICTURE_PREPROCESS.out.coordinate_minmax   // channel: [ "*coordinate_minmax.tsv" ]
    features           = FICTURE_PREPROCESS.out.features            // channel: [ "*feature.clean.tsv.gz" ]

    results            = FICTURE.out.results                        // channel: [ val(meta), [ "results/** ] ]

    versions = ch_versions                                          // channel: [ versions.yml ]
}

