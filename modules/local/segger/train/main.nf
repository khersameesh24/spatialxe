process SEGGER_TRAIN {
    tag "$meta.id"
    label 'process_high'

    container "heylf/segger:0.1.0"

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
    def script_path = "${task.cli_dir}" + "/train_model.py"
    """

    python3 ${script_path} \\
        --dataset_dir ${dataset_dir} \\
        --models_dir ${meta.id}_trained_models \\
        --sample_tag ${meta.id} \\
        --num_workers ${task.cpus} \\
        --init_emb 8 \\
        --hidden_channels 32 \\
        --num_tx_tokens 500 \\
        --out_channels 8 \\
        --heads 2 \\
        --num_mid_layers 2 \\
        --batch_size 4 \\
        --accelerator cpu \\
        --num_workers 2 \\
        --max_epochs 200 \\
        --devices 4 \\
        --strategy auto \\
        --precision 16-mixed

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