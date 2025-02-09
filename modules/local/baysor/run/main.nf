process BAYSOR_RUN {
    tag '$meta.id'
    label 'process_high'
    container "nf-core/baysor:0.7.1"

    input:
    tuple val(meta), path(transcripts)
    path(prior_segmentation)

    output:
    tuple val(meta), path("*segmentation.csv"), emit: segmentation
    path("*.json"),                             emit: polygons
    path("*.toml"),                             emit: params
    path("*.log"),                              emit: log
    path("*.loom"),                             emit: loom
    path("segmentation_cell_stats.csv"),        emit: stats
    path "versions.yml",                        emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def VERSION = "${params.version}"

    """
    baysor run \\
    ${transcripts} \\
    ${args} \\
    --plot

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        baysor: $VERSION
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def VERSION = "${params.version}"

    """
    touch segmentation.csv
    touch segmentation_polygons_2d.json
    touch segmentation_log.log
    touch segmentation_counts.loom
    touch segmentation_cell_stats.csv
    touch segmentation_params.dump.toml

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        baysor: $VERSION
    END_VERSIONS
    """
}
