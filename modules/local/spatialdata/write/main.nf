process SPATIALDATA_WRITE {
    tag "$meta.id"
    label 'process_high'

    container "ghcr.io/scverse/spatialdata:spatialdata0.3.0_spatialdata-io0.1.7_spatialdata-plot0.2.9"

    // Exit if running this module with -profile conda / -profile mamba
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        exit 1, "SPATIALDATA_WRITE module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    input:
    tuple val(meta), path(bundle, stageAs: "*")

    output:
    tuple val(meta), path("spatialdata/**")           , emit: spatialdata
    path "versions.yml"                               , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'spatialdatawrite.py'

    stub:
    """
    mkdir -p "spatialdata/"
    touch spatialdata/fake_file.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        spatialdata: \$(echo \$( python -c "import spatialdata; print(spatialdata.__version__)" 2>&1) )
    END_VERSIONS
    """

}
