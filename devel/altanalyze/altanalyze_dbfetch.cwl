cwlVersion: v1.0
class: CommandLineTool

requirements: []

hints:
  - class: DockerRequirement
    dockerPull: haysb1991/altanalyze-test:version7

inputs: 
  bash_script:
    type: string?
    default: |
      #!/bin/bash
      echo "$@"
      echo "$0"
      echo "$2"
      python /opt/altanalyze/AltAnalyze.py --species "$0" --update Official --version "$1"
      ls /opt/altanalyze/AltDatabase/EnsMart72
      cp -r /opt/altanalyze/AltDatabase/EnsMart72 .

    inputBinding:
      position: 5
    doc: |
      Bash function to redirect to complete the return of EnsMart72 as output.

  species:
    type:
      type: enum
      name: "species"
      symbols: ["Mm", "Hs", "Rn", "Dr"]
      inputBinding:
        position: 6

  db_name:
    type: string
    default: "EnsMart72"
    inputBinding:
      position: 7

outputs:
  stdout_log:
    type: stdout

  stderr_log:
    type: stderr

  database:
    type: Directory
    outputBinding:
      glob: "EnsMart72"

baseCommand: [bash, '-c']

stdout: aadbfetch_stdout.log
stderr: aadbfetch_stderr.log

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