//
// Run the cellpose, baysor and import-segmentation flow
//

include { CELLPOSE                         } from '../../../modules/nf-core/cellpose/main'
include { BAYSOR_RUN                       } from '../../../modules/local/baysor/run/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'

workflow CELLPOSE_BAYSOR_IMPORT_SEGMENTATION {

    take:

    ch_image        // channel: [ val(meta), ["path-to-morphology.ome.tif"] ]
    ch_bundle       // channel: [ val(meta), ["path-to-xenium-bundle"] ]
    ch_transcripts  // channel: [ val(meta), ["path-to-transcripts.csv.gz"] ]

    main:

    ch_versions = Channel.empty()

    // run cellpose to generate segmentation mask
    CELLPOSE ( ch_image, params.cellpose_model )
    ch_versions = ch_versions.mix ( CELLPOSE.out.versions )


    // run baysor with the segmentation mask from cellpose
    ch_mask = CELLPOSE.out.mask.map {
        _meta, seg_mask -> [ seg_mask ]
    }
    BAYSOR_RUN ( ch_transcripts, ch_mask, "" )
    ch_versions = ch_versions.mix ( BAYSOR_RUN.out.versions )


    // run import segmentation with outputs from baysor
    ch_segmentation = BAYSOR_RUN.out.segmentation.map {
        _meta, segmentation -> return [ segmentation ]
    }
    ch_polygons = BAYSOR_RUN.out.polygons2d

    XENIUMRANGER_IMPORT_SEGMENTATION (
        ch_bundle,
        [],
        [],
        [],
        ch_segmentation,
        ch_polygons,
        "pixel"
    )

    emit:

    redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle // channel: [ val(meta), ["redefined-xenium-bundle"] ]

    versions         = ch_versions                                 // channel: [ versions.yml ]
}

