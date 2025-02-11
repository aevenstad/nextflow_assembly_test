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

### To-do:
- LREFinder (create local module and container for dependencies)
- PlasmidFinder (nf-core module available)
- Report (create python script for report writing and container for dependencies)


## Usage
First, prepare a samplesheet with your input data that looks as follows:

`samplesheet.csv`:

```csv
sample,fastq_1,fastq_2
CONTROL_REP1,AEG588A1_S1_L002_R1_001.fastq.gz,AEG588A1_S1_L002_R2_001.fastq.gz
```

Each row represents a fastq file (single-end) or a pair of fastq files (paired end).


Now, you can run the pipeline using:

```bash
nextflow run assembly \
   -profile <docker/singularity/.../institute> \
   --input samplesheet.csv \
   --outdir <OUTDIR>
```

## Citations

This pipeline uses code and infrastructure developed and maintained by the [nf-core](https://nf-co.re) community, reused here under the [MIT license](https://github.com/nf-core/tools/blob/main/LICENSE).

> **The nf-core framework for community-curated bioinformatics pipelines.**
>
> Philip Ewels, Alexander Peltzer, Sven Fillinger, Harshil Patel, Johannes Alneberg, Andreas Wilm, Maxime Ulysse Garcia, Paolo Di Tommaso & Sven Nahnsen.
>
> _Nat Biotechnol._ 2020 Feb 13. doi: [10.1038/s41587-020-0439-x](https://dx.doi.org/10.1038/s41587-020-0439-x).
