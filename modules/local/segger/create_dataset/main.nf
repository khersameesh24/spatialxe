process SEGGER_CREATE_DATASET {
    tag "$meta.id"
    label 'process_high'

    container "nf-core/segger:0.1.0"

    input:
    tuple val(meta), path(base_dir)

    output:
    tuple val(meta), path("segger_dataset"), emit: segger_dataset
    path("versions.yml")                   , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER_CREATE_DATASET module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def script_path = "${params.cli_dir}" + "/create_dataset_fast.py"
    def sample_type = "${params.sample_type}" ?: "xenium"
    """
    python3 ${script_path} \\
        --base_dir ${base_dir} \\
        --data_dir segger_dataset \\
        --sample_type ${sample_type} \\
        --n_workers ${task.cpus}
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: ${params.version}
    END_VERSIONS
    """

    stub:
    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    mkdir -p segger_dataset/

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: ${params.version}
    END_VERSIONS
    """
}
