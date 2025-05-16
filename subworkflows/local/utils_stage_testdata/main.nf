//
// stage data for the test profile of the pipeline
//

include { UNTAR } from '../../../modules/nf-core/untar/main'


workflow STAGE_TESTDATA {

    take:
    ch_samplesheet

    main:

    ch_versions            = Channel.empty()
    ch_raw_bundle          = Channel.empty()
    ch_bundle_url          = Channel.empty()
    ch_image               = Channel.empty()
    ch_transcripts_csv     = Channel.empty()
    ch_transcripts_parquet = Channel.empty()

    // get xenium bundle path
    ch_bundle_url = ch_samplesheet.map { meta, bundle, _image ->
        return [ meta, file(bundle) ]
    }

    // run the UNTAR module to create xenium bundle
    UNTAR(ch_bundle_url)
    ch_versions = ch_versions.mix ( UNTAR.out.versions )

    ch_bundle_local_path = UNTAR.out.untar
    ch_bundle_local_path.view()

    // get transcript.csv.gz
    ch_transcripts_csv = ch_bundle_local_path.map { meta, bundle ->
        def transcripts_csv = file(bundle + "/transcripts.csv.gz")
        return [ meta, transcripts_csv ]
    }

    // get transcript.parquet
    ch_transcripts_parquet = ch_bundle_local_path.map { meta, bundle ->
        def transcripts_parquet = file(bundle + "/transcripts.parquet")
        return [ meta, transcripts_parquet ]
    }

    // get morphology.ome.tif
    ch_image = ch_bundle_local_path.map { meta, bundle ->
        def morphology_image = file(bundle + "/morphology.ome.tif")
        return [ meta, morphology_image ]
    }

    // get baysor xenium config
    ch_config = Channel.fromPath("${projectDir}/assets/config/xenium.toml", checkIfExists: true)


    emit:

    ch_raw_bundle           = ch_bundle_local_path          // channel [ val(meta), ["xenium-bundle"] ]
    ch_transcripts_csv      = ch_transcripts_csv     // channel [ val(meta), ["path-to-transcripts.csv.gz"] ]
    ch_transcripts_parquet  = ch_transcripts_parquet // channel [ val(meta), ["path-to-transcripts.csv.gz"] ]
    ch_image                = ch_image               // channel [ val(meta), ["path-to-morphology.ome.tif"] ]
    ch_config               = ch_config              // channel [ ["path-to-xenium.toml"] ]

    versions = ch_versions                           // channel [versions.yml]

}
