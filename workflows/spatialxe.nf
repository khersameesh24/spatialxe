/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

// multiqc
include { MULTIQC                } from '../modules/nf-core/multiqc/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { paramsSummaryMultiqc   } from '../subworkflows/nf-core/utils_nfcore_pipeline'

// nf-core functionality
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'
include { methodsDescriptionText } from '../subworkflows/local/utils_nfcore_spatialxe_pipeline'
include { fromSamplesheet           } from 'plugin/nf-validation'

// nf-core processes

// spatialxe utility modules
include { GUNZIP } from '../modules/nf-core/gunzip/main'

// local processes
include { SPATIALDATA_WRITE as SPATIALDATA_WRITE_RAW } from '../modules/local/spatialdata/write/main'
include { SPATIALDATA_WRITE as SPATIALDATA_WRITE_RESEGMENT } from '../modules/local/spatialdata/write/main'
include { SPATIALDATA_MERGE } from '../modules/local/spatialdata/merge/main'
include { SPATIALDATA_META } from '../modules/local/spatialdata/meta/main'

// segmentation processes
include { CELLPOSE } from '../modules/nf-core/cellpose/main'

include { XENIUMRANGER_IMPORT_SEGMENTATION } from '../modules/nf-core/xeniumranger/import-segmentation/main'

include { BAYSOR_RUN } from '../modules/local/baysor/run/main'
include { BAYSOR_SEGFREE } from '../modules/local/baysor/segfree/main'
include { BAYSOR_PREVIEW } from '../modules/local/baysor/preview/main'

