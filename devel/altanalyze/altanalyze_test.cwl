cwlVersion: v1.0
class: CommandLineTool

requirements: []

hints: []

inputs:
  move_script:
    type: string?
    default: |
      #!/bin/bash
      cp -r EnsMart72 /opt/altanalyze/AltDatabase
      python /opt/altanalyze/AltAnalyze.py --species Mm --platform RNASeq --runICGS yes --ChromiumSparseMatrix /opt/altanalyze/DemoData/ICGS/10xGenomics/Mm-e14.5_Kidney-GSE104396/mm10/matrix.mtx --output /opt/altanalyze/DemoData/ICGS/10xGenomics/Mm-e14.5_Kidney-GSE104396/mm10 --expname kidney

    inputBinding:
      position: 5
    doc: |
      Bash function to redirect to complete the return of EnsMart72 as output.

  data_in:
    type: Directory

outputs:
  stdout_log:
    type: stdout

  stderr_log:
    type: stderr

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