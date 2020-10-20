cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement
- class: InitialWorkDirRequirement
  listing: |
    ${
      var listing = [
        {
          "entry": inputs.fastq_file_r1,
          "entryname": "sample_S1_L001_R1_001.fastq.gz",
          "writable": true
        },
        {
          "entry": inputs.fastq_file_r2,
          "entryname": "sample_S1_L001_R2_001.fastq.gz",
          "writable": true
        }
      ];
      if (inputs.fastq_file_i1){
        listing.push(
          {
            "entry": inputs.fastq_file_i1,
            "entryname": "sample_S1_L001_I1_001.fastq.gz",
            "writable": true
          }
        );
      };
      return listing;
    }


hints:
- class: DockerRequirement
  dockerPull: cumulusprod/cellranger:4.0.0


inputs:
  
  fastq_file_r1:
    type: File
    doc: |
      Fastq file 1 (will be staged into workdir as sample_S1_L001_R1_001.fastq.gz)

  fastq_file_r2:
    type: File
    doc: |
      Fastq file 2 (will be staged into workdir as sample_S1_L001_R2_001.fastq.gz)

  fastq_file_i1:
    type: File?
    doc: |
      Fastq file 3 (if provided, will be staged into workdir as sample_S1_L001_I1_001.fastq.gz)

  indices_folder:
    type: Directory
    inputBinding:
      position: 5
      prefix: "--transcriptome"
    doc: |
      Path of folder containing 10x-compatible transcriptome reference.
      Should be generated by "cellranger mkref" command

  threads:
    type: int?
    inputBinding:
      position: 6
      prefix: "--localcores"
    doc: |
      Set max cores the pipeline may request at one time.
      Default: all available

  memory_limit:
    type: int?
    inputBinding:
      position: 7
      prefix: "--localmem"
    doc: |
      Set max GB the pipeline may request at one time
      Default: all available

  virt_memory_limit:
    type: int?
    inputBinding:
      position: 8
      prefix: "--localvmem"
    doc: |
      Set max virtual address space in GB for the pipeline
      Default: all available


outputs:

  web_summary_report:
    type: File
    outputBinding:
      glob: "sample/outs/web_summary.html"
    doc: |
      Run summary metrics and charts in HTML format

  metrics_summary_report:
    type: File
    outputBinding:
      glob: "sample/outs/metrics_summary.csv"
    doc: |
      Run summary metrics in CSV format

  possorted_genome_bam_bai:
    type: File
    outputBinding:
      glob: "sample/outs/possorted_genome_bam.bam"
    secondaryFiles:
    - .bai
    doc: |
      Indexed reads aligned to the genome and transcriptome annotated with barcode information
  
  filtered_feature_bc_matrix_folder:
    type: Directory
    outputBinding:
      glob: "sample/outs/filtered_feature_bc_matrix"
    doc: |
      Folder with filtered feature-barcode matrices containing only cellular barcodes in MEX format.
      When implemented, in Targeted Gene Expression samples, the non-targeted genes won't be present.

  filtered_feature_bc_matrix_h5:
    type: File
    outputBinding:
      glob: "sample/outs/filtered_feature_bc_matrix.h5"
    doc: |
      Filtered feature-barcode matrices containing only cellular barcodes in HDF5 format.
      When implemented, in Targeted Gene Expression samples, the non-targeted genes won't
      be present.
  
  raw_feature_bc_matrices_folder:
    type: Directory
    outputBinding:
      glob: "sample/outs/raw_feature_bc_matrix"
    doc: |
      Folder with unfiltered feature-barcode matrices containing all barcodes in MEX format

  raw_feature_bc_matrices_h5:
    type: File
    outputBinding:
      glob: "sample/outs/raw_feature_bc_matrix.h5"
    doc: |
      Unfiltered feature-barcode matrices containing all barcodes in HDF5 format

  secondary_analysis_report_folder:
    type: Directory
    outputBinding:
      glob: "sample/outs/analysis"
    doc: |
      Folder with secondary analysis results including dimensionality reduction,
      cell clustering, and differential expression

  molecule_info_h5:
    type: File
    outputBinding:
      glob: "sample/outs/molecule_info.h5"
    doc: |
      Molecule-level information used by cellranger aggr to aggregate samples into
      larger datasets

  loupe_browser_track:
    type: File
    outputBinding:
      glob: "sample/outs/cloupe.cloupe"
    doc: |
      Loupe Browser visualization and analysis file

  stdout_log:
    type: stdout

  stderr_log:
    type: stderr


