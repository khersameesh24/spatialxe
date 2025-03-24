process GRANDQC_TISSUE {
    tag "$meta.id"
    label 'process_high'

    container "khersameesh24/grandqc:045b7a2d765ef0daa046609f93218312287a92d0"

    input:
    tuple val(meta), path(slide_folder)
    path(output_dir)
    val(qc_mpp_model)

    output:
    tuple val(meta), path(*.geojson)

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "GRANDQC module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    echo "Generating Tissue Segmentation"

    python $OME_TIFF_QC/wsi_tis_detect.py \\
    --slide_folder "${slide_folder}" \\
    --output_dir "${output_dir}" \\
    --mpp "${qc_mpp_model}"

    if [ $? -eq 0 ]; then echo Tissue Segmentation compeleted!; else echo Tissue Segmentation failed; fi

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        grandqc: "version not implemented"
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "GRANDQC module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${output_dir}/*.geojson

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        grandqc: "version not implemented"
    END_VERSIONS
    """
}
