process SEGGER_TRAIN {
    tag "$meta.id"
    label 'process_high'

    container "khersameesh24/segger:0.1.0"

    input:
    tuple val(meta), path(dataset_dir)

    output:
    tuple val(meta), path("${meta.id}_trained_models")   , emit: trained_models
    path("versions.yml")                                 , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER_TRAIN module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def script_path = "${System.getenv('SEGGER_TRAIN_MODEL')}"


    """
    python3 ${script_path} \\
        --dataset_dir ${dataset_dir} \\
        --models_dir ${meta.id}_trained_models \\
        --sample_tag ${meta.id} \\
        --num_workers ${task.cpus} \\
        --batch_size ${params.batch_size} \\
        --devices ${params.devices} \\
        --accelerator ${params.accelerator} \\
        --max_epochs ${params.max_epochs} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: "${task.version}"
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p models_dir/
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: "${task.version}"
    END_VERSIONS
    """
}
