cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement
  expressionLib:
  - var default_output_filename = function() {
          if (inputs.output_filename == ""){
            return inputs.file_a.basename;
          } else {
            return inputs.output_filename;
          }
        };


hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/bedtools2:v2.26.0


inputs:

  file_a:
    type: File
    inputBinding:
      position: 5
      prefix: "-a"
    doc: "BED/GFF/VCF file A. Each feature in A is compared to B in search of overlaps"

  file_b:
    type: File
    inputBinding:
      position: 6
      prefix: "-b"
    doc: "BED/GFF/VCF file B"

  detailed_report:
    type: boolean?
    inputBinding:
      position: 7
      prefix: "-detail"
    doc: "Instead of a summary, report the relative distance for each interval in A" 

  output_filename:
    type: string?
    default: ""
    doc: "Output file name"


outputs:

  relative_distance_distribution:
    type: File
    outputBinding:
      glob: $(default_output_filename())
    doc: "The distribution of relative distances between two sets of intervals"


baseCommand: ["bedtools", "reldist"]
stdout: $(default_output_filename())
