// Import generic module functions
include { saveFiles; getSoftwareName } from './functions'

params.options     = [:]
params.results_dir = ''

process SYNAPSE_TO_SAMPLESHEET {
    tag "$meta.id"
    publishDir "${params.outdir}",
        mode: params.publish_dir_mode,
        saveAs: { filename -> saveFiles(filename:filename, options:params.options, publish_dir:getSoftwareName(task.process), meta:meta, publish_by_meta:['id']) }

    memory 100.MB

    input:
    tuple val(meta), path(fastq)
    val pipeline

    output:
    tuple val(meta), path("*.csv"), emit: samplesheet

    exec:

    //  Remove custom keys
    def meta_map = meta.clone()
    meta_map.remove("id")

    def fastq_1 = "${params.outdir}/${params.results_dir}/${fastq}"
    def fastq_2 = ''
    if (fastq instanceof List && fastq.size() == 2) {
        fastq_1 = "${params.outdir}/${params.results_dir}/${fastq[0]}"
        fastq_2 = "${params.outdir}/${params.results_dir}/${fastq[1]}"
    }

    // Add relevant fields to the beginning of the map
    pipeline_map = [
        sample  : "${meta.id}",
        fastq_1 : fastq_1,
        fastq_2 : fastq_2
    ]

    // Add nf-core pipeline specific entries
    if (pipeline) {
        if (pipeline == 'rnaseq') {
            pipeline_map << [ strandedness: 'unstranded' ]
        }
    }
    pipeline_map << meta_map

    // Create a samplesheet
    samplesheet  = pipeline_map.keySet().collect{ '"' + it + '"'}.join(",") + '\n'
    samplesheet += pipeline_map.values().collect{ '"' + it + '"'}.join(",")

    // Write samplesheet to file
    def samplesheet_file = task.workDir.resolve("${meta.id}.samplesheet.csv")
    samplesheet_file.text = samplesheet
}