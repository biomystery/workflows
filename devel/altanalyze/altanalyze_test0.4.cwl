cwlVersion: v1.0
class: CommandLineTool

requirements: []

hints:
  - class: DockerRequirement
    dockerPull: haysb1991/altanalyze-test:version6

inputs:
  move_script:
    type: string?
    default: |
      #!/bin/bash
      echo "$@"
      set -- "$0" "$@"
      echo "$1"
      cp -r "$0" /opt/altanalyze/AltDatabase
      python /opt/altanalyze/AltAnalyze.py --species "$2" --platform RNASeq --runICGS yes --excludeCellCycle "$3" --removeOutliers "$4" --restrictBy "$5" --downsample "$6" --markerPearsonCutoff "$7" --ChromiumSparseMatrix /opt/altanalyze/DemoData/ICGS/10xGenomics/Mm-e14.5_Kidney-GSE104396/mm10/matrix.mtx --output /opt/altanalyze/DemoData/ICGS/10xGenomics/Mm-e14.5_Kidney-GSE104396/mm10 --expname "$8"
      ls /opt/altanalyze/DemoData/ICGS/10xGenomics/Mm-e14.5_Kidney-GSE104396/mm10/ICGS-NMF
      cp -r /opt/altanalyze/DemoData/ICGS/10xGenomics/Mm-e14.5_Kidney-GSE104396/mm10/ICGS-NMF .

    inputBinding:
      position: 1
    doc: |
      Bash function to redirect to complete the return of EnsMart72 as output.

  data_in:
    type: Directory
    inputBinding:
      position: 2

  species:
    type: string
    default: "Mm"
    inputBinding:
      position: 3

  excludeCellCycle:
    type: string
    default: "no"
    inputBinding:
      position: 4

  removeOutliers:
    type: string
    default: "yes"
    inputBinding:
      position: 5

  restrictBy:
    type: string
    default: "None"
    inputBinding:
      position: 6

  downsample:
    type: string
    default: "5000"
    inputBinding:
      position: 7

  markerPearsonCutoff:
    type: string
    default: "0.3"
    inputBinding:
      position: 8

  expname:
    type: string
    default: "kidney"
    inputBinding:
      position: 9

outputs:
  stdout_log:
    type: stdout

  stderr_log:
    type: stderr

  ICGSMNF:
    type: Directory
    outputBinding: 
      glob: "ICGS-NMF"

baseCommand: [bash, '-c']

stdout: aatest_stdout.log
stderr: aatest_stderr.log

$namespaces:
  s: http://schema.org/

s:isPartOf:
  class: s:CreativeWork
  s:name: Common Workflow Language
  s:url: http://commonwl.org/

s:creator:
- class: s:Organization
  s:legalName: "Cincinnati Children's Hospital Medical Center"
  s:location:
  - class: s:PostalAddress
    s:addressCountry: "USA"
    s:addressLocality: "Cincinnati"
    s:addressRegion: "OH"
    s:postalCode: "45229"
    s:streetAddress: "3333 Burnet Ave"
    s:telephone: "+1(513)636-4200"
  s:logo: "https://www.cincinnatichildrens.org/-/media/cincinnati%20childrens/global%20shared/childrens-logo-new.png"

doc: |
  altanalyze is being used in a single cell pipeline