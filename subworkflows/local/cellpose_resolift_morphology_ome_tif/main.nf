//
// Run cellpose on the morphology tiff
//

include { CELLPOSE                         } from '../../../modules/nf-core/cellpose/main'
include { RESOLIFT                         } from '../../../modules/local/resolift/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'

workflow CELLPOSE_RESOLIFT_MORPHOLOGY_OME_TIF {

    take:

    ch_morphology_image  // channel: [ val(meta), ["path-to-morphology.ome.tiff"] ]
    ch_bundle_path       // channel: [ val(meta), ["path-to-xenium-bundle"] ]

    main:

    ch_versions = Channel.empty()
    ch_model    = Channel.empty()

    if ( !params.cellpose_model ) {
        ch_model = ""
    }

    // sharpen morphology tiff if param - sharpen_tiff is true
    if ( params.sharpen_tiff ) {

        RESOLIFT ( ch_morphology_image )
        ch_versions = ch_versions.mix( RESOLIFT.out.versions )

        // run cellpose on the enhanced tiff
        CELLPOSE ( RESOLIFT.out.enhanced_tiff, ch_model )
        ch_versions = ch_versions.mix( CELLPOSE.out.versions )

    } else {

        // run cellpose on the original tiff
        CELLPOSE ( ch_morphology_image, params.cellpose_model )
        ch_versions = ch_versions.mix( CELLPOSE.out.versions )
    }

    // get cellpose segmentation results
    cellpose_cells = CELLPOSE.out.cells.map {
        _meta, cells -> return [ cells ]
    }
    cellpose_mask = CELLPOSE.out.mask.map {
        _meta, mask -> return [ mask ]
    }
    _cellpose_flows = CELLPOSE.out.flows.map {
        _meta, flows -> return [ flows ]
    }

    // run import-segmentation with cellpose results
    if ( params.nucleus_segmentation_only ) {

        XENIUMRANGER_IMPORT_SEGMENTATION (
            ch_bundle_path,
            [],
            cellpose_mask,
            [],
            [],
            [],
            ""
        )
        ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )

    } else {

        XENIUMRANGER_IMPORT_SEGMENTATION (
            ch_bundle_path,
            [],
            cellpose_mask,
            cellpose_cells,
            [],
            [],
            ""
        )
        ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )
    }

    emit:

    mask  = CELLPOSE.out.mask                                      // channel: [ val(meta), [ "*masks.tif" ] ]
    flows = CELLPOSE.out.flows                                     // channel: [ val(meta), [ "*flows.tif" ] ]
    cells = CELLPOSE.out.cells                                     // channel: [ val(meta), [ "*seg.npy" ] ]

    redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle // channel: [ val(meta), ["redefined-xenium-bundle"] ]

    versions = ch_versions                                         // channel: [ versions.yml ]
}
