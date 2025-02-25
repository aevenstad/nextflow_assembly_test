/*
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
    IMPORT MODULES / SUBWORKFLOWS / FUNCTIONS
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
*/
include { AMRFINDERPLUS_RUN      } from '../modules/nf-core/amrfinderplus/run/main'
include { BBMAP_ALIGN            } from '../modules/nf-core/bbmap/align/main'
include { FASTP                  } from '../modules/nf-core/fastp/main'
include { FASTQC                 } from '../modules/nf-core/fastqc/main'
include { KLEBORATE              } from '../modules/nf-core/kleborate/main'
include { LRE_FINDER             } from '../modules/local/lre-finder/main'
include { MLST                   } from '../modules/nf-core/mlst/main'
include { PLASMIDFINDER          } from '../modules/nf-core/plasmidfinder/main'
include { QUAST                  } from '../modules/nf-core/quast/main'
include { RMLST                  } from '../modules/local/rmlst/main'
include { SHOVILL                } from '../modules/nf-core/shovill/main'
include { SKESA                  } from '../modules/local/skesa/main'


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
    // MODULE: Run Assembly (Shovill or SKESA)
    //
    def ch_assembly

    if (params.assembler == 'shovill') {
        ch_assembly = SHOVILL(ch_trimmed).contigs
    } else if (params.assembler == 'skesa') {
        ch_assembly = SKESA(ch_trimmed).contigs
    } else {
        exit 1, "Unsupported assembler: ${params.assembler}"
    }

    //
    // MODULE: Run Quast (Assembly Evaluation)
    //
    QUAST (
        ch_assembly
    )
    ch_quast = QUAST.out.results // Outputs Quast report
    ch_versions = ch_versions.mix(QUAST.out.versions.first())

    //
    // MODULE: Run BBMap aligner (calculate coverage)
    //
    BBMAP_ALIGN (
        ch_trimmed,
        ch_assembly
    )
    ch_bbmap = BBMAP_ALIGN.out // Outputs BBMap results
    ch_versions = ch_versions.mix(BBMAP_ALIGN.out.versions.first())

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
    ch_rmlst = RMLST.out.species // Outputs rMLST results

    //
    // MODULE KLEBORATE (Run Kleborate for Klebsiella)
    // Only run Kleborate fot Klebsiella assemblies identified through rMLST
    //
    KLEBORATE (
        ch_rmlst,
        ch_assembly
    )
    ch_kleborate = KLEBORATE.out.txt // Outputs Kleborate results
    ch_versions = ch_versions.mix(KLEBORATE.out.versions.first())

    //
    // MODULE AMRFINDERPLUS (Run AMRFinderPlus)
    //
    AMRFINDERPLUS_RUN (
        ch_assembly,
        ch_rmlst
    )
    ch_amrfinderplus = AMRFINDERPLUS_RUN.out // Outputs AMRFinderPlus results
    ch_versions = ch_versions.mix(AMRFINDERPLUS_RUN.out.versions.first())


    //
    // MODULE PLASMIDFINDER (Run PlasmidFinder)
    //
    PLASMIDFINDER (
        ch_assembly
    )
    ch_plasmidfinder = PLASMIDFINDER.out.txt // Outputs PlasmidFinder results
    ch_versions = ch_versions.mix(PLASMIDFINDER.out.versions.first())

    //
    // MODULE LRE-FINDER (Run LRE-Finder)
    //
    LRE_FINDER (
        ch_rmlst,
        ch_trimmed
    )
    ch_lre_finder = LRE_FINDER.out.txt // Outputs LRE-Finder results

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
