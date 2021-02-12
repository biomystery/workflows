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


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

s:name: "kallisto-index"
s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows/master/tools/kallisto-index.cwl
s:codeRepository: https://github.com/Barski-lab/workflows
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
        s:email: mailto:misha.kotliar@gmail.com
        s:sameAs:
        - id: http://orcid.org/0000-0002-6486-3898

doc: |
  kallisto index builds an index from a FASTA formatted file of target sequences

s:about: |
  Usage: kallisto index [arguments] FASTA-files

  Required argument:
  -i, --index=STRING          Filename for the kallisto index to be constructed 

  Optional argument:
  -k, --kmer-size=INT         k-mer (odd) length (default: 31, max value: 31)
      --make-unique           Replace repeated target names with unique names