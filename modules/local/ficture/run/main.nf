process FICTURE_RUN {
    tag "$meta.id"
    label 'process_high'

    container "nf-core/ficture:0.0.4.0"

    input:
    tuple val(meta), path(transcripts)
    val(features)

    output:
    tuple val(meta), path("ficture_outs"), emit: ficture_outs
    path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def negctrl_regex = "${params.negative_control_regex}" ? : "BLANK\|NegCon"

    """
    ficture_preprocess.py \\
    --input ${transcripts} \\
    --output filtered.matrix.tsv \\
    --feature feature.clean.tsv.gz \\
    --min_phred_score 15 \\
    --dummy_genes ${negctrl_control_regex}


    ficture run_together \\
    --in-tsv filtered.matrix.tsv \\
    --in-minmax coordinate_minmax.tsv \\
    --in-feature feature.clean.tsv.gz \\
    --out-dir ficture_outs \\
    --train-width 12,18 \\
    --n-factor 6,12 \\
    --n-jobs 4 \\
    --plot-each-factor \\
    --all

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ficture: "${params.version}"
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p ficture_outs/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ficture: "${params.version}"
    END_VERSIONS
    """
}
