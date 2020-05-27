cwlVersion: v1.0
class: Workflow


requirements:
  - class: InlineJavascriptRequirement


inputs:

  bigwig_files:
    type: File[]

  chrom_length_file:
    type: File

  output_filename:
    type: string


outputs:

  average_signal_bigwig:
    type: File
    outputSource: convert_to_bigwig/average_signal_bigwig


steps:

  get_average_signal:
    run:
      cwlVersion: v1.0
      class: CommandLineTool
      hints:
      - class: DockerRequirement
        dockerPull: quay.io/biocontainers/wiggletools:1.2.2--hbf82112_4
      inputs:
        bigwig_files:
          type: File[]
          inputBinding:
            position: 1
      outputs:
        average_signal_wig:
          type: stdout
      baseCommand: ["wiggletools", "mean"]
      stdout: average_signal.wig
    in:
      bigwig_files: bigwig_files
    out:
      - average_signal_wig

  convert_to_bigwig:
    run:
      cwlVersion: v1.0
      class: CommandLineTool
      hints:
      - class: DockerRequirement
        dockerPull: biowardrobe2/ucscuserapps:v358_2
      inputs:
        average_signal_wig:
          type: File
          inputBinding:
            position: 1
        chrom_length_file:
          type: File
          inputBinding:
            position: 2
        output_filename:
          type: string
          inputBinding:
            position: 3
      outputs:
        average_signal_bigwig:
          type: File
          outputBinding:
            glob: "*"
      baseCommand: ["wigToBigWig"]
    in:
      average_signal_wig: get_average_signal/average_signal_wig
      chrom_length_file: chrom_length_file
      output_filename: output_filename
    out:
      - average_signal_bigwig