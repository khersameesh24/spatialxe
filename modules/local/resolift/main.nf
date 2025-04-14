process RESOLIFT {
    tag "$meta.id"
    label 'process_medium'

    container "quay.io/khersameesh24/resolift:1.0.0"

    input:
    tuple val(meta), path(input)

    output:
    tuple val(meta), path("*.tiff"), emit: enhanced_tiff
    path("versions.yml")           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "ResoLift module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    if ("$input" == "${prefix}.tiff") error "Input and output names are the same, set prefix in module configuration to disambiguate!"
    def VERSION = '1.0.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    resolift \\
        -i $input \\
        -o ${prefix}.tiff \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resolift: ${VERSION}
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "ResoLift module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def prefix = task.ext.prefix ?: "${meta.id}"
    if ("$input" == "${prefix}.tiff") error "Input and output names are the same, set prefix in module configuration to disambiguate!"
    def VERSION = '1.0.0' // WARN: Version information not provided by tool on CLI. Please update this string when bumping container versions.

    """
    touch ${prefix}.tiff

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        resolift: ${VERSION}
    END_VERSIONS
    """
}
