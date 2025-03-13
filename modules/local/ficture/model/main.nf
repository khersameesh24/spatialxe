process FICTURE {
    tag "$meta.id"
    label 'process_high'

    // TODO docker container on nf-core has ps error! (needs fix)
    container "heylf/ficture:0.0.4.0"

    input:
    tuple val(meta), path(transcripts)
    path(coordinate_minmax)
    path(features)

    output:
    tuple val(meta), path("results/**")     , emit: results 
    path "versions.yml"                     , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def features = features ? "--in-feature ${features}": ""

    """
    ficture run_together \\
        --in-tsv $transcripts \\
        --in-minmax $coordinate_minmax \\
        $features \\
        --out-dir results \\
        --train-width 12,18 \\
        --n-factor 6,12 \\
        --n-jobs 4 \\
        --plot-each-factor \\
        --all

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ficture: \$(pip show ficture | grep "^Version:" | awk '{print \$2}')
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p results/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ficture: \$(pip show ficture | grep "^Version:" | awk '{print \$2}')
    END_VERSIONS
    """
}
