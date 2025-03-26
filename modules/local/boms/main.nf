process BOMS {
    tag "$meta.id"
    label 'process_high'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/boms:1.1.0--py312h9c9b0c2_2':
        'biocontainers/boms:1.1.0--py312h9c9b0c2_2' }"

    input:
    tuple val(meta), path(transcripts)

    output:
    tuple val(meta), path("*_boms_segmentation_out.npy"), emit: segmentation_outs
    path("*_boms_counts_out.h5"),                         emit: count_matrix
    path("*_boms_cell_locations.npy"),                    emit: cell_locations
    path("*_boms_modes.npy"),                             emit: modes
    path("*_coordinates.npy"),                            emit: modes
    path "versions.yml",                                  emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def VERSION = "1.1.0"
    """
    template run_boms.py

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        boms: \$(${VERSION})
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch ${prefix}_boms_segmentation_out.npy
    touch ${prefix}_boms_counts_out.h5
    touch ${prefix}_boms_cell_locations.npy
    touch ${prefix}_boms_modes.npy
    touch ${prefix}_coordinates.npy
    touch versions.yml

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        boms: \$(${VERSION})
    END_VERSIONS
    """
}
