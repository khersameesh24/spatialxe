process FICTURE_PREPROCESS {
    tag "$meta.id"
    label 'process_high'

    // TODO docker container on nf-core has ps error! (needs fix)
    container "heylf/ficture:0.0.4.0"

    input:
    tuple val(meta), path(transcripts)
    path(features)

    output:
    tuple val(meta), path("*processed_transcripts.tsv.gz")      , emit: transcripts
    path("*coordinate_minmax.tsv")                              , emit: coordinate_minmax
    path("*feature.clean.tsv.gz")                               , optional:true, emit: features
    path "versions.yml"                                         , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: ''
    template 'ficture_preprocess.py'

    stub:
    """
    mkdir -p "${meta.id}/ficture/preprocess/"
    touch ${meta.id}/ficture/preprocess/fake_file.txt

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        ficture_preprocess: v.1.0.0
    END_VERSIONS
    """
}
