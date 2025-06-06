//
// Run cellpose on the morphology tiff
//

include { CELLPOSE as CELLPOSE_CELLS       } from '../../../modules/nf-core/cellpose/main'
include { CELLPOSE as CELLPOSE_NUCLEI      } from '../../../modules/nf-core/cellpose/main'
include { RESOLIFT                         } from '../../../modules/local/resolift/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../../../modules/nf-core/xeniumranger/import-segmentation/main'

workflow CELLPOSE_RESOLIFT_MORPHOLOGY_OME_TIF {

    take:

    ch_morphology_image  // channel: [ val(meta), ["path-to-morphology.ome.tiff"] ]
    ch_bundle_path       // channel: [ val(meta), ["path-to-xenium-bundle"] ]

    main:

    ch_versions = Channel.empty()

    cellpose_model = params.cellpose_model ? (Channel.fromPath(params.cellpose_model, checkIfExists: true)) : []

    // sharpen morphology tiff if param - sharpen_tiff is true
    if ( params.sharpen_tiff ) {

        RESOLIFT ( ch_morphology_image )
        ch_versions = ch_versions.mix( RESOLIFT.out.versions )

        // run cellpose on the enhanced tiff
        CELLPOSE_CELLS ( RESOLIFT.out.enhanced_tiff, cellpose_model, 'cells' )
        ch_versions = ch_versions.mix( CELLPOSE.out.versions )

        CELLPOSE_NUCLEI ( RESOLIFT.out.enhanced_tiff, 'nuclei', 'nuclei' )
        ch_versions = ch_versions.mix( CELLPOSE_NUCLEI.out.versions )

    } else {

        // run cellpose on the original tiff
        CELLPOSE_CELLS ( ch_morphology_image, cellpose_model, 'cells' )
        ch_versions = ch_versions.mix( CELLPOSE_CELLS.out.versions )

        CELLPOSE_NUCLEI ( ch_morphology_image, 'nuclei', 'nuclei' )
        ch_versions = ch_versions.mix( CELLPOSE_NUCLEI.out.versions )
    }

    // get cellpose segmentation results
    cellpose_cells_cells = CELLPOSE_CELLS.out.cells.map {
        _meta, cells -> return [ cells ]
    }
    cellpose_cells_mask = CELLPOSE_CELLS.out.mask.map {
        _meta, mask -> return [ mask ]
    }
    _cellpose_cells_flows = CELLPOSE_CELLS.out.flows.map {
        _meta, flows -> return [ flows ]
    }
    cellpose_nuclei_cells = CELLPOSE_NUCLEI.out.cells.map {
        _meta, cells -> return [ cells ]
    }
    cellpose_nuclei_mask = CELLPOSE_NUCLEI.out.mask.map {
        _meta, mask -> return [ mask ]
    }
    _cellpose_nuclei_flows = CELLPOSE_NUCLEI.out.flows.map {
        _meta, flows -> return [ flows ]
    }

    // run import-segmentation with cellpose results
    if ( params.nucleus_segmentation_only ) {

        XENIUMRANGER_IMPORT_SEGMENTATION (
            ch_bundle_path,
            [],
            cellpose_nuclei_mask,
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
            cellpose_nuclei_mask,
            cellpose_cells_mask,
            [],
            [],
            ""
        )
        ch_versions = ch_versions.mix( XENIUMRANGER_IMPORT_SEGMENTATION.out.versions )
    }

    emit:

    cells_mask  = CELLPOSE_CELLS.out.mask                                // channel: [ val(meta), [ "*masks.tif" ] ]
    cells_flows = CELLPOSE_CELLS.out.flows                               // channel: [ val(meta), [ "*flows.tif" ] ]
    cells_cells = CELLPOSE_CELLS.out.cells                               // channel: [ val(meta), [ "*seg.npy" ] ]
    nuclei_mask  = CELLPOSE_NUCLEI.out.mask                              // channel: [ val(meta), [ "*masks.tif" ] ]
    nuclei_flows = CELLPOSE_NUCLEI.out.flows                             // channel: [ val(meta), [ "*flows.tif" ] ]
    nuclei_cells = CELLPOSE_NUCLEI.out.cells                             // channel: [ val(meta), [ "*seg.npy" ] ]

    redefined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle // channel: [ val(meta), ["redefined-xenium-bundle"] ]

    versions = ch_versions                                         // channel: [ versions.yml ]
}
