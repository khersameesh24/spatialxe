//
// Run segger create_dataset, train and predict modules & parquet_to_csv
//

include { SEGGER_CREATE_DATASET } from '../../modules/local/segger/create_dataset/main'
include { SEGGER_TRAIN          } from '../../modules/local/segger/train/main'
include { SEGGER_PREDICT        } from '../../modules/local/segger/predict/main'
include { PARQUET_TO_CSV        } from '../../modules/local/spatialconverter/parquet_to_csv/main'

workflow SEGGER_CREATE_TRAIN_PREDICT {

    take:

    ch_basedir              // channel: [ val(meta), [ basedir ] ]
    ch_transcripts_parquet  // channel: [ val(meta), [bundle + "/transcripts.parquet"]]

    main:

    ch_versions = Channel.empty()

    // create dataset
    SEGGER_CREATE_DATASET ( ch_basedir )
    ch_versions = ch_versions.mix ( SEGGER_CREATE_DATASET.out.versions )

    // train a model with the dataset created
    SEGGER_TRAIN ( SEGGER_CREATE_DATASET.out.datasetdir )
    ch_versions = ch_versions.mix ( SEGGER_TRAIN.out.versions )

    // run prediction with the trained models
    ch_just_trained_models = SEGGER_TRAIN.out.trained_models.map {
                _meta, models -> return [ models ]
    }
    ch_just_transcripts_parquet = ch_transcripts_parquet.map {
                _meta, transcripts -> return [ transcripts ]
    }
    SEGGER_PREDICT ( SEGGER_CREATE_DATASET.out.datasetdir, ch_just_trained_models, ch_just_transcripts_parquet )
    ch_versions = ch_versions.mix ( SEGGER_PREDICT.out.versions )

    // convert parquet to csv
    PARQUET_TO_CSV( SEGGER_PREDICT.out.transcripts )
    ch_versions = ch_versions.mix( PARQUET_TO_CSV.out.versions )

    emit:

    datasetdir     = SEGGER_CREATE_DATASET.out.datasetdir // channel: [ val(meta), [ datasetdir ] ]
    trained_models = SEGGER_TRAIN.out.trained_models      // channel: [ val(meta), [ trained_models ] ]
    benchmarks     = SEGGER_PREDICT.out.benchmarks        // channel: [ val(meta), [ benchmarks ] ]
    ch_transcripts = PARQUET_TO_CSV.out.transcripts_csv   // channel: [ val(meta), [ transcripts ] ]

    versions       = ch_versions                          // channel: [ versions.yml ]
}
