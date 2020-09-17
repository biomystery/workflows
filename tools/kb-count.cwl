cwlVersion: v1.0
class: CommandLineTool


hints:
  - class: DockerRequirement
    dockerPull: biowardrobe2/kb-python:v0.0.1


inputs:

  fastq_file_1:
    type: File
    inputBinding:
      position: 100
    doc: "Fastq file 1"

  fastq_file_2:
    type: File
    inputBinding:
      position: 101
    doc: "Fastq file 2"
  
  fastq_file_3:
    type: File?
    inputBinding:
      position: 102
    doc: "Fastq file 3"
    
  kallisto_index_file:
    type: File
    inputBinding:
      position: 5
      prefix: "-i"
    doc: "Kallisto index file"

  transcript_to_gene_mapping_file:
    type: File
    inputBinding:
      position: 6
      prefix: "-g"
    doc: "Transcript-to-gene mapping file"

  sc_technology:
    type:
    - type: enum
      name: "sc_technology"
      symbols:
      - 10XV1       # 3 input files
      - 10XV2       # 2 input files 
      - 10XV3       # 2 input files 
      - CELSEQ      # 2 input files
      - CELSEQ2     # 2 input files
      - DROPSEQ     # 2 input files
      - INDROPSV1   # 2 input files
      - INDROPSV2   # 2 input files
      - INDROPSV3   # 3 input files
      - SCRUBSEQ    # 2 input files
      - SURECELL    # 2 input files
    inputBinding:
      position: 7
      prefix: "-x"
    doc: "Single-cell technology used"

  loom:
    type: boolean?
    inputBinding:
      position: 8
      prefix: "--loom"
    doc: "Generate loom file from count matrix"

  h5ad:
    type: boolean?
    inputBinding:
      position: 9
      prefix: "--h5ad"
    doc: "Generate h5ad file from count matrix"


outputs:

  all_files:
    type: File[]
    outputBinding:
      glob: "*"


baseCommand: ["kb", "count", "--verbose"]


doc: |
  Uses kallisto to pseudoalign reads and bustools to quantify the data.

  Notes:
  --verbose was hardcoded
  --lamanno and --nucleus arguments were skipped, so we don't need -c1, -c2
  --keep-tmp, --overwrite doesn't make sense when running from container