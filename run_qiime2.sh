#!/usr/bin/env bash

# 16S Sequencing Analysis Pipeline using QIIME2
# This script processes 16S rRNA sequencing data from raw FASTQ files to taxonomic profiles and diversity analyses.
# Assumes FastQ files in ${PWD}/fastq, metadata file in ${PWD}/metadata.tsv, and
# SILVA classifier in ${PWD}/silva-138-99-nb-classifier.qza.

BOLDBLUE='\033[1;34m'
NC='\033[0m'

# # Step 1: Create necessary directory structure for the analysis
# echo -e "${BOLDBLUE}Step 1: Creating directory structure for QIIME2 analysis...${NC}"
# docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
#     "mkdir -p /workspace/artfacts/qc /workspace/artfacts/composition /workspace/visualizations/qc /workspace/visualizations/composition"

# # Step 2: Import demultiplexed sequences into QIIME2 artifact
# echo -e "${BOLDBLUE}Step 2: Importing demultiplexed sequences into QIIME2 artifact...${NC}"
# docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
#     "qiime tools import --type SampleData[SequencesWithQuality] --input-path /workspace/fastq --output-path /workspace/artfacts/demultiplexed-sequences.qza --input-format CasavaOneEightSingleLanePerSampleDirFmt"

# # Step 3: Perform quality control on FASTQ files using FastQC
# echo -e "${BOLDBLUE}Step 3: Performing quality control on FASTQ files using FastQC...${NC}"
# docker run -v /${PWD}/:/workspace biomehub/fastqc:0.11.8 bash -c \
#     ' fastqc /workspace/fastq/* -o /workspace/fastq -t 2'

# # Step 4: Aggregate FastQC reports into a single MultiQC report
# echo -e "${BOLDBLUE}Step 4: Aggregating FastQC reports into a single MultiQC report...${NC}"
# docker run -v /${PWD}/:/workspace staphb/multiqc:1.19 bash -c \
#     "multiqc --filename /workspace/artfacts/qc/multiqc_report /workspace/fastq"

# Step 5: Generate summary visualization of demultiplexed sequences
echo -e "${BOLDBLUE}Step 5: Generating summary visualization of demultiplexed sequences...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime demux summarize --i-data /workspace/artfacts/demultiplexed-sequences.qza --o-visualization /workspace/visualizations/qc/single-end-demux.qzv"

# Step 6: Denoise sequences using DADA2 algorithm to generate ASVs
echo -e "${BOLDBLUE}Step 6: Denoising sequences using DADA2 algorithm to generate ASVs...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime dada2 denoise-single --o-table /workspace/artfacts/composition/representative-table.qza --p-n-threads 2 --p-trim-left 30 --p-trunc-len 250 --o-denoising-stats /workspace/artfacts/qc/denoising-stats.qza --i-demultiplexed-seqs /workspace/artfacts/demultiplexed-sequences.qza --o-representative-sequences /workspace/artfacts/composition/representative-sequences.qza"

# Step 7: Create visualization of denoising statistics
echo -e "${BOLDBLUE}Step 7: Creating visualization of denoising statistics...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime metadata tabulate --m-input-file /workspace/artfacts/qc/denoising-stats.qza --o-visualization /workspace/visualizations/qc/denoising-stats.qzv"

# Step 8: Export denoising statistics to TSV format
echo -e "${BOLDBLUE}Step 8: Exporting denoising statistics to TSV format...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime tools export --input-path /workspace/artfacts/qc/denoising-stats.qza --output-path /workspace/visualizations/qc/denoising-summary"

# Step 9: Generate summary visualization of the feature table
echo -e "${BOLDBLUE}Step 9: Generating summary visualization of the feature table...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime feature-table summarize --i-table /workspace/artfacts/composition/representative-table.qza --o-visualization /workspace/visualizations/composition/representative-table.qzv --m-sample-metadata-file /workspace/metadata.tsv"

# Step 10: Create visualization of representative sequences
echo -e "${BOLDBLUE}Step 10: Creating visualization of representative sequences...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime feature-table tabulate-seqs --i-data /workspace/artfacts/composition/representative-sequences.qza --o-visualization /workspace/visualizations/composition/representative-sequences.qzv"

# Step 11: Construct phylogenetic tree from representative sequences
echo -e "${BOLDBLUE}Step 11: Constructing phylogenetic tree from representative sequences...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime phylogeny align-to-tree-mafft-fasttree --o-tree /workspace/artfacts/composition/unrooted-tree.qza --i-sequences /workspace/artfacts/composition/representative-sequences.qza --o-alignment /workspace/artfacts/composition/aligned-representative-sequences.qza --o-rooted-tree /workspace/artfacts/composition/rooted-tree.qza --o-masked-alignment /workspace/artfacts/composition/masked-aligned-representative-sequences.qza"

