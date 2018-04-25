## Introduction

Analysis of renseq enriched data from bulk susceptible and susceptible parent for SNP analysis. The pipeline also checks for common SNPs between bulk susceptible and susceptible parent.

## Requirements

1) ruby rake
2) FASTQC
3) Trimmomatic
4) Bowtie
5) samtools
6) bcftools

## usage:

1) rake -f renseq_snpcall_pipeline.rb reference=PacBio_assembly_RenSeq_RParent_Wu-0_c1.contigs.fasta sample=bulksus samtools:bulksus
2) rake -f renseq_snpcall_pipeline.rb  R1=DM10_Susparent/A5_TKD180301086-AK793_HCGHWBCX2_L2_1.fq.gz R2=DM10_Susparent/A5_TKD180301086-AK793_HCGHWBCX2_L2_2.fq.gz reference=PacBio_assembly_RenSeq_RParent_Wu-0_c1.contigs.fasta sample=susparent bowtie:run samtools:susparent

