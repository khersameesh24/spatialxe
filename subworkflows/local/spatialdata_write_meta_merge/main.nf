//
// generate spatialdata object from the spatialxe layers
//

include { SPATIALDATA_WRITE as SPATIALDATA_WRITE_RAW_BUNDLE       } from '../../../modules/local/spatialdata/write/main'
include { SPATIALDATA_WRITE as SPATIALDATA_WRITE_REDEFINED_BUNDLE } from '../../../modules/local/spatialdata/write/main'
include { SPATIALDATA_MERGE as SPATIALDATA_MERGE_RAW_REDEFINED    } from '../../../modules/local/spatialdata/merge/main'
include { SPATIALDATA_META                                        } from '../../../modules/local/spatialdata/meta/main'

workflow SPATIALDATA_WRITE_META_MERGE {

    take:
    ch_raw_bundle       // channel: [ val(meta), [ "xenium-bundle" ] ]
    ch_redefined_bundle // channel: [ val(meta), [ "redefined-xenium-bundle" ] ]

    main:

    ch_versions = Channel.empty()

    // write spatialdata object from the raw xenium bundle
    raw_bundle_path = ch_raw_bundle.map { meta, file_path ->
        return [ meta, file(file_path) ]
    }
    SPATIALDATA_WRITE_RAW_BUNDLE (
        raw_bundle_path,
        'spatialdata_raw'
    )
    ch_versions = ch_versions.mix ( SPATIALDATA_WRITE_RAW_BUNDLE.out.versions )


    // write spatialdata object after running IMP_SEG
    redefined_bundle_path = ch_redefined_bundle.map { meta, file_path ->
        return [ meta, file(file_path) ]
    }
    SPATIALDATA_WRITE_REDEFINED_BUNDLE (
        redefined_bundle_path,
        'spatialdata_redefined'
    )
    ch_versions = ch_versions.mix ( SPATIALDATA_WRITE_REDEFINED_BUNDLE.out.versions )


    // merge raw & redefined spatialdata objects
    SPATIALDATA_MERGE_RAW_REDEFINED (
        SPATIALDATA_WRITE_RAW_BUNDLE.out.spatialdata,
        SPATIALDATA_WRITE_REDEFINED_BUNDLE.out.spatialdata
    )
    ch_versions = ch_versions.mix ( SPATIALDATA_MERGE_RAW_REDEFINED.out.versions )


    // write metadata with spatialdata object
    SPATIALDATA_META (
        SPATIALDATA_MERGE_RAW_REDEFINED.out.spatialxe_bundle,
        ch_raw_bundle
    )
    ch_versions = ch_versions.mix ( SPATIALDATA_META.out.versions )

    emit:

    ch_sd_raw       = SPATIALDATA_WRITE_RAW_BUNDLE.out.spatialdata         // channel: [ val(meta), "spatialdata_raw" ]
    ch_sd_redefined = SPATIALDATA_WRITE_REDEFINED_BUNDLE.out.spatialdata   // channel: [ val(meta), "spatialdata_redefined" ]
    ch_sd_merged    = SPATIALDATA_MERGE_RAW_REDEFINED.out.spatialxe_bundle // channel: [ val(meta), "spatialdata_spatialxe" ]
    ch_sd_meta      = SPATIALDATA_META.out.spatialxe_bundle                // channel: [ val(meta), "spatialdata_spatialxe_final" ]

    versions = ch_versions                                                 // channel: [ versions.yml ]
}