# Step 12: Classify sequences taxonomically using SILVA classifier
echo -e "${BOLDBLUE}Step 12: Classifying sequences taxonomically using SILVA classifier...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime feature-classifier classify-sklearn --i-reads /workspace/artfacts/composition/representative-sequences.qza --i-classifier /workspace/silva-138-99-nb-classifier.qza --o-classification /workspace/artfacts/composition/representative-sequences-taxonomy.qza"

# Step 13: Create visualization of taxonomic classifications
echo -e "${BOLDBLUE}Step 13: Creating visualization of taxonomic classifications...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime metadata tabulate --m-input-file /workspace/artfacts/composition/representative-sequences-taxonomy.qza --o-visualization /workspace/visualizations/composition/representative-sequences-taxonomy.qzv"

# Step 14: Perform alpha rarefaction analysis
echo -e "${BOLDBLUE}Step 14: Performing alpha rarefaction analysis...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime diversity alpha-rarefaction --i-table /workspace/artfacts/composition/representative-table.qza --i-phylogeny /workspace/artfacts/composition/rooted-tree.qza --p-max-depth 5000 --m-metadata-file /workspace/metadata.tsv --o-visualization /workspace/artfacts/composition/alpha-rarefaction.qzv"

# Step 15: Collapse feature table to species level
echo -e "${BOLDBLUE}Step 15: Collapsing feature table to species level...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime taxa collapse --i-table /workspace/artfacts/composition/representative-table.qza --p-level 7 --i-taxonomy /workspace/artfacts/composition/representative-sequences-taxonomy.qza --o-collapsed-table /workspace/artfacts/composition/species-count-table.qza"

# Step 16: Collapse feature table to genus level
echo -e "${BOLDBLUE}Step 16: Collapsing feature table to genus level...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime taxa collapse --i-table /workspace/artfacts/composition/representative-table.qza --p-level 6 --i-taxonomy /workspace/artfacts/composition/representative-sequences-taxonomy.qza --o-collapsed-table /workspace/artfacts/composition/genus-count-table.qza"

# Step 17: Collapse feature table to family level
echo -e "${BOLDBLUE}Step 17: Collapsing feature table to family level...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime taxa collapse --i-table /workspace/artfacts/composition/representative-table.qza --p-level 5 --i-taxonomy /workspace/artfacts/composition/representative-sequences-taxonomy.qza --o-collapsed-table /workspace/artfacts/composition/family-count-table.qza"

# Step 18: Collapse feature table to phylum level
echo -e "${BOLDBLUE}Step 18: Collapsing feature table to phylum level...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime taxa collapse --i-table /workspace/artfacts/composition/representative-table.qza --p-level 2 --i-taxonomy /workspace/artfacts/composition/representative-sequences-taxonomy.qza --o-collapsed-table /workspace/artfacts/composition/phylum-count-table.qza"

# Step 19: Generate taxonomic barplot visualization
echo -e "${BOLDBLUE}Step 19: Generating taxonomic barplot visualization...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime taxa barplot --i-table /workspace/artfacts/composition/representative-table.qza --i-taxonomy /workspace/artfacts/composition/representative-sequences-taxonomy.qza --m-metadata-file /workspace/metadata.tsv --o-visualization /workspace/visualizations/composition/taxonomy-profile.qzv"

# Step 20: Export representative sequences to FASTA format
echo -e "${BOLDBLUE}Step 20: Exporting representative sequences to FASTA format...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime tools export --input-path /workspace/artfacts/composition/representative-sequences.qza --output-path /workspace/visualizations/composition/representative-sequences.fasta --output-format DNAFASTAFormat"

# Step 21: Export feature table to BIOM format
echo -e "${BOLDBLUE}Step 21: Exporting feature table to BIOM format...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime tools export --input-path /workspace/artfacts/composition/representative-table.qza --output-path /workspace/visualizations/composition/representative-table.biom --output-format BIOMV210Format"

# Step 22: Export rooted phylogenetic tree
echo -e "${BOLDBLUE}Step 22: Exporting rooted phylogenetic tree...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime tools export --input-path /workspace/artfacts/composition/rooted-tree.qza --output-path /workspace/artfacts/"

# Step 23: Export taxonomic classifications
echo -e "${BOLDBLUE}Step 23: Exporting taxonomic classifications...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "qiime tools export --input-path /workspace/artfacts/composition/representative-sequences-taxonomy.qza --output-path /workspace/artfacts/"

# Step 24: Convert BIOM table to TSV format
echo -e "${BOLDBLUE}Step 24: Converting BIOM table to TSV format...${NC}"
docker run -v /${PWD}/:/workspace quay.io/qiime2/core:2023.5 bash -c \
    "biom convert -i /workspace/visualizations/composition/representative-table.biom -o /workspace/visualizations/composition/representative-table.tsv --to-tsv"