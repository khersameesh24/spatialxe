process SEGGER_TRAIN_MODEL {
    tag "$meta.id"
    label 'process_high'

    container "nf-core/segger:0.1.0"

    input:
    tuple val(meta), path(dataset_dir)
    val(sample_tag)

    output:
    tuple val(meta), path("trained_models"), emit: trained_models
    path("versions.yml"),                    emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER_TRAIN_MODEL module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def script_path = "${params.cli_dir}" + "/train_model.py"
    """
    python3 ${script_path} \\
        --dataset_dir ${dataset_dir} \\
        --models_dir trained_models \\
        --sample_tag ${sample_tag} \\
        --num_workers ${task.cpus} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: "${params.version}"
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p models_dir/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: "${params.version}"
    END_VERSIONS
    """
}
