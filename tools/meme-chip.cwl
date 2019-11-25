cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement
  expressionLib:
  - var get_output_folder_name = function() {
          return (inputs.output_folder_name == "")?"memechip_out":inputs.output_folder_name;
        };


hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/memesuite:v0.0.1


inputs:

  fasta_file:
    type: File
    inputBinding:
      position: 100
    doc: "Input FASTA file"

  motif_file:
    type:
    - type: array
      items: File
      inputBinding:
        prefix: "--db"
    inputBinding:
      position: 1
    doc: "MEME Motif Format file(s) for use by Tomtom and CentriMo. Repeat prefix for every item in array"

  motif_count:
    type: int?
    inputBinding:
      position: 2
      prefix: "-meme-nmotifs"
    doc: "Number of motifs that MEME should search for"

  motif_searchsize:
    type: int?
    inputBinding:
      position: 3
      prefix: "-meme-searchsize"
    doc: "The maximum portion of the primary sequences (in characters) used by MEME in searching for motif"

  skip_spamo:
    type: boolean?
    inputBinding:
      position: 4
      prefix: "-spamo-skip"
    doc: "Do not run SpaMo"

  skip_fimo:
    type: boolean?
    inputBinding:
      position: 5
      prefix: "-fimo-skip"
    doc: "Do not run SpaFIMOMo"

  output_folder_name:
    type: string?
    inputBinding:
      position: 6
      prefix: "-o"
      valueFrom: $(get_output_folder_name())
    default: ""
    doc: "Name of the output folder to keep all the results"

  threads:
    type: int?
    inputBinding:
      position: 7
      prefix: "-meme-p"
    doc: "Number of threads to run MEME"


outputs:

  results_folder:
    type: Directory
    outputBinding:
      glob: $(get_output_folder_name())
    doc: "Folder with all the generated results"

  html_report_file:
    type: File
    outputBinding:
      glob: "*/meme-chip.html"
    doc: "HTML file that provides the results in an interactive, human-readable format"

  summary_file:
    type: File
    outputBinding:
      glob: "*/summary.tsv"
    doc: "TSV file that provides a summary of the results in a format suitable for parsing by scripts and viewing with Excel"

  identified_motifs_file:
    type: File?
    outputBinding:
      glob: "*/combined.meme"
    doc: "Text file that contains all the motifs identified by MEME-ChIP in MEME Motif Format"

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: ["meme-chip"]
stdout: meme_chip_stdout.log
stderr: meme_chip_stderr.log


$namespaces:
  s: http://schema.org/

$schemas:
- http://schema.org/version/latest/schema.rdf

s:mainEntity: https://bio.tools/meme_suite

s:name: "meme-chip"
s:license: http://www.apache.org/licenses/LICENSE-2.0

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
  s:department:
  - class: s:Organization
    s:legalName: "Allergy and Immunology"
    s:department:
    - class: s:Organization
      s:legalName: "Barski Research Lab"
      s:member:
      - class: s:Person
        s:name: Michael Kotliar
        s:email: mailto:michael.kotliar@cchmc.org
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898


doc: |
  Runs "meme-chip" tool from MEME Suite. Input `motif_file` should be provided as array even for a single file.