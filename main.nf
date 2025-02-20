#!/usr/bin/env nextflow

nextflow.enable.dsl=2

params.input = "data/"
params.outdir = "results/"

process IMPORT_DATA {
    input:
    path raw_reads

    output:
    path "demux.qza"

    script:
    """
    qiime tools import \
      --type 'SampleData[PairedEndSequencesWithQuality]' \
      --input-path $raw_reads \
      --input-format CasavaOneEightSingleLanePerSampleDirFmt \
      --output-path demux.qza
    """
}

process DEMUX_SUMMARY {
    input:
    path demux

    output:
    path "demux.qzv"

    script:
    """
    qiime demux summarize \
      --i-data demux.qza \
      --o-visualization demux.qzv
    """
}

process DADA2 {
    input:
    path demux

    output:
    path "table-dada2.qza"
    path "rep-seqs.qza"

    script:
    """
    qiime dada2 denoise-paired \
      --i-demultiplexed-seqs demux.qza \
      --p-trunc-len-f 250 \
      --p-trunc-len-r 250 \
      --o-table table-dada2.qza \
      --o-representative-sequences rep-seqs.qza \
      --o-denoising-stats denoising-stats.qza
    """
}

process ASSIGN_TAXONOMY {
    input:
    path rep_seqs

    output:
    path "taxonomy.qza"

    script:
    """
    qiime feature-classifier classify-sklearn \
      --i-classifier classifier.qza \
      --i-reads rep-seqs.qza \
      --o-classification taxonomy.qza
    """
}

workflow {
    Channel.fromPath(params.input).set { raw_reads }

    raw_reads | IMPORT_DATA | DEMUX_SUMMARY | DADA2 | ASSIGN_TAXONOMY
}
