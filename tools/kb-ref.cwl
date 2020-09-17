cwlVersion: v1.0
class: CommandLineTool


requirements:
  - class: InlineJavascriptRequirement
    expressionLib:
    - var get_output_prefix = function(ext) {
            if (inputs.output_prefix == ""){
              var root = inputs.genome_fasta_file.basename.split('.').slice(0,-1).join('.');
              return (root == "")?inputs.genome_fasta_file.basename+ext:root+ext;
            } else {
              return inputs.output_prefix + ext;
            }
          };


hints:
  - class: DockerRequirement
    dockerPull: biowardrobe2/kb-python:v0.0.1


inputs:

  genome_fasta_file:
    type: File
    inputBinding:
      position: 100
    doc: "Genome FASTA file"

  annotation_gtf_file:
    type: File
    inputBinding:
      position: 101
    doc: "GTF annotation file"
      
  output_prefix:
    type: string?
    default: ""
    doc: "Output prefix for generated files"


outputs:

  kallisto_index_file:
    type: File
    outputBinding:
      glob: $(get_output_prefix(".idx"))
  
  transcriptome_fasta_file:
    type: File
    outputBinding:
      glob: $(get_output_prefix(".fasta"))

  transcript_to_gene_mapping_file:
    type: File
    outputBinding:
      glob: $(get_output_prefix(".tsv"))

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: ["kb", "ref", "--verbose"]


arguments:
- valueFrom: $(get_output_prefix(".idx"))
  position: 5
  prefix: -i
- valueFrom: $(get_output_prefix(".tsv"))
  position: 6
  prefix: -g
- valueFrom: $(get_output_prefix(".fasta"))
  position: 7
  prefix: -f1                                  # required parameter because we don't use -d (checked in the code of v0.24.4)


stdout: kb_ref_stdout.log
stderr: kb_ref_stderr.log


$namespaces:
  s: http://schema.org/

$schemas:
- http://schema.org/docs/schema_org_rdfa.html

s:name: "kb-ref"
s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows/master/tools/kb-ref.cwl
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
  Builds a kallisto index and transcript-to-gene mapping

  Notes:
  --verbose was hardcoded
  --lamanno argument was skipped, so we don't need -f2, -c1, -c2
  --keep-tmp, -d, --overwrite doesn't make sense when running from container
  
  `annotation_gtf_file` input should have correct "gene_id" field.
  
  Use
  `docker run --rm -ti -v `pwd`:/tmp/ biowardrobe2/ucscuserapps:v358 /bin/bash -c "cut -f 2- refGene.txt | genePredToGtf file stdin refgene.gtf"`
  to generate a proper gtf file from `refGene.txt` downloaded from http://hgdownload.cse.ucsc.edu/goldenPath/${GEN}/database/refGene.txt.gz

s:about: |
  usage: kb ref [-h] [--keep-tmp] [--verbose] -i INDEX -g T2G -f1 FASTA [-f2 FASTA] [-c1 T2C] [-c2 T2C] [-d {human,mouse,linnarsson}] [--lamanno] [--overwrite] fasta gtf

  Build a kallisto index and transcript-to-gene mapping

  positional arguments:
    fasta                 Genomic FASTA file
    gtf                   Reference GTF file

  optional arguments:
    -h, --help            Show this help message and exit
    --keep-tmp            Do not delete the tmp directory
    --verbose             Print debugging information
    -d {human,mouse,linnarsson}
                          Download a pre-built kallisto index (along with all necessary files) instead of building it locally
    --lamanno             Prepare files for RNA velocity based on La Manno et al. 2018 logic
    --overwrite           Overwrite existing kallisto index

  required arguments:
    -i INDEX              Path to the kallisto index to be constructed
    -g T2G                Path to transcript-to-gene mapping to be generated
    -f1 FASTA             [Optional with -d] Path to the cDNA FASTA to be generated

  required arguments for --lamanno:
    -f2 FASTA             Path to the intron FASTA to be generated
    -c1 T2C               Path to generate cDNA transcripts-to-capture
    -c2 T2C               Path to generate intron transcripts-to-capture