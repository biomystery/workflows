cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement
  expressionLib:
  - var get_output_folder = function() {
          if (inputs.output_folder == ""){
            var root = inputs.target_fasta_file.basename.split('.').slice(0,-1).join('.');
            return (root == "")?inputs.target_fasta_file.basename:root;
          } else {
            return inputs.output_folder;
          }
        };


hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/homer:v0.0.2


inputs:

  target_fasta_file:
    type: File
    doc: |
      Target FASTA file to scan for motifs

  output_folder:
    type: string?
    inputBinding:
      position: 5
      valueFrom: $(get_output_folder())
    default: ""
    doc: |
      Name of the output folder to keep all the results

  background_fasta_file:
    type: File
    inputBinding:
      position: 6
      prefix: "-fasta"
    doc: |
      Background FASTA file suitable for use as a null distribution

  skip_denovo:
    type: boolean?
    inputBinding:
      position: 7
      prefix: "-nomotif"
    doc: |
      Don't search for de novo motif enrichment
      
  use_binomial:
    type: boolean?
    inputBinding:
      position: 8
      prefix: "-b"
    doc: |
      Use binomial distribution to calculate p-values (default is hypergeometric)

  threads:
    type: int?
    inputBinding:
      position: 9
      prefix: "-p"
    doc: |
      Number of threads to use


outputs:

  results_folder:
    type: Directory
    outputBinding:
      glob: $(get_output_folder())
    doc: |
      Folder with all the generated results

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: ["findMotifs.pl"]
arguments:
  - valueFrom: $(inputs.target_fasta_file)
  - "dummy"


stdout: homer_find_motifs_stdout.log
stderr: homer_find_motifs_stderr.log