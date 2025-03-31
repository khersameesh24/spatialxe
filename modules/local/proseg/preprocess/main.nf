process PROSEG2BAYSOR {
    tag "$meta.id"
    label 'process_high'

    container "khersameesh24/proseg:2.0.0"

    input:
    tuple val(meta), path(cell_polygons)
    path(transcript_metadata)

    output:
    path("xr-transcript-metadata.csv"), emit: xr_metadata
    path("xr-cell-polygons.geojson"), emit: xr_polygons
    path("versions.yml"), emit: versions

    script:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PROSEG2BAYSOR (preprocess) module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    """
    proseg-to-baysor  \
        ${transcript_metadata} \
        ${cell_polygons} \
        --output-transcript-metadata xr-transcript-metadata.csv \
        --output-cell-polygons xr-cell-polygons.geojson

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        proseg: \$(proseg --version | sed 's/proseg //')
    END_VERSIONS

    """

    stub:
    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "PROSEG module does not support Conda. Please use Docker / Singularity / Podman instead."
    }
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    touch xr-transcript-metadata.csv
    touch xr-cell-polygons.geojson

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        proseg: \$(proseg --version | sed 's/proseg //')
    END_VERSIONS
    """
}

