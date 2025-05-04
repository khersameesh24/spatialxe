//
// Run baysor preview, run and segfree modules
//

include { GUNZIP                           } from '../../../modules/nf-core/gunzip/main'
include { RESOLIFT                         } from '../../../modules/local/resolift/main'
include { BAYSOR_RUN                       } from '../../../modules/local/baysor/run/main'
include { BAYSOR_PREVIEW                   } from '../../../modules/local/baysor/preview/main'
include { BAYSOR_SEGFREE                   } from '../../../modules/local/baysor/segfree/main'
include { BAYSOR_CREATE_DATASET            } from '../../../modules/local/baysor/create_dataset/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'

workflow BAYSOR_PREVIEW_RUN_SEGFREE {

    take:

    ch_bundle      // channel: [ val(meta), ["xenium-bundle"] ]
    ch_transcripts // channel: [ val(meta), [ "transcripts.csv.gz" ] ]
    ch_image       // channel: [ val(meta), [ "morphology_focus.tiff" ] ]

    main:

    ch_versions    = Channel.empty()


    // unzip transcripts.csv.gz
    GUNZIP ( ch_transcripts )
    ch_versions = ch_versions.mix ( GUNZIP.out.versions )


    // run baysor preview if param - generate_preview is true
    if ( params.baysor_preview ) {

        // generate randomised sample data
        BAYSOR_CREATE_DATASET ( GUNZIP.out.gunzip, "0.3" )
        ch_versions = ch_versions.mix ( BAYSOR_CREATE_DATASET.out.versions )

        BAYSOR_PREVIEW (
            BAYSOR_CREATE_DATASET.out.sampled_transcripts
        )
        ch_versions = ch_versions.mix ( BAYSOR_PREVIEW.out.versions )

        log.info "Preview generated at ${params.outdir}"
        System.exit(0)
    }

    // run baysor run with morphology tif
    if ( params.baysor_run_image ) {

        // channel to store either pixel-based or co-ordinate based segmentation
        ch_segmentation = Channel.empty()

        // sharpen morphology tiff if param `sharpen_tiff` is true
        ch_just_image = Channel.empty()
        if ( params.sharpen_tiff ) {

            RESOLIFT ( ch_image )
            ch_versions = ch_versions.mix( RESOLIFT.out.versions )

            ch_just_image = RESOLIFT.out.enhanced_tiff.map {
                _meta, image -> return [ image ]
            }

        } else {

            // use the original morphology tiff from the bundle
            ch_just_image = ch_image.map {
                _meta, image -> return [ image ]
            }
        }

        // run baysor with morphology.tiff
        BAYSOR_RUN (
            GUNZIP.out.gunzip,
            ch_just_image,
            30 // TODO probably better to introduce a parameter here
        )
        ch_versions = ch_versions.mix( BAYSOR_RUN.out.versions )

        ch_segmentation = BAYSOR_RUN.out.segmentation.map {
            _meta, segmentation -> return [ segmentation ]
        }
        // run xeniumranger import-segmentation
        XENIUMRANGER_IMPORT_SEGMENTATION (
            ch_bundle,
            [],
            [],
            [],
            ch_segmentation,
            BAYSOR_RUN.out.polygons2d,
            "pixel"
        )
        ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )
    }


    // run baysor with transcripts.csv
    if ( params.baysor_run_transcripts ) {

        BAYSOR_RUN (
            GUNZIP.out.gunzip,
            [],
            30 // TODO probably better to inroduce a parameter here
        )
        ch_versions = ch_versions.mix ( BAYSOR_RUN.out.versions )

        ch_segmentation = BAYSOR_RUN.out.segmentation.map {
            _meta, segmentation -> return [ segmentation ]
        }
        // run xeniumranger import-segmentation
        XENIUMRANGER_IMPORT_SEGMENTATION (
            ch_bundle,
            [],
            [],
            [],
            ch_segmentation,
            BAYSOR_RUN.out.polygons2d,
            "microns"
        )
        ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )
    }


    // run baysor segree if segfree methods are provided
    if ( params.segmentation == 'baysor_segmentation_free' ) {

        BAYSOR_SEGFREE (
            GUNZIP.out.gunzip
        )
        ch_versions = ch_versions.mix( BAYSOR_SEGFREE.out.versions )

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
    }

    emit:

    enhanced_tiff    = RESOLIFT.out.enhanced_tiff                     // channel: [ val(meta), ["morphology.tiff"] ]

    preview_html     = BAYSOR_PREVIEW.out.preview_html                // channel: [ val(meta), ["preview.html"] ]

    segmentation     = BAYSOR_RUN.out.segmentation                    // channel: [ val(meta), ["segmentation.csv"] ]
    polygons2d       = BAYSOR_RUN.out.polygons2d                      // channel: [ val(meta), ["segmentation_polygons_2d.json"] ]
    htmls            = BAYSOR_RUN.out.htmls                           // channel: [ val(meta), ["*.html"] ]
    stats            = BAYSOR_RUN.out.stats                           // channel: [ val(meta), ["segmentation_cell_stats.csv"] ]

    ncvs             = BAYSOR_SEGFREE.out.ncvs                        // channel: [ val(meta), ["ncvs.loom"] ]

    redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle    // channel: [ val(meta), "redefined-xenium-bundle" ]

    versions = ch_versions                                            // channel: [ versions.yml ]
}
