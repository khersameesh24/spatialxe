process SEGGER_PREDICT {
    tag "$meta.id"
    label 'process_gpu'

    container "khersameesh24/segger:0.1.0"

    input:
    tuple val(meta), path(segger_dataset)
    path(models_dir)
    path(transcripts)


    output:
    tuple val(meta), path("${meta.id}_benchmarks_dir")                                  , emit: benchmarks
    tuple val(meta), path("${meta.id}_benchmarks_dir/*/segger_transcripts.parquet")     , emit: transcripts
    path("versions.yml")                                                                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER_PREDICT module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def script_path = "${env('SEGGER_PREDICT')}"

    """
    python3 ${script_path} \\
        --models_dir ${models_dir} \\
        --segger_data_dir ${segger_dataset} \\
        --transcripts_file ${transcripts} \\
        --benchmarks_dir ${meta.id}_benchmarks_dir \\
        --num_workers ${task.cpus} \\
        --use_cc ${params.cc_analysis} \\
        --knn_method ${params.knn_method} \\
        --batch_size ${params.batch_size} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: ${task.version}
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p benchmarks_dir/
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: ${task.version}
    END_VERSIONS
    """
}
