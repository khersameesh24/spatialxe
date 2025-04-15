//
// Run baysor preview, run and segfree modules
//

include { GUNZIP         } from '../../modules/nf-core/gunzip/main'
include { RESOLIFT       } from '../../modules/local/resolift/main'
include { BAYSOR_PREVIEW } from '../../modules/local/baysor/preview/main'
include { BAYSOR_RUN     } from '../../modules/local/baysor/run/main'
include { BAYSOR_SEGFREE } from '../../modules/local/baysor/segfree/main'

workflow BAYSOR_PREVIEW_RUN_SEGFREE {

    take:

    ch_transcripts // channel: [ val(meta), [ "transcript.csv.gz" ] ]
    ch_image       // channel: [ val(meta), [ "morphology_focus.tiff" ] ]

    main:

    ch_versions    = Channel.empty()

    enhanced_tiff  = Channel.empty()

    preview_html   = Channel.empty()

    segmentation   = Channel.empty()
    polygons2d     = Channel.empty()
    polygons3d     = Channel.empty()
    params         = Channel.empty()
    loom           = Channel.empty()
    htmls          = Channel.empty()
    stats          = Channel.empty()

    ncvs           = Channel.empty()


    // unzip transcripts.csv.gz
    GUNZIP ( ch_transcripts )
    ch_versions = ch_versions.mix ( GUNZIP.out.versions )


    // run baysor preview if param - generate preview is true
    if ( params.generate_preview ) {

        // TODO: function to randomly select about 30% rows from transcripts.csv
        BAYSOR_PREVIEW (
            GUNZIP.out.gunzip
        )
        ch_versions = ch_versions.mix ( BAYSOR_PREVIEW.out.versions )

        // TODO: the pipeline should ideally exit once the preview is generated
    }

    // generate segmentation with baysor run
    if ( params.segmentation == 'baysor_segmentation' ) {

        if ( params.baysor_rerun ) {

            // channel to store either pixel-based or co-ordinate based segmentation
            ch_segmentation = Channel.empty()

            // sharpen morphology tiff if param `sharpen_tiff` is true
            ch_just_image = Channel.empty()
            if ( params.sharpen_tiff ) {

                RESOLIFT ( ch_image )
                ch_versions = ch_versions.mix(RESOLIFT.out.versions)

                ch_just_image = RESOLIFT.out.enhanced_tiff.map {
                    meta, image -> return [ image ]
                }

            } else {

                // use the original morphology tiff from the bundle
                ch_just_image = ch_image.map {
                    meta, image -> return [ image ]
                }
            }

            // run baysor with morphology.tiff
            BAYSOR_RUN(
                GUNZIP.out.gunzip,
                ch_just_image,
                30 // TODO probably better to introduce a parameter here
            )
            ch_versions = ch_versions.mix(BAYSOR_RUN.out.versions)

            ch_segmentation = BAYSOR_RUN.out.segmentation.map {
                meta, segmentation -> return [ segmentation ]
            }

        } else {

            // run baysor with transcripts.csv
            BAYSOR_RUN (
                GUNZIP.out.gunzip,
                [],
                30 // TODO probably better to inroduce a parameter here
            )
            ch_versions = ch_versions.mix ( BAYSOR_RUN.out.versions )

            ch_segmentation = BAYSOR_RUN.out.segmentation.map {
                meta, segmentation -> return [ segmentation ]
            }
        }
    }

    // run baysor segree if segfree methods are provided
    if ( params.segmentation == 'baysor_segmentation_free' ) {

        BAYSOR_SEGFREE (
            GUNZIP.out.gunzip
        )
        ch_versions = ch_versions.mix( BAYSOR_SEGFREE.out.versions )

    }

    emit:

    enhanced_tiff  = RESOLIFT.out.enhanced_tiff      // channel: [ val(meta), ["morphology.tiff"] ]

    preview_html   = BAYSOR_PREVIEW.out.preview_html // channel: [ val(meta), ["preview.html"] ]

    segmentation   = BAYSOR_RUN.out.segmentation     // channel: [ val(meta), ["segmentation.csv"] ]
    polygons2d     = BAYSOR_RUN.out.polygons2d       // channel: [ val(meta), ["segmentation_polygons_2d.json"] ]
    polygons3d     = BAYSOR_RUN.out.polygons3d       // channel: [ val(meta), ["segmentation_polygons_3d.json"] ]
    params         = BAYSOR_RUN.out.params           // channel: [ val(meta), ["*.toml"] ]
    loom           = BAYSOR_RUN.out.loom             // channel: [ val(meta), ["*.loom"] ]
    htmls          = BAYSOR_RUN.out.htmls            // channel: [ val(meta), ["*.html"] ]
    stats          = BAYSOR_RUN.out.stats            // channel: [ val(meta), ["segmentation_cell_stats.csv"] ]

    ncvs           = BAYSOR_SEGFREE.out.ncvs         // channel: [ val(meta), ["ncvs.loom"] ]

    versions = ch_versions                           // channel: [ versions.yml ]
}
