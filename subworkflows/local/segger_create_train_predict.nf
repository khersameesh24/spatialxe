//
// Run segger create_dataset, train and predict modules
//

include { SEGGER_CREATE_DATASET } from '../../../modules/local/segger/create_dataset/main'
include { SEGGER_TRAIN } from '../../../modules/local/segger/train/main'
include { SEGGER_PREDICT } from '../../../modules/local/segger/predict/main'


workflow SEGGER_CREATE_TRAIN_PREDICT {

    take:

    ch_basedir     // channel: [ val(meta), [ basedir ] ]
    ch_transcripts // channel: [Channel.fromPath(path)]

    main:

    ch_versions = Channel.empty()

    // create dataset
    SEGGER_CREATE_DATASET ( ch_basedir )
    ch_versions = ch_versions.mix ( SEGGER_CREATE_DATASET.out.versions.first() )

    // train a model with the dataset created
    SEGGER_TRAIN ( SEGGER_CREATE_DATASET.out.datasetdir )
    ch_versions = ch_versions.mix ( SEGGER_TRAIN.out.versions.first() )

    // run prediction with the trained models
    SEGGER_PREDICT ( SEGGER_CREATE_DATASET.out.datasetdir, SEGGER_TRAIN.out.trained_models, ch_transcripts )
    ch_versions = ch_versions.mix ( SEGGER_PREDICT.out.versions.first() )

    emit:

    datasetdir     = SEGGER_CREATE_DATASET.out.datasetdir // channel: [ val(meta), [ datasetdir ] ]
    trained_models = SEGGER_TRAIN.out.trained_models      // channel: [ val(meta), [ trained_models ] ]
    benchmarks     = SEGGER_PREDICT.out.benchmarks        // channel: [ val(meta), [ benchmarks ] ]
    transcripts    = SEGGER_PREDICT.out.transcripts       // channel: [ val(meta), [ transcripts ] ]

    versions       = ch_versions                          // channel: [ versions.yml ]
}
