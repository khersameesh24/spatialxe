//
// Run baysor run and import-segmentation
//

include { GUNZIP                               } from '../../../modules/nf-core/gunzip/main'
include { BAYSOR_RUN as BAYSOR_RUN_TRANSCRIPTS } from '../../../modules/local/baysor/run/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION     } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'


workflow BAYSOR_RUN_TRANSCRIPTS_CSV {

    take:

    ch_bundle_path     // channel: [ val(meta), ["xenium-bundle"] ]
    ch_transcripts_csv // channel: [ val(meta), ["transcripts.csv.gz"] ]
    ch_config          // channel: ["path-to-xenium.toml"]

    main:

    ch_versions             = Channel.empty()

    ch_segmentation         = Channel.empty()
    ch_polygons2d           = Channel.empty()
    ch_htmls                = Channel.empty()

    ch_redefined_bundle     = Channel.empty()
    ch_unzipped_transcripts = Channel.empty()


    // unzip transcripts.csv.gz
    GUNZIP ( ch_transcripts_csv )
    ch_versions = ch_versions.mix ( GUNZIP.out.versions )

    ch_unzipped_transcripts = GUNZIP.out.gunzip

    // run baysor with transcripts.csv
    BAYSOR_RUN_TRANSCRIPTS (
        ch_unzipped_transcripts,
        [],
        ch_config,
        30
    )
    ch_versions = ch_versions.mix ( BAYSOR_RUN_TRANSCRIPTS.out.versions )

    ch_segmentation = BAYSOR_RUN_TRANSCRIPTS.out.segmentation
    ch_jus_segmentation = ch_segmentation.map {
        _meta, segmentation -> return [ segmentation ]
    }
    ch_polygons2d = BAYSOR_RUN_TRANSCRIPTS.out.polygons2d
    ch_htmls      = BAYSOR_RUN_TRANSCRIPTS.out.htmls

    // run xeniumranger import-segmentation
    XENIUMRANGER_IMPORT_SEGMENTATION (
        ch_bundle_path,
        [],
        [],
        [],
        ch_jus_segmentation,
        ch_polygons2d,
        "microns"
    )
    ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )

    ch_redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle

    emit:

    segmentation     = ch_segmentation        // channel: [ val(meta), ["segmentation.csv"] ]
    polygons2d       = ch_polygons2d          // channel: [ ["segmentation_polygons_2d.json"] ]
    htmls            = ch_htmls               // channel: [ ["*.html"] ]

    redefined_bundle = ch_redefined_bundle    // channel: [ val(meta), "redefined-xenium-bundle" ]

    versions = ch_versions                    // channel: [ versions.yml ]
}
