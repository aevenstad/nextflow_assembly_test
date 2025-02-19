process LRE_FINDER {
    publishDir "${params.outdir}/${meta.id}/10_lre-finder", mode: 'copy'
    containerOptions "-B /bigdata/Jessin/Softwares/lre-finder/elmDB/:/mnt/db"
    tag "$meta.id"

    container '/bigdata/Jessin/Softwares/containers/lre-finder_v1.0.0.sif'

    input:
    tuple val(meta), path(species)
    tuple val(meta), path(reads)

    output:
    tuple val(meta), path("*.txt")                 , emit: txt
    tuple val(meta), path("*.res")                 , optional: true
    tuple val(meta), path("*.pos")                 , optional: true
    tuple val(meta), path("*.fsa")                 , optional: true
    tuple val(meta), path("*.aln")                 , optional: true
    tuple val(meta), path("*.gz")                  , optional: true

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def args = task.ext.args ?: '-ID 90 -1t1 -cge -matrix'
    """

    species_content=\$(cat $species)
    echo "Species file content: \$species_content"

    if [[ "\$species_content" == *"Enterococcus"* ]]; then
        LRE-Finder.py \\
        -ipe ${reads[0]} ${reads[1]} \\
        -o ./${prefix} \\
        -t_db /mnt/db/elm \\
        $args |\\
        html2text > LRE-Finder_out.txt
    
    else
        echo "Skipping LRE-Finder..."
        echo "LRE-Finder skipped for \$species_content" > lre-finder_skipped.txt
    fi
    cat <<-END_VERSIONS > versions.yml
    "${task.process}":
        LRE-Finder: \$(LRE-Finder.py -V)
    END_VERSIONS
    """
}