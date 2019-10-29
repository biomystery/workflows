cwlVersion: v1.0
class: CommandLineTool


hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/ucscuserapps:v358


requirements:
- class: InlineJavascriptRequirement
  expressionLib:
  - var default_output_filename = function() {
          if (inputs.output_filename == ""){
            var root = inputs.fasta_file.basename.split('.').slice(0,-1).join('.');
            return (root == "")?inputs.fasta_file.basename+".2bit":root+".2bit";
          } else {
            return inputs.output_filename;
          }
        };


inputs:

  fasta_file:
    type: File
    inputBinding:
      position: 5
    doc: "Reference genome FASTA file"

  output_filename:
    type: string?
    default: ""
    inputBinding:
      valueFrom: $(default_output_filename())
      position: 6
    doc: "Output file name"


outputs:

  twobit_file:
    type: File
    outputBinding:
      glob: $(default_output_filename())
    doc: "Reference genome 2bit file"

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: ["faToTwoBit"]
stdout: fa_to_twobit_stdout.log
stderr: fa_to_twobit_stderr.log