cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement
  expressionLib:
  - var default_output_filename = function(ext) {
      ext = ext || "";
      return inputs.output_filename == "" ? inputs.bam_file.nameroot+".peakclusters.bed"+ext:inputs.output_filename+ext;
    };


hints:
  - class: DockerRequirement
    dockerPull: biowardrobe2/clipper:v0.0.1


inputs:

  bam_file:
    type: File
    inputBinding:
      prefix: "-b"
    secondaryFiles:
    - .bai
    doc: "A bam file to call peaks on"

  species:
    type: string?
    inputBinding:
      prefix: "-s"
    doc: "Species: one of ce10 ce11 dm3 hg19 GRCh38 mm9 mm10"

  output_filename:
    type: string
    inputBinding:
      prefix: "-o"
      valueFrom: $(default_output_filename())
    default: ""
    doc: "Output BED file name"


outputs:

  output_tsv:
    type: File
    outputBinding:
      glob: $(default_output_filename(".tsv"))

  output_bed:
    type: File
    outputBinding:
      glob: $(default_output_filename())


baseCommand: [clipper]


doc: |
  CLIPper is a tool to define peaks in your CLIP-seq dataset.
  CLIPper was developed in the Yeo Lab at the University of California, San Diego.
    Usage: clipper --bam CLIP-seq_reads.srt.bam --species hg19 --outfile CLIP-seq_reads.srt.peaks.bed
    
  Usage: 
      THIS IS CLIPPER FOR ECLIP VERSION 0.1.4
      python peakfinder.py -b <bamfile> -s <hg18/hg19/mm9> OR 
      python peakfinder.py -b <bamfile> --customBED <BEDfile> --customMRNA 
      <mRNA lengths> --customPREMRNA <premRNA lengths>

  CLIPper. Michael Lovci, Gabriel Pratt 2012.                       CLIP
  peakfinder that uses fitted smoothing splines to                       define
  clusters of binding.  Computation is performed in
  parallel using parallelPython.                       Refer to:
  https://github.com/YeoLab/clipper/wiki for instructions.
  Questions should be directed to michaeltlovci@gmail.com.

  Options:
    -h, --help            show this help message and exit
    -b FILE.bam, --bam=FILE.bam
                          A bam file to call peaks on
    -s SPECIES, --species=SPECIES
                          A species for your peak-finding, either hg19 or mm9
    -o OUTFILEF, --outfile=OUTFILEF
                          a bed file output, default:fitted_clusters
    -g GENENAME, --gene=GENENAME
                          A specific gene you'd like try
    --minreads=NREADS     minimum reads required for a section to start the
                          fitting process.  Default:3
    --poisson-cutoff=P    p-value cutoff for poisson test, Default:0.05
    --disable_global_cutoff
                          disables global transcriptome level cutoff to CLIP-seq
                          peaks, Default:On
    --FDR=FDR_ALPHA       FDR cutoff for significant height estimation,
                          default=0.05
    --binomial=BINOM      Alpha significance threshold for using Binomial
                          distribution for determining height threshold,
                          default=0.05
    --threshold=THRESHOLD
                          Skip FDR calculation and set a threshold yourself
    --maxgenes=NGENES     stop computation after this many genes, for testing
    --processors=NP       Number of processors to use. Default: All processors
                          on machine
    -p, --plot            make figures of the fits
    -v, --verbose         
    -q, --quiet           suppress notifications
    --save-pickle         Save a pickle file containing the analysis
    --debug               disables multipcoressing in order to get proper error
                          tracebacks
    --max_gap=MAX_GAP     defines maximum gap between reads before calling a
                          region a new section, default: 15
    --timeout=TIMEOUT     adds timeout (in seconds) to genes that take too long
                          (useful for debugging only, or if you don't care about
                          higly expressed genes)