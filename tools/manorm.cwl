cwlVersion: v1.0
class: CommandLineTool


hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/manorm:v0.0.1


inputs:

  peak_file_first:
    type: File
    inputBinding:
      position: 5

  peak_file_second:
    type: File
    inputBinding:
      position: 6

  bam_file_first:
    type: File
    inputBinding:
      position: 7

  bam_file_second:
    type: File
    inputBinding:
      position: 9

  fragment_size_first:
    type: int
    inputBinding:
      position: 10

  fragment_size_second:
    type: int
    inputBinding:
      position: 11


outputs:

  common_peak_file:
    type: File
    outputBinding:
      glob: "MAnorm_result_commonPeak_merged.xls"


baseCommand: ["run_manorm.sh"]