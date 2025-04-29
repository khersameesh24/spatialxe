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
include { fromSamplesheet        } from 'plugin/nf-validation'

// nf-core processes
include { GUNZIP } from '../modules/nf-core/gunzip/main'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPATIALXE - SEGMENTATION LAYER
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// coordinate-based segmentation subworklfows
include { SEGGER_CREATE_TRAIN_PREDICT                      } from '../subworkflows/local/segger_create_train_predict.nf'
include { PROSEG_PRESET_PROSEG2BAYSOR                      } from '../subworkflows/local/proseg_preset_proseg2baysor.nf'
include { FICTURE_PREPROCESS_MODEL                         } from '../subworkflows/local/ficture_preprocess_model.nf'
include { BAYSOR_PREVIEW_RUN_SEGFREE                       } from '../subworkflows/local/baysor_run_preview_segfree.nf'

// image-based segmentation subworklfows
include { CELLPOSE_RESOLIFT_MORPHOLOGY_OME_TIF             } from '../subworkflows/local/cellpose_resolift_morphology_ome_tif.nf'
include { XENIUMRANGER_RESEGMENT_MORPHOLOGY_OME_TIF        } from '../subworkflows/local/xeniumranger_resegment_morphology_ome_tif.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPATIALXE - SPATIALDATA LAYER
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// spatialdata subworkflows
include { SPATIALDATA_WRITE_META_MERGE                     } from '../subworkflows/local/spatialdata_write_meta_merge.nf'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    SPATIALXE - XENIUMRANGER LAYER
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
// xeniumranger subworkflows
include { XENIUMRANGER_RELABEL_RESEGMENT                   } from '../subworkflows/local/xeniumranger_relabel_resegment.nf'
include { XENIUMRANGER_IMPORT_SEGMENTATION_REDEFINE_BUNDLE } from '../subworkflows/local/xeniumranger_import_segmentation_redefine_bundle.nf'


// TODO qc layer subworkflows

// TODO metadata layer subworkflows

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow SPATIALXE {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

// ============================== generate input channels ===================================

    ch_versions = Channel.empty()
    ch_multiqc_files = Channel.empty()
    ch_segmentation_mask = Channel.empty()

    ch_samplesheet.view()

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

    ch_raw_bundle = Channel.empty()
    ch_refined_bundle = Channel.empty()

// ============================== raw data layer =======================================

    // run xr relabel if relabel_genes is true, check if gene_panel.json is provided
    if ( params.relabel_genes && params.gene_panel ) {

        ch_gene_panel = Channel.fromPath( params.gene_panel, checkIfExists: true )
        XENIUMRANGER_RELABEL_RESEGMENT (
            ch_bundle,
            ch_gene_panel
        )
        ch_raw_bundle = XENIUMRANGER_RELABEL_RESEGMENT.out.redefined_bundle

    } else {

        ch_raw_bundle = ch_samplesheet.map {
            meta, bundle, image -> return [ meta, bundle ]
        }
    }

// ============================== data preview layer =======================================

    // run baysor preview if `generate_preview ` is true
    BAYSOR_PREVIEW_RUN_SEGFREE (
        [],
        ch_transcripts,
        []
    )

// ============================== segmentation layer =======================================

    // --------------------------image-based segmentation--------------------------------------


    if ( params.image_based ) {

        // run xeniumranger resegment with morphology_ome.tif
        if ( params.segmentation == 'xeniumranger' ) {

            XENIUMRANGER_RESEGMENT_MORPHOLOGY_OME_TIF (
                ch_raw_bundle
            )
            ch_refined_bundle = XENIUMRANGER_RESEGMENT_MORPHOLOGY_OME_TIF.out.redefined_bundle
        }

        // run baysor run with morphology_ome.tif
        if ( params.segmentation == 'baysor' ) {

            BAYSOR_PREVIEW_RUN_SEGFREE (
                ch_raw_bundle,
                [],
                ch_image
            )
            ch_refined_bundle = BAYSOR_PREVIEW_RUN_SEGFREE.out.redefined_bundle
        }

        // run cellpose on the morphology_ome.tif
        if ( params.segmentation == 'cellpose' ) {

            CELLPOSE_RESOLIFT_MORPHOLOGY_OME_TIF (
                ch_image,
                ch_raw_bundle
            )
            ch_refined_bundle = CELLPOSE_RESOLIFT_MORPHOLOGY_OME_TIF.out.redefined_bundle
        }

    }

    // ----------------------transcript-based segmentation-----------------------------------

    // run proseg with transcripts.csv.gz
    if ( params.coordinate_based ) {

        // run proseg with transcripts.csv.gz
        if ( params.segmentation == 'proseg' ) {

            PROSEG_PRESET_PROSEG2BAYSOR (
                ch_raw_bundle,
                ch_transcripts
            )
            ch_refined_bundle = PROSEG_PRESET_PROSEG2BAYSOR.out.redefined_bundle
        }

        // run segger with transcripts.csv.gz
        if ( params.segmenattion == 'segger' ) {

            SEGGER_CREATE_TRAIN_PREDICT (
                ch_raw_bundle,
                ch_transcripts_parquet
            )

        }

        // run baysor with transcripts.csv.gz
        if ( params.segmenattion == 'baysor' ) {

            BAYSOR_PREVIEW_RUN_SEGFREE (
                ch_raw_bundle,
                ch_transcripts,
                []
            )
            ch_refined_bundle = BAYSOR_PREVIEW_RUN_SEGFREE.out.redefined_bundle
        }

    }

// ============================== Xeniumranger layer =======================================

    // run only xeniumranger import segmentation with changes xr specific params
    if  ( params.xeniumranger_only ) {

        XENIUMRANGER_IMPORT_SEGMENTATION_REDEFINE_BUNDLE (
            ch_raw_bundle
        )
        ch_refined_bundle = XENIUMRANGER_IMPORT_SEGMENTATION_REDEFINE_BUNDLE.out.redefined_bundle
    }




// ============================== spatialdata layer =======================================

    // run spatialdata modules to generate sd objects
    SPATIALDATA_WRITE_META_MERGE (
        ch_raw_bundle,
        ch_refined_bundle
    )

// ================================== QC layer ============================================


// ============================== metadata layer ==========================================


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
