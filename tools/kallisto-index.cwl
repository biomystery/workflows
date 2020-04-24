cwlVersion: v1.0
class: CommandLineTool


requirements:
  - class: InlineJavascriptRequirement
    expressionLib:
    - var get_output_filename = function() {
            if (inputs.output_filename == ""){
              var ext = ".idx";
              var root = inputs.transcriptome_fasta_file.basename.split('.').slice(0,-1).join('.');
              return (root == "")?inputs.transcriptome_fasta_file.basename+ext:root+ext;
            } else {
              return inputs.output_filename;
            }
          };


hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/kallisto:0.46.2--h4f7b962_1


inputs:

  transcriptome_fasta_file:
    type: File
    inputBinding:
      position: 10
    doc: |
      Transcriptome FASTA file, optionally gzipped

  make_unique:
    type: boolean?
    inputBinding:
      position: 5
      prefix: "--make-unique"
    doc: |
      Replace repeated target names with unique names

  kmer_size:
    type: int?
    inputBinding:
      position: 6
      prefix: "--kmer-size"
    doc: |
      k-mer (odd) length (default: 31, max value: 31)
      
  output_filename:
    type: string?
    inputBinding:
      position: 7
      prefix: "--index"
      valueFrom: $(get_output_filename())
    default: ""
    doc: |
      Filename for the kallisto index to be constructed


outputs:

  kallisto_index:
    type: File
    outputBinding:
      glob: $(get_output_filename())

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: [ "kallisto", "index" ]


stdout: kallisto_index_stdout.log
stderr: kallisto_index_stderr.log