process XENIUMRANGER_RESEGMENT {
    tag "$meta.id"
    label 'process_high'

    container "nf-core/xeniumranger:3.1.1"

    input:
    tuple val(meta), path(xenium_bundle)

    output:
    tuple val(meta), path("${meta.id}/outs"), emit: bundle
    path("versions.yml")                    , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "XENIUMRANGER_RESEGMENT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ""
    def prefix = task.ext.prefix ?: "${meta.id}"

    // Do not use boundary stain in analysis, but keep default interior stain and DAPI
    def boundary_stain = "${params.boundary_stain}" ? "": "--boundary-stain=disable"
    // Do not use interior stain in analysis, but keep default boundary stain and DAPI
    def interior_stain = "${params.interior_stain}" ? "": "--interior-stain=disable"

    """
    xeniumranger resegment \\
        --id="${prefix}" \\
        --xenium-bundle="${xenium_bundle}" \\
        --expansion-distance=${params.expansion_distance} \\
        --dapi-filter=${params.dapi_filter} \\
        ${boundary_stain} \\
        ${interior_stain} \\
        --localcores=${task.cpus} \\
        --localmem=${task.memory.toGiga()} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        xeniumranger: \$(xeniumranger -V | sed -e "s/xeniumranger-/- /g")
    END_VERSIONS
    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "XENIUMRANGER_RESEGMENT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p "${prefix}/outs/"
    touch "${prefix}/outs/fake_file.txt"

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        xeniumranger: \$(xeniumranger -V | sed -e "s/xeniumranger-/- /g")
    END_VERSIONS
    """
}