// subworkflows
include { SEGGER_CREATE_TRAIN_PREDICT } from '../subworkflows/local/segger_create_train_predict.nf'
include { PROSEG_RUN_PROSEG2BAYSOR    } from '../subworkflows/local/proseg_proseg_proseg2baysor.nf'
include { FICTURE_PREPROCESS_MODEL    } from '../subworkflows/local/ficture_preprocess_model.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SPATIALXE {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_segmentation_mask = Channel.empty()

    ch_samplesheet.view()

    // Start subworkflow with segmentation (+- refinement)

    // Start subworkflow without segmentation

    // Just run xeniumranger parts (+- refinemnet)

    // Just do QC
    ch_bundle = ch_samplesheet.map {
        meta, bundle, image -> return [ meta, bundle ]
    }

    ch_transcripts = ch_samplesheet.map {
        meta, bundle, image -> return [ meta, bundle + "/transcripts.csv.gz" ]
    }

    ch_transcripts_parquet = ch_samplesheet.map {
        meta, bundle, image -> return [ meta, bundle + "/transcripts.parquet" ]
    }

    ch_image = ch_samplesheet.map {
            meta, bundle, image -> return [ meta, image ]
    }

    SPATIALDATA_WRITE_RAW(
        ch_bundle,
        'spatialdata_raw'
    )
    ch_versions = ch_versions.mix(SPATIALDATA_WRITE_RAW.out.versions)

    if ( params.segmentation_refinement ) {

        SEGGER_CREATE_TRAIN_PREDICT (
            ch_basedir,
            ch_transcripts_parquet
        )
    }

    if ( params.segmentation in params.seg_methods ){

        if ( params.segmentation == 'cellpose' ){

            CELLPOSE(
                ch_image,
                []
            )

            ch_versions = ch_versions.mix(CELLPOSE.out.versions)

            ch_nulcleus_segmentation = CELLPOSE.out.mask.map {
                meta, mask -> return [ mask ]
            }

            // you need the morphology_focus.tif the normal morpholly.tif might thow an error in
            // xenium ranger import.
            ch_cells_segmenetation = CELLPOSE.out.cells.map {
                meta, cells -> return [ cells ]
            }

            ch_cells_segmenetation.view()

            XENIUMRANGER_IMPORT_SEGMENTATION(
                ch_bundle,
                [],
                [],
                ch_nulcleus_segmentation,
                [],
                [],
                [],
                []
            )
            ch_versions = ch_versions.mix(XENIUMRANGER_IMPORT_SEGMENTATION.out.versions)

        }

        if ( params.segmentation == 'proseg' ){

            PROSEG_RUN_PROSEG2BAYSOR( ch_transcripts )

            // TODO https://github.com/dcjones/proseg defines here to use --units microns, do we need to do this?
            XENIUMRANGER_IMPORT_SEGMENTATION(
                ch_bundle,
                [],
                [],
                [],
                [],
                PROSEG2BAYSOR.out.xr_metadata,
                PROSEG2BAYSOR.out.xr_polygons,
                "microns"
            )
            ch_versions = ch_versions.mix(XENIUMRANGER_IMPORT_SEGMENTATION.out.versions)

        }

        if ( params.segmentation == 'baysor_segmentation' ){

            GUNZIP( ch_transcripts )
            ch_versions = ch_versions.mix(GUNZIP.out.versions)

            if ( params.baysor_rerun ){

                // TODO baysor container needs julia package OMETIFF

                ch_just_image = ch_image.map {
                    meta, image -> return [ image ]
                }

                BAYSOR_RUN(
                    GUNZIP.out.gunzip,
                    ch_just_image,
                    30 // TODO probably better to inroduce a parameter here
                )
                ch_versions = ch_versions.mix(BAYSOR_RUN.out.versions)

                ch_segmentation = BAYSOR_RUN.out.segmentation.map {
                    meta, segmentation -> return [ segmentation ]
                }

            } else {
                BAYSOR_RUN(
                    GUNZIP.out.gunzip,
                    [],
                    30 // TODO probably better to inroduce a parameter here
                )
                ch_versions = ch_versions.mix(BAYSOR_RUN.out.versions)

                ch_segmentation = BAYSOR_RUN.out.segmentation.map {
                    meta, segmentation -> return [ segmentation ]
                }

                XENIUMRANGER_IMPORT_SEGMENTATION(
                    ch_bundle,
                    [],
                    [],
                    [],
                    [],
                    ch_segmentation,
                    BAYSOR_RUN.out.polygons2d,
                    "microns"
                )
                ch_versions = ch_versions.mix(XENIUMRANGER_IMPORT_SEGMENTATION.out.versions)
            }

        }

    }

    if ( params.segmentation in params.segfree_methods ) {


        if ( params.segmentation == 'ficture' ) {

            FICTURE_PREPROCESS_MODEL ( ch_transcripts, [] )

        }

        if ( params.segmentation == 'baysor_segmentation_free' ) {

            GUNZIP( ch_transcripts )
            ch_versions = ch_versions.mix(GUNZIP.out.versions)

            BAYSOR_SEGFREE(
                GUNZIP.out.gunzip
            )
            ch_versions = ch_versions.mix(BAYSOR_SEGFREE.out.versions)

        }

    }

    if ( params.segmentation == 'baysor_preview' ) {

        GUNZIP( ch_transcripts )
        ch_versions = ch_versions.mix(GUNZIP.out.versions)

        BAYSOR_PREVIEW(
            GUNZIP.out.gunzip
        )
        ch_versions = ch_versions.mix(BAYSOR_PREVIEW.out.versions)

    }

    SPATIALDATA_WRITE_RESEGMENT(
        XENIUMRANGER_IMPORT_SEGMENTATION.out.bundle,
        'spatialdata_resegement'
    )
    ch_versions = ch_versions.mix(SPATIALDATA_WRITE_RESEGMENT.out.versions)

    SPATIALDATA_MERGE(
        SPATIALDATA_WRITE_RAW.out.spatialdata,
        SPATIALDATA_WRITE_RESEGMENT.out.spatialdata
    )

    SPATIALDATA_META(
        SPATIALDATA_MERGE.out.spatialxe_bundle,
        ch_bundle
    )
    ch_versions = ch_versions.mix(SPATIALDATA_META.out.versions)

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name: 'nf_core_'  +  'spatialxe_software_'  + 'mqc_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    //
    // MODULE: MultiQC
    //
    ch_multiqc_config        = Channel.fromPath(
        "$projectDir/assets/multiqc_config.yml", checkIfExists: true)
    ch_multiqc_custom_config = params.multiqc_config ?
        Channel.fromPath(params.multiqc_config, checkIfExists: true) :
        Channel.empty()
    ch_multiqc_logo          = params.multiqc_logo ?
        Channel.fromPath(params.multiqc_logo, checkIfExists: true) :
        Channel.empty()

    summary_params      = paramsSummaryMap(
        workflow, parameters_schema: "nextflow_schema.json")
    ch_workflow_summary = Channel.value(paramsSummaryMultiqc(summary_params))
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_workflow_summary.collectFile(name: 'workflow_summary_mqc.yaml'))
    ch_multiqc_custom_methods_description = params.multiqc_methods_description ?
        file(params.multiqc_methods_description, checkIfExists: true) :
        file("$projectDir/assets/methods_description_template.yml", checkIfExists: true)
    ch_methods_description                = Channel.value(
        methodsDescriptionText(ch_multiqc_custom_methods_description))

    ch_multiqc_files = ch_multiqc_files.mix(ch_collated_versions)
    ch_multiqc_files = ch_multiqc_files.mix(
        ch_methods_description.collectFile(
            name: 'methods_description_mqc.yaml',
            sort: true
        )
    )

    MULTIQC (
        ch_multiqc_files.collect(),
        ch_multiqc_config.toList(),
        ch_multiqc_custom_config.toList(),
        ch_multiqc_logo.toList(),
        [],
        []
    )

    emit:multiqc_report = MULTIQC.out.report.toList() // channel: /path/to/multiqc_report.html
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
