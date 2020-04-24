cwlVersion: v1.0
class: Workflow


requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement


inputs:

  genome_fasta_file:
    type: File
    doc: |
      Genome file in FASTA format, uncompressed

  annotation_gtf_file:
    type: File
    doc: |
      GTF annotation file

  make_unique:
    type: boolean?
    doc: |
      Replace repeated target names with unique names

  kmer_size:
    type: int?
    doc: |
      k-mer (odd) length (default: 31, max value: 31)
      
  index_output_filename:
    type: string?
    doc: |
      Filename for the kallisto index to be constructed


outputs:

  transcriptome_fasta_file:
    type: File
    outputSource: generate_transcriptome/transcriptome_fasta_file

  kallisto_index:
    type: File
    outputSource: generate_kallisto_index/kallisto_index

  kallisto_stdout_log:
    type: File
    outputSource: generate_kallisto_index/stdout_log

  kallisto_stderr_log:
    type: File
    outputSource: generate_kallisto_index/stderr_log


steps:

  generate_transcriptome:
    run: ../tools/gffread.cwl
    in:
      genome_fasta_file: genome_fasta_file
      annotation_gtf_file: annotation_gtf_file
    out: [transcriptome_fasta_file]

  generate_kallisto_index:
    run: ../tools/kallisto-index.cwl
    in:
      transcriptome_fasta_file: generate_transcriptome/transcriptome_fasta_file
      make_unique: make_unique
      kmer_size: kmer_size
      output_filename: index_output_filename
    out:
    - kallisto_index
    - stdout_log
    - stderr_log

$namespaces:
  s: http://schema.org/

$schemas:
- http://schema.org/docs/schema_org_rdfa.html

s:name: "genome-kallisto-index"
s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows/master/tools/genome-kallisto-index.cwl
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
  Generates a FASTA file with the DNA sequences for all transcripts in a GFF file and builds kallisto index

s:about: |
  Usage: kallisto index [arguments] FASTA-files

  Required argument:
  -i, --index=STRING          Filename for the kallisto index to be constructed 

  Optional argument:
  -k, --kmer-size=INT         k-mer (odd) length (default: 31, max value: 31)
      --make-unique           Replace repeated target names with unique names