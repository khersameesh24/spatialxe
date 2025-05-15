//
// stage data for the test profile of the pipeline
//

include { UNTAR } from '../../../modules/nf-core/untar/main'


workflow STAGE_TESTDATA {

    take:
    ch_samplesheet

    main:

    ch_versions    = Channel.empty()
    ch_raw_bundle  = Channel.empty()
    ch_transcripts = Channel.empty()
    ch_bundle_path = Channel.empty()
    ch_image       = Channel.empty()

    // get samplesheet fields
    ch_bundle_path = ch_samplesheet.map { meta, bundle, _image ->
        return [ meta, file(bundle) ]
    }

    // run the UNTAR module to create xenium bundle
    UNTAR(ch_bundle_path)
    ch_versions = ch_versions.mix ( UNTAR.out.versions )

    ch_raw_bundle = UNTAR.out.untar

    // get transcript.csv.gz
    ch_transcripts = ch_raw_bundle
                    .filter { meta, file -> file.name == 'transcripts.csv.gz' }
                    .map { meta, file -> file }

    // get morphology.ome.tif
    ch_image = ch_raw_bundle
                    .filter { meta, file -> file.name == 'morphology.ome.tif' }
                    .map { meta, file -> file }

    // get baysor xenium config
    ch_config = Channel.fromPath("${projectDir}/assets/config/xenium.toml", checkIfExists: true)


    emit:

    ch_raw_bundle  = ch_raw_bundle  // channel [ val(meta), ["xenium-bundle"] ]
    ch_transcripts = ch_transcripts // channel [ val(meta), ["path-to-transcripts.csv.gz"] ]
    ch_image       = ch_image       // channel [ val(meta), ["path-to-morphology.ome.tif"] ]
    ch_bundle_path = ch_bundle_path // channel [ val(meta), ["path-to-xenium-bundle"] ]

    versions = ch_versions          // channel [versions.yml]

}
