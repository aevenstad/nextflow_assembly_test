# bacterial genome assembly

## Introduction
Bioinformatics pipeline to assemble bacterial genomes from raw Illumina data and perform antimicrobial resistance screening.
Set up using `nf-core tools` and the pipeline is currently using a `nf-core` template. 

### Completed steps:
- FastQC (Quality check of raw reads)
- fastp (Adapter and quality trimming)
- shovill (de-novo genome assembly - using spades)
- quast (assembly statistics)
- MLST (Multi locus sequence typing of assemblies)
- rMLST (ribosomal MLST)
- Kleborate (screening of antimocrobial resistence for Klebsiella assemblies only)
- BBMap align (Calculate coverage)
- AMRFinderPlus (screening of antimicrobial resistance)
- LREFinder (create local module and container for dependencies)
- PlasmidFinder (nf-core module available)

### To-do:

- Report (create python script for report writing and container for dependencies)
- Configurate start-up message/info

