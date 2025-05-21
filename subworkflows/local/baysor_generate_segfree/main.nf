//
// Run baysor segfree
//

include { BAYSOR_SEGFREE                       } from '../../../modules/local/baysor/segfree/main'


workflow BAYSOR_GENERATE_SEGFREE {

    take:

    ch_transcripts_parquet // channel: [ val(meta), ["transcripts.parquet"] ]
    ch_config

    main:

    ch_versions = Channel.empty()

    ch_ncvs     = Channel.empty()

    // run baysor segfree
    BAYSOR_SEGFREE (
        ch_transcripts_parquet,
        ch_config
    )
    ch_versions = ch_versions.mix( BAYSOR_SEGFREE.out.versions )

    ch_ncvs = BAYSOR_SEGFREE.out.ncvs

    emit:

    ncvs     = ch_ncvs      // channel: [ val(meta), ["ncvs.loom"] ]

    versions = ch_versions  // channel: [ versions.yml ]
}
