process SKESA {
    publishDir "${params.outdir}/${meta.id}/10_skesa", mode: 'copy'
    tag "$meta.id"
    label 'process_medium'
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/skesa:2.5.1--hdcf5f25_1':
        'quay.io/biocontainers/skesa:2.5.1--hdcf5f25_1' }"

    input:
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.fasta")                 , emit: contigs
    path "versions.yml"                             , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: ''
    """

    skesa --cores $task.cpus --reads ${reads[0]},${reads[1]} --contigs_out ${prefix}.fasta

    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        skesa: \$(skesa --version 2>&1 | tail -1 | awk '{ print \$2 }' | sed 's/v\\.//')
    END_VERSIONS

    """

}