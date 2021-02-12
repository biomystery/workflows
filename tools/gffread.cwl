cwlVersion: v1.0
class: CommandLineTool


requirements:
  - class: InlineJavascriptRequirement
    expressionLib:
    - var get_output_filename = function() {
            if (inputs.output_filename == ""){
              var ext = ".fa";
              var root = inputs.genome_fasta_file.basename.split('.').slice(0,-1).join('.');
              return (root == "")?inputs.genome_fasta_file.basename+ext:root+ext;
            } else {
              return inputs.output_filename;
            }
          };


hints:
  - class: DockerRequirement
    dockerPull: quay.io/biocontainers/gffread:0.11.7--h8b12597_0


inputs:

  genome_fasta_file:
    type: File
    secondaryFiles:
      - .fai
    inputBinding:
      position: 5
      prefix: "-g"
    doc: |
      Genome file in FASTA format, uncompressed

  annotation_gtf_file:
    type: File
    inputBinding:
      position: 10
    doc: |
      GTF annotation file

  output_filename:
    type: string?
    inputBinding:
      position: 6
      prefix: "-w"
      valueFrom: $(get_output_filename())
    default: ""
    doc: |
      Filename for generated transcriptome FASTA file


outputs:

  transcriptome_fasta_file:
    type: File
    outputBinding:
      glob: $(get_output_filename())

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: [ "gffread"]


stdout: gffread_stdout.log
stderr: gffread_stderr.log


$namespaces:
  s: http://schema.org/

$schemas:
- https://github.com/schemaorg/schemaorg/raw/main/data/releases/11.01/schemaorg-current-http.rdf

s:name: "gffread"
s:downloadUrl: https://raw.githubusercontent.com/Barski-lab/workflows/master/tools/gffread.cwl
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
  Generates a FASTA file with the DNA sequences for all transcripts in a GFF file

