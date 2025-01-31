/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { FASTP                  } from '../modules/nf-core/fastp/main'
include { SHOVILL                } from '../modules/nf-core/shovill/main'
include { QUAST                  } from '../modules/nf-core/quast/main'
include { MLST                   } from '../modules/nf-core/mlst/main'
include { RMLST                  } from '../modules/local/rmlst/main'
include { paramsSummaryMap       } from 'plugin/nf-schema'
include { softwareVersionsToYAML } from '../subworkflows/nf-core/utils_nfcore_pipeline'

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    RUN MAIN WORKFLOW
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/

workflow ASSEMBLY {

    take:
    ch_samplesheet // channel: samplesheet read in from --input
    main:

    ch_versions = Channel.empty()
    //
    // MODULE: Run FastQC
    //
    FASTQC (
        ch_samplesheet
    )
    
    ch_versions = ch_versions.mix(FASTQC.out.versions.first())


    //
    // MODULE: Run Fastp (Trimming)
    //
    FASTP (
        ch_samplesheet,
        false, // discard_trimmed_pass
        false, // save_trimmed_fail
        false // save merged
    )
    ch_trimmed = FASTP.out.reads // Outputs trimmed FASTQ files
    ch_versions = ch_versions.mix(FASTP.out.versions.first())

    //
    // MODULE: Run Shovi (Assembly)
    //
    SHOVILL (
        ch_trimmed,
    )
    ch_assembly = SHOVILL.out.contigs // Outputs assembled contigs
    ch_versions = ch_versions.mix(SHOVILL.out.versions.first())

    //
    // MODULE: Run Quast (Assembly Evaluation)
    //
    QUAST (
        ch_assembly
    )
    ch_quast = QUAST.out.results // Outputs Quast report
    ch_versions = ch_versions.mix(QUAST.out.versions.first())

    //
    // MODULE: Run MLST (Multi Locus Sequence Typing)
    //
    MLST (
        ch_assembly
    )
    ch_mlst = MLST.out.tsv // Outputs Quast report
    ch_versions = ch_versions.mix(MLST.out.versions.first())

    //
    // MODULE RMLST (Run MLST)
    //
    RMLST (
        ch_assembly
    )
    ch_rmlst = RMLST.out.txt // Outputs rMLST results

    //
    // Collate and save software versions
    //
    softwareVersionsToYAML(ch_versions)
        .collectFile(
            storeDir: "${params.outdir}/pipeline_info",
            name:  'assembly_software_'  + 'versions.yml',
            sort: true,
            newLine: true
        ).set { ch_collated_versions }


    emit:
    versions       = ch_versions                 // channel: [ path(versions.yml) ]

}

/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    THE END
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
