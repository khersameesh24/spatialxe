process BAYSOR_RUN {
    tag "$meta.id"
    label 'process_high'
    container "nf-core/baysor:0.7.1" // TODO julia package OMETIFF needs to be added

    input:
    tuple val(meta), path(transcripts)
    path(prior_segmentation)
    val(scale)

    output:
    tuple val(meta), path("segmentation.csv")   , emit: segmentation
    path "segmentation_polygons_2d.json"        , emit: polygons2d
    path "segmentation_polygons_3d.json"        , emit: polygons3d
    path("*.toml")                              , emit: params
    path("*.log")                               , emit: log
    path("*.loom")                              , emit: loom
    path("*.html")                              , emit: htmls
    path("segmentation_cell_stats.csv")         , emit: stats
    path "xenium.toml"                          , emit: config
    path "versions.yml"                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"
    def prior_segmentation = prior_segmentation ? prior_segmentation: ""
    def scale = scale ? "--scale=${scale}": ""

    """
    echo "$task.baysor_xenium_config" > xenium.toml

    baysor run \\
    $transcripts \\
    $prior_segmentation \\
    $scale \\
    --plot \\
    --config xenium.toml \\
    --polygon-format=GeometryCollectionLegacy

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        baysor: $task.version
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "BAYSOR_RUN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix  = task.ext.prefix ?: "${meta.id}"

    """
    touch segmentation.csv
    touch segmentation_polygons_2d.json
    touch segmentation_log.log
    touch segmentation_counts.loom
    touch segmentation_cell_stats.csv
    touch segmentation_params.dump.toml

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        baysor: $task.version
    END_VERSIONS
    """
}