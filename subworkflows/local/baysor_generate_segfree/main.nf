//
// Run baysor segfree
//

include { GUNZIP                               } from '../../../modules/nf-core/gunzip/main'
include { BAYSOR_SEGFREE                       } from '../../../modules/local/baysor/segfree/main'


workflow BAYSOR_GENERATE_SEGFREE {

    take:

    ch_transcripts // channel: [ val(meta), ["transcripts.csv.gz"] ]

    main:

    ch_versions = Channel.empty()

    ch_ncvs     = Channel.empty()

    // unzip transcripts.csv.gz
    GUNZIP ( ch_transcripts )
    ch_versions = ch_versions.mix ( GUNZIP.out.versions )

    // run baysor segfree
    BAYSOR_SEGFREE (
        GUNZIP.out.gunzip
    )
    ch_versions = ch_versions.mix( BAYSOR_SEGFREE.out.versions )

    emit:

    ncvs     = ch_ncvs

    versions = ch_versions                    // channel: [ versions.yml ]
}