s:about: |
  Usage:
    gffread <input_gff> [-g <genomic_seqs_fasta> | <dir>][-s <seq_info.fsize>] 
    [-o <outfile>] [-t <trackname>] [-r [[<strand>]<chr>:]<start>..<end> [-R]]
    [-CTVNJMKQAFPGUBHZWTOLE] [-w <exons.fa>] [-x <cds.fa>] [-y <tr_cds.fa>]
    [-i <maxintron>] [--bed] [--table <attrlist>] [--sort-by <refseq_list.txt>]
    
    Filter, convert or cluster GFF/GTF/BED records, extract the sequence of
    transcripts (exon or CDS) and more.
    By default (i.e. without -O) only transcripts are processed, discarding any
    other non-transcript features. Default output is a simplified GFF3 with only
    the basic attributes.
    
    <input_gff> is a GFF file, use '-' for stdin
    
    Options:
    -i   discard transcripts having an intron larger than <maxintron>
    -l   discard transcripts shorter than <minlen> bases
    -r   only show transcripts overlapping coordinate range <start>..<end>
          (on chromosome/contig <chr>, strand <strand> if provided)
    -R   for -r option, discard all transcripts that are not fully 
          contained within the given range
    -U   discard single-exon transcripts
    -C   coding only: discard mRNAs that have no CDS features
    --nc non-coding only: discard mRNAs that have CDS features
    --ignore-locus : discard locus features and attributes found in the input
    -A   use the description field from <seq_info.fsize> and add it
          as the value for a 'descr' attribute to the GFF record
    -s   <seq_info.fsize> is a tab-delimited file providing this info
          for each of the mapped sequences:
          <seq-name> <seq-length> <seq-description>
          (useful for -A option with mRNA/EST/protein mappings)
    Sorting: (by default, chromosomes are kept in the order they were found)
    --sort-alpha : chromosomes (reference sequences) are sorted alphabetically
    --sort-by : sort the reference sequences by the order in which their
          names are given in the <refseq.lst> file
    Misc options: 
    -F   preserve all GFF attributes (for non-exon features)
    --keep-exon-attrs : for -F option, do not attempt to reduce redundant
          exon/CDS attributes
    -G   do not keep exon attributes, move them to the transcript feature
          (for GFF3 output)
    --keep-genes : in transcript-only mode (default), also preserve gene records
    --keep-comments: for GFF3 input/output, try to preserve comments
    -O   process other non-transcript GFF records (by default non-transcript
          records are ignored)
    -V   discard any mRNAs with CDS having in-frame stop codons (requires -g)
    -H   for -V option, check and adjust the starting CDS phase
          if the original phase leads to a translation with an 
          in-frame stop codon
    -B   for -V option, single-exon transcripts are also checked on the
          opposite strand (requires -g)
    -P   add transcript level GFF attributes about the coding status of each
          transcript, including partialness or in-frame stop codons (requires -g)
    --add-hasCDS : add a "hasCDS" attribute with value "true" for transcripts
          that have CDS features
    --adj-stop stop codon adjustment: enables -P and performs automatic
          adjustment of the CDS stop coordinate if premature or downstream
    -N   discard multi-exon mRNAs that have any intron with a non-canonical
          splice site consensus (i.e. not GT-AG, GC-AG or AT-AC)
    -J   discard any mRNAs that either lack initial START codon
          or the terminal STOP codon, or have an in-frame stop codon
          (i.e. only print mRNAs with a complete CDS)
    --no-pseudo: filter out records matching the 'pseudo' keyword
    --in-bed: input should be parsed as BED format (automatic if the input
              filename ends with .bed*)
    --in-tlf: input GFF-like one-line-per-transcript format without exon/CDS
              features (see --tlf option below); automatic if the input
              filename ends with .tlf)
    Clustering:
    -M/--merge : cluster the input transcripts into loci, discarding
          "duplicated" transcripts (those with the same exact introns
          and fully contained or equal boundaries)
    -d <dupinfo> : for -M option, write duplication info to file <dupinfo>
    --cluster-only: same as -M/--merge but without discarding any of the
          "duplicate" transcripts, only create "locus" features
    -K   for -M option: also discard as redundant the shorter, fully contained
          transcripts (intron chains matching a part of the container)
    -Q   for -M option, no longer require boundary containment when assessing
          redundancy (can be combined with -K); only introns have to match for
          multi-exon transcripts, and >=80% overlap for single-exon transcripts
    -Y   for -M option, enforce -Q but also discard overlapping single-exon 
          transcripts, even on the opposite strand (can be combined with -K)
    Output options:
    --force-exons: make sure that the lowest level GFF features are considered
          "exon" features
    --gene2exon: for single-line genes not parenting any transcripts, add an
          exon feature spanning the entire gene (treat it as a transcript)
    --t-adopt:  try to find a parent gene overlapping/containing a transcript
          that does not have any explicit gene Parent
    -D    decode url encoded characters within attributes
    -Z    merge very close exons into a single exon (when intron size<4)
    -g   full path to a multi-fasta file with the genomic sequences
          for all input mappings, OR a directory with single-fasta files
          (one per genomic sequence, with file names matching sequence names)
    -w    write a fasta file with spliced exons for each transcript
    --w-add <N> for the -w option, extract additional <N> bases
          both upstream and downstream of the transcript boundaries
    -x    write a fasta file with spliced CDS for each GFF transcript
    -y    write a protein fasta file with the translation of CDS for each record
    -W    for -w and -x options, write in the FASTA defline the exon
          coordinates projected onto the spliced sequence;
          for -y option, write transcript attributes in the FASTA defline
    -S    for -y option, use '*' instead of '.' as stop codon translation
    -L    Ensembl GTF to GFF3 conversion (implies -F; should be used with -m)
    -m    <chr_replace> is a name mapping table for converting reference 
          sequence names, having this 2-column format:
          <original_ref_ID> <new_ref_ID>
    -t    use <trackname> in the 2nd column of each GFF/GTF output line
    -o    write the records into <outfile> instead of stdout
    -T    main output will be GTF instead of GFF3
    --bed output records in BED format instead of default GFF3
    --tlf output "transcript line format" which is like GFF
          but exons, CDS features and related data are stored as GFF 
          attributes in the transcript feature line, like this:
            exoncount=N;exons=<exons>;CDSphase=<N>;CDS=<CDScoords> 
          <exons> is a comma-delimited list of exon_start-exon_end coordinates;
          <CDScoords> is CDS_start:CDS_end coordinates or a list like <exons>
    --table output a simple tab delimited format instead of GFF, with columns
          having the values of GFF attributes given in <attrlist>; special
          pseudo-attributes (prefixed by @) are recognized:
          @id, @geneid, @chr, @start, @end, @strand, @numexons, @exons, 
          @cds, @covlen, @cdslen
    -v,-E expose (warn about) duplicate transcript IDs and other potential
          problems with the given GFF/GTF records