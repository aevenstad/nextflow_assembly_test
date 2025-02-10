process KLEBORATE {
    publishDir "${params.outdir}/${meta.id}", mode: 'copy'
    label 'process_medium'

    conda "${moduleDir}/environment.yml"
    container "${ workflow.containerEngine == 'singularity' && !task.ext.singularity_pull_docker_container ?
        'https://depot.galaxyproject.org/singularity/kleborate:3.1.2--pyhdfd78af_0' :
        'biocontainers/kleborate:3.1.2--pyhdfd78af_0' }"

    input:
    tuple val(meta), path(species)
    tuple val(meta), path(fastas)

    output:
    tuple val(meta), path("*/*.txt"), emit: txt
    //path "versions.yml"           , emit: versions

    when:
    task.ext.when == null || task.ext.when

    script:
    def args = task.ext.args ?: '-p kpsc'
    def prefix = task.ext.prefix ?: "${meta.id}"

    """
    species_content=\$(cat $species)
    echo "Species file content: \$species_content"
    
    if [[ "\$species_content" == *"Klebsiella"* ]]; then
        kleborate \\
        $args \\
        --outdir 7_kleborate \\
        --assemblies $fastas

        #cat <<END_VERSIONS > versions.yml
        #"${task.process}":
        #    kleborate: \$(kleborate --version | sed 's/Kleborate v//;')
        #END_VERSIONS
    else
        echo "Skipping Kleborate..."
        #touch skip_marker.txt  // Optional: create a file to mark the process as skipped
        mkdir -p 7_kleborate
        echo "Kleborate skipped for \$species_content" > 7_kleborate/kleborate_skipped.txt
    fi  
    """

    stub:
    def prefix = task.ext.prefix ?: "${meta.id}"
    """
    touch ${prefix}.results.txt

    #cat <<END_VERSIONS > versions.yml
    #"${task.process}":
    #    kleborate: \$(kleborate --version | sed 's/Kleborate v//;')
    #END_VERSIONS
    """
}
