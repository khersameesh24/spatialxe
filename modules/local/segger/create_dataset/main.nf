process SEGGER_CREATE_DATASET {
    tag "$meta.id"
    label 'process_high'

    // TODO update segger container
    // TODO segger container is massive needs a reduction at some point, at least we need a warning for now
    container "khersameesh24/segger:0.1.0"

    input:
    tuple val(meta), path(base_dir)

    output:
    tuple val(meta), path("${meta.id}") , emit: datasetdir
    path("versions.yml")                , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    if (workflow.profile.tokenize(',').intersect(['conda', 'mamba']).size() >= 1) {
        error "SEGGER_CREATE_DATASET module does not support Conda. Please use Docker / Singularity / Podman instead."
    }

    def args = task.ext.args ?: ''
    def prefix = task.ext.prefix ?: "${meta.id}"
    def script_path = "${task.cli_dir}" + "/create_dataset_fast.py"
    def script_path = "${System.getenv('SEGGER_CREATE_DATASET')}"


    // check for platform values
    if ( !(params.format in ['xenium']) ) {
        error "${params.format} is an invalid platform type. Please specify xenium, cosmx, or merscope"
    }

    """
    python3 ${script_path} \\
        --base_dir ${base_dir} \\
        --data_dir ${meta.id} \\
        --sample_type ${params.format} \\
        --n_workers ${task.cpus} \\
        --tile_width ${task.tile_width} \\
        --tile_height ${task.tile_height} \\
        ${args}

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: ${task.version}
    END_VERSIONS
    """

    stub:
    """
    mkdir -p segger_dataset/
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        segger: ${task.version}
    END_VERSIONS
    """
}
