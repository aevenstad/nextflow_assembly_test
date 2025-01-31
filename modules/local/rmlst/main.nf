process RMLST {
    tag "$meta.id"
    label 'process_low'

    // conda "${moduleDir}/environment.yml"
    container '/bigdata/Jessin/Softwares/containers/rMLST.sif'

    input:
    tuple val(meta), path(fasta)

    output:
    tuple val(meta), path("*.txt"), emit: txt

    when:
    task.ext.when == null || task.ext.when

    script:
    def prefix = task.ext.prefix ?: "${meta.id}"
    def fastaOption = fasta ? "--file $fasta" : ''
    """
    python3 /opt/rMLST/species_api_upload.py $fastaOption > ${prefix}_rmlst.txt
    """
}