baseCommand: ["cellranger", "count", "--disable-ui", "--fastqs", ".", "--id", "sample"]


stdout: cellranger_count_stdout.log
stderr: cellranger_count_stderr.log


doc: |
  Generates single cell feature counts for a single library.

  Input parameters for Feature Barcode, Targeted Gene Expression and CRISPR-specific
  analyses are not implemented, therefore the correspondent outputs are also excluded.

  Parameters set by default:
  --disable-ui - no need in any UI when running in Docker container
  --id - can be hardcoded as we rename input files anyway
  --fastqs - points to the current directory, because input FASTQ files are staged there

  Why do we need to rename input files?
  Refer to the "My FASTQs are not named like any of the above examples" section of
  https://support.10xgenomics.com/single-cell-gene-expression/software/pipelines/latest/using/fastq-input


s:about: |
  Count gene expression and feature barcoding reads from a single sample and GEM well

  USAGE:
      cellranger count [FLAGS] [OPTIONS] --id <ID> --transcriptome <PATH>

  FLAGS:
          --no-target-umi-filter    Turn off the target UMI filtering subpipeline
          --nosecondary             Disable secondary analysis, e.g. clustering. Optional
          --no-libraries            Proceed with processing using a --feature-ref but no Feature Barcode libraries specified with the 'libraries' flag
          --dry                     Do not execute the pipeline. Generate a pipeline invocation (.mro) file and stop
          --disable-ui              Do not serve the UI
          --noexit                  Keep web UI running after pipestance completes or fails
          --nopreflight             Skip preflight checks
      -h, --help                    Prints help information

  OPTIONS:
          --id <ID>                 A unique run id and output folder name [a-zA-Z0-9_-]+
          --description <TEXT>      Sample description to embed in output files
          --transcriptome <PATH>    Path of folder containing 10x-compatible transcriptome reference
      -f, --fastqs <PATH>...        Path to input FASTQ data
      -p, --project <TEXT>          Name of the project folder within a mkfastq or bcl2fastq-generated folder to pick FASTQs from
      -s, --sample <PREFIX>...      Prefix of the filenames of FASTQs to select
          --lanes <NUMS>...         Only use FASTQs from selected lanes
          --libraries <CSV>         CSV file declaring input library data sources
          --feature-ref <CSV>       Feature reference CSV file, declaring Feature Barcode constructs and associated barcodes
          --target-panel <CSV>      The target panel CSV file declaring the target panel used, if any
          --expect-cells <NUM>      Expected number of recovered cells
          --force-cells <NUM>       Force pipeline to use this number of cells, bypassing cell detection
          --r1-length <NUM>         Hard trim the input Read 1 to this length before analysis
          --r2-length <NUM>         Hard trim the input Read 2 to this length before analysis
          --chemistry <CHEM>        Assay configuration. NOTE: by default the assay configuration is detected automatically, which is the recommened mode. You usually will not need
                                    to specify a chemistry. Options are: 'auto' for autodetection, 'threeprime' for Single Cell 3', 'fiveprime' for  Single Cell 5', 'SC3Pv1' or
                                    'SC3Pv2' or 'SC3Pv3' for Single Cell 3' v1/v2/v3, 'SC5P-PE' or 'SC5P-R2' for Single Cell 5', paired-end/R2-only, 'SC-FB' for Single Cell Antibody-
                                    only 3' v2 or 5' [default: auto]
          --jobmode <MODE>          Job manager to use. Valid options: local (default), sge, lsf, slurm or a .template file. Search for help on "Cluster Mode" at
                                    support.10xgenomics.com for more details on configuring the pipeline to use a compute cluster [default: local]
          --localcores <NUM>        Set max cores the pipeline may request at one time. Only applies to local jobs
          --localmem <NUM>          Set max GB the pipeline may request at one time. Only applies to local jobs
          --localvmem <NUM>         Set max virtual address space in GB for the pipeline. Only applies to local jobs
          --mempercore <NUM>        Reserve enough threads for each job to ensure enough memory will be available, assuming each core on your cluster has at least this much memory
                                    available. Only applies in cluster jobmodes
          --maxjobs <NUM>           Set max jobs submitted to cluster at one time. Only applies in cluster jobmodes
          --jobinterval <NUM>       Set delay between submitting jobs to cluster, in ms. Only applies in cluster jobmodes
          --overrides <PATH>        The path to a JSON file that specifies stage-level overrides for cores and memory. Finer-grained than --localcores, --mempercore and --localmem.
                                    Consult the 10x support website for an example override file
          --uiport <PORT>           Serve web UI at http://localhost:PORT