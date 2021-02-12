cwlVersion: v1.0
class: CommandLineTool


hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/kallisto:0.46.2--h4f7b962_1

    
inputs:

  kallisto_index:
    type: File
    inputBinding:
      position: 1
      prefix: --index

  fastq1:
    type: File
    inputBinding:
      position: 8

  fastq2:
    type: File?
    inputBinding:
      position: 9

  single:
    type: boolean?
    inputBinding:
      prefix: --single
      position: 6
      
  threads:
    type: int?
    inputBinding:
      prefix: --threads
      position: 7
      

outputs:

  expression_transcript_table:
    type: File
    outputBinding:
      glob: "kallisto/abundance.tsv"

  expression_transcript_h5:
    type: File
    outputBinding:
      glob: "kallisto/abundance.h5"

  fusions:
    type: File
    outputBinding:
      glob: "kallisto/fusion.txt"

  bam_file:
    type: File
    outputBinding:
      glob: "kallisto/pseudoalignments.bam"

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: [ "kallisto", "quant" ]


arguments:
  - valueFrom: "kallisto"
    position: 2
    prefix: "--output-dir"
  - valueFrom: "100"
    position: 3
    prefix: "--bootstrap-samples"
  - valueFrom: "--fusion"
    position: 4
  - valueFrom: "--pseudobam"
    position: 5


stdout: kallisto_quant_stdout.log
stderr: kallisto_quant_stderr.log