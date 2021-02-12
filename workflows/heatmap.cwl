cwlVersion: v1.0
class: Workflow


requirements:
  - class: InlineJavascriptRequirement
  - class: SubworkflowFeatureRequirement


inputs:

  bam_file:
    type: File[]
    label: "BAM files"
    format: "http://edamontology.org/format_2572"
    doc: "Array of input BAM files"

  genelist_file:
    type: File
    label: "Genelist file"
    format: "http://edamontology.org/format_3475"
    doc: "Genelist file"

  fragment_size:
    type: int[]
    label: "Fragment sizes"
    doc: "Array of fragment sizes"

  total_reads:
    type: int[]
    label: "Total reads numbers"
    doc: "Array of total reads number for downstream normalization"

  export_heatmap:
    type: boolean?
    default: True
    label: "Export heatmap instead of a histogram"
    doc: "Export heatmap instead of a histogram"

  hist_width:
    type: int?
    default: 20000
    label: "Histogram/Heatmap width, bp"
    doc: "Histogram/Heatmap width, bp"

  hist_bin_size:
    type: int?
    default: 50
    label: "Histogram/Heatmap bin size, bp"
    doc: "Histogram/Heatmap bin size, bp"

  threads:
    type: int?
    default: 1
    label: "Number of threads"
    doc: "Number of threads for those steps that support multithreading"


outputs:

  heatmap_file_raw:
    type: File
    outputSource: make_tss_heatmap/histogram_file

steps:

  make_tag_folders:
    run: ../tools/heatmap-prepare.cwl
    in:
      bam_file: bam_file
      fragment_size: fragment_size
      total_reads: total_reads
    out: [tag_folder]

  center_genelist_on_tss:
    run: ../tools/custom-bash.cwl
    in:
      input_file: genelist_file
      script:
        default: cat "$0" | grep -v "refseq_id" | awk '{tss=$4; if ($6 == "-") tss=$5; print $2"\t"$3"\t"tss"\t"tss"\t"$6}' > `basename $0`
    out: [output_file]

  make_tss_heatmap:
    run: ../tools/homer-annotate-peaks-hist.cwl
    in:
      peak_file: center_genelist_on_tss/output_file
      tag_folders: make_tag_folders/tag_folder
      hist_width: hist_width
      hist_bin_size: hist_bin_size
      export_heatmap: export_heatmap
      threads: threads
      histogram_filename:
        default: "default.tsv"
    out: [histogram_file]


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

s:name: "heatmap"
s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows/master/workflows/heatmap.cwl
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
      - class: s:Person
        s:name: Andrey Kartashov
        s:email: mailto:Andrey.Kartashov@cchmc.org
        s:sameAs:
        - id: http://orcid.org/0000-0001-9102-5681

doc: |
  Generates ATDP heatmap centered on TSS from an array of input BAM files and genelist TSV file.
  Returns array of heatmap JSON files with the names that have the same basenames as input BAM files,
  but with .json extension

s:about: |
  Generates ATDP heatmap centered on TSS from an array of input BAM files and genelist TSV file.
  Returns array of heatmap JSON files with the names that have the same basenames as input BAM files,
  but with .json extension