//
// Run baysor run & import-segmentation
//

include { GUNZIP                               } from '../../../modules/nf-core/gunzip/main'
include { RESOLIFT                             } from '../../../modules/local/resolift/main'
include { BAYSOR_RUN as BAYSOR_RUN_IMAGE       } from '../../../modules/local/baysor/run/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION     } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'


workflow BAYSOR_RUN_MORPHOLOGY_OME_TIF {

    take:

    ch_bundle      // channel: [ val(meta), ["xenium-bundle"] ]
    ch_transcripts // channel: [ val(meta), ["transcripts.csv.gz"] ]
    ch_image       // channel: [ val(meta), ["morphology_focus.tiff"] ]

    main:

    ch_versions             = Channel.empty()

    ch_enhanced_tiff        = Channel.empty()
    ch_segmentation         = Channel.empty()
    ch_polygons2d           = Channel.empty()
    ch_htmls                = Channel.empty()

    ch_redefined_bundle     = Channel.empty()
    ch_unzipped_transcripts = Channel.empty()


    // unzip transcripts.csv.gz
    GUNZIP ( ch_transcripts )
    ch_versions = ch_versions.mix ( GUNZIP.out.versions )

    ch_unzipped_transcripts = GUNZIP.out.gunzip

    // sharpen morphology tiff if param `sharpen_tiff` is true
    ch_just_image = Channel.empty()
    if ( params.sharpen_tiff ) {

        RESOLIFT ( ch_image )
        ch_versions = ch_versions.mix( RESOLIFT.out.versions )

        ch_enhanced_tiff = RESOLIFT.out.enhanced_tiff
        ch_just_image = ch_enhanced_tiff.map {
            _meta, image -> return [ image ]
        }

    } else {

        // use the original morphology tiff from the bundle
        ch_just_image = ch_image.map {
            _meta, image -> return [ image ]
        }
    }

    // run baysor with morphology.tiff
    BAYSOR_RUN_IMAGE (
        ch_unzipped_transcripts,
        ch_just_image,
        30
    )
    ch_versions = ch_versions.mix( BAYSOR_RUN_IMAGE.out.versions )

    ch_segmentation = BAYSOR_RUN_IMAGE.out.segmentation
    ch_jus_segmentation = ch_segmentation.map {
        _meta, segmentation -> return [ segmentation ]
    }
    ch_polygons2d = BAYSOR_RUN_IMAGE.out.polygons2d
    ch_htmls      = BAYSOR_RUN_IMAGE.out.htmls
    // run xeniumranger import-segmentation
    XENIUMRANGER_IMPORT_SEGMENTATION (
        ch_bundle,
        [],
        [],
        [],
        ch_jus_segmentation,
        ch_polygons2d,
        "pixel"
    )
    ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )

    ch_redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle

    emit:

    enhanced_tiff    = ch_enhanced_tiff       // channel: [ val(meta), ["morphology.tiff"] ]

    segmentation     = ch_segmentation        // channel: [ val(meta), ["segmentation.csv"] ]
    polygons2d       = ch_polygons2d          // channel: [ ["segmentation_polygons_2d.json"] ]
    htmls            = ch_htmls               // channel: [ ["*.html"] ]

    redefined_bundle = ch_redefined_bundle    // channel: [ val(meta), "redefined-xenium-bundle" ]

    versions = ch_versions                    // channel: [ versions.yml ]
}
