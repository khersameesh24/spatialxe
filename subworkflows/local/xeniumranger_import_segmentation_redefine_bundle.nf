//
// Run xeniumranger import-segmentation
//

include { XENIUMRANGER_IMPORT_SEGMENTATION as IMP_SEG_COUNT_MATRIX_EXP_DISTANCE       } from '../../modules/nf-core/xeniumranger/import-segmentation/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION as IMP_SEG_POLYGON_GEOJSON_INPUT       } from '../../modules/nf-core/xeniumranger/import-segmentation/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION as IMP_SEG_POST_FICTURE      } from '../../modules/nf-core/xeniumranger/import-segmentation/main'
include { XENIUMRANGER_IMPORT_SEGMENTATION as IMP_SEG_POST_             } from '../../modules/nf-core/xeniumranger/import-segmentation/main'


workflow XENIUMRANGER_IMPORT_SEGMENTATION_REDEFINE_BUNDLE {

    take:

    ch_bundle // channel: [ val(meta), [ "xenium-bundle" ] ]

    main:

    ch_versions = Channel.empty()

    cells = ch_bundle.map {
        _meta, bundle -> return [ bundle + "/cells.zarr.zip" ]
    }

    // scenario - 1 change nuclear expansion distance / create a nucleus-only count matrix(--expansion_distance=0)
    if ( params.expansion_distance == 0 || params.expansion_distance != 5 ){
        IMP_SEG_COUNT_MATRIX_EXP_DISTANCE (
            ch_bundle,
            [],
            cells,
            [],
            [],
            [],
            "pixel"
        )
    }

    // scenario - 2 polygon input - geojson format (from QuPath)
    if ( params.qupath_polygons ) {
        IMP_SEG_POLYGON_GEOJSON_INPUT (
            ch_bundle,
            [],
            params.qupath_polygons,
            params.qupath_polygons,
            [],
            [],
            "pixel"
        )
    } else if ( params.qupath_polygons && params.nucleus_segmentation_only ) {
        IMP_SEG_POLYGON_GEOJSON_INPUT (
            ch_bundle,
            [],
            params.qupath_polygons,
            [],
            [],
            [],
            "pixel"
        )
    }

    //scenario 3 - mask input - included in the cellpose subworkflow

    // scenario 4 - transcript assignment input



    emit:
    // TODO nf-core: edit emitted channels
    bam      = SAMTOOLS_SORT.out.bam           // channel: [ val(meta), [ bam ] ]
    bai      = SAMTOOLS_INDEX.out.bai          // channel: [ val(meta), [ bai ] ]
    csi      = SAMTOOLS_INDEX.out.csi          // channel: [ val(meta), [ csi ] ]

    versions = ch_versions                     // channel: [ versions.yml ]
}

