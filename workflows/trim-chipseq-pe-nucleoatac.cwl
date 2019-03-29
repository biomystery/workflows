cwlVersion: v1.0
class: Workflow

requirements:
  - class: SubworkflowFeatureRequirement
  - class: ScatterFeatureRequirement
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement

inputs:

  indices_folder:
    type: Directory
    label: "BOWTIE indices folder"
    doc: "Path to BOWTIE generated indices folder"

  annotation_file:
    type: File
    label: "Annotation file"
    format: "http://edamontology.org/format_3475"
    doc: "Tab-separated input annotation file"

  genome_fasta_file:
    type: File
    label: "FASTA file"
    format: "http://edamontology.org/format_1929"
    doc: "Reference genome in fasta format + samtools faidx index"

  genome_size:
    type: string
    label: "Effective genome size"
    doc: "MACS2 effective genome size: hs, mm, ce, dm or number, for example 2.7e9"

  chrom_length:
    type: File
    label: "Chromosome length file"
    format: "http://edamontology.org/format_2330"
    doc: "Chromosome length file"

  control_file:
    type: File?
    default: null
    label: "Control BAM file"
    format: "http://edamontology.org/format_2572"
    doc: "Control BAM file file for MACS2 peak calling"

  broad_peak:
    type: boolean
    label: "Callpeak broad"
    doc: "Set to call broad peak for MACS2"

  fastq_file_upstream:
    type: File
    label: "FASTQ upstream input file"
    format: "http://edamontology.org/format_1930"
    doc: "Upstream reads data in a FASTQ format, received after paired end sequencing"

  fastq_file_downstream:
    type: File
    label: "FASTQ downstream input file"
    format: "http://edamontology.org/format_1930"
    doc: "Downstream reads data in a FASTQ format, received after paired end sequencing"

  blacklist_regions_file:
    type: File
    label: "Blacklist regions BED6 file"
    format: "http://edamontology.org/format_3585"
    doc: "Blacklist regions to be removed from BAM"

  exp_fragment_size:
    type: int?
    default: 150
    label: "Expected fragment size"
    doc: "Expected fragment size for MACS2"

  force_fragment_size:
    type: boolean?
    default: false
    label: "Force fragment size"
    doc: "Force MACS2 to use exp_fragment_size"

  clip_3p_end:
    type: int?
    default: 0
    label: "Clip from 3p end"
    doc: "Number of bases to clip from the 3p end"

  clip_5p_end:
    type: int?
    default: 0
    label: "Clip from 5p end"
    doc: "Number of bases to clip from the 5p end"

  remove_duplicates:
    type: boolean?
    default: false
    label: "Remove duplicates"
    doc: "Calls samtools rmdup to remove duplicates from sortesd BAM file"

  threads:
    type: int?
    default: 2
    doc: "Number of threads for those steps that support multithreading"
    label: "Number of threads"

outputs:

  bigwig:
    type: File
    format: "http://edamontology.org/format_3006"
    label: "BigWig file"
    doc: "Generated BigWig file"
    outputSource: bam_to_bigwig/bigwig_file

  fastx_statistics_upstream:
    type: File
    label: "FASTQ upstream statistics"
    format: "http://edamontology.org/format_2330"
    doc: "fastx_quality_stats generated upstream FASTQ quality statistics file"
    outputSource: fastx_quality_stats_upstream/statistics_file

  fastx_statistics_downstream:
    type: File
    label: "FASTQ downstream statistics"
    format: "http://edamontology.org/format_2330"
    doc: "fastx_quality_stats generated downstream FASTQ quality statistics file"
    outputSource: fastx_quality_stats_downstream/statistics_file

  bowtie_log:
    type: File
    label: "BOWTIE alignment log"
    format: "http://edamontology.org/format_2330"
    doc: "BOWTIE generated alignment log"
    outputSource: bowtie_aligner/log_file

  iaintersect_log:
    type: File
    label: "Island intersect log"
    format: "http://edamontology.org/format_3475"
    doc: "Iaintersect generated log"
    outputSource: island_intersect/log_file

  iaintersect_result:
    type: File
    label: "Island intersect results"
    format: "http://edamontology.org/format_3475"
    doc: "Iaintersect generated results"
    outputSource: island_intersect/result_file

  atdp_log:
    type: File
    label: "ATDP log"
    format: "http://edamontology.org/format_3475"
    doc: "Average Tag Density generated log"
    outputSource: average_tag_density/log_file

  atdp_result:
    type: File
    label: "ATDP results"
    format: "http://edamontology.org/format_3475"
    doc: "Average Tag Density generated results"
    outputSource: average_tag_density/result_file

  samtools_rmdup_log:
    type: File
    label: "Remove duplicates log"
    format: "http://edamontology.org/format_2330"
    doc: "Samtools rmdup generated log"
    outputSource: samtools_rmdup/rmdup_log

  bambai_pair:
    type: File
    format: "http://edamontology.org/format_2572"
    label: "Coordinate sorted BAM alignment file (+index BAI)"
    doc: "Coordinate sorted BAM file and BAI index file"
    outputSource: samtools_sort_index_after_rmdup/bam_bai_pair

  macs2_called_peaks:
    type: File?
    label: "Called peaks"
    format: "http://edamontology.org/format_3468"
    doc: "XLS file to include information about called peaks"
    outputSource: macs2_callpeak/peak_xls_file

  macs2_narrow_peaks:
    type: File?
    label: "Narrow peaks"
    format: "http://edamontology.org/format_3613"
    doc: "Contains the peak locations together with peak summit, pvalue and qvalue"
    outputSource: macs2_callpeak/narrow_peak_file

  macs2_broad_peaks:
    type: File?
    label: "Broad peaks"
    format: "http://edamontology.org/format_3614"
    doc: "Contains the peak locations together with peak summit, pvalue and qvalue"
    outputSource: macs2_callpeak/broad_peak_file

  macs2_peak_summits:
    type: File?
    label: "Peak summits"
    format: "http://edamontology.org/format_3003"
    doc: "Contains the peak summits locations for every peaks"
    outputSource: macs2_callpeak/peak_summits_file

  macs2_moder_r:
    type: File?
    label: "MACS2 generated R script"
    format: "http://edamontology.org/format_2330"
    doc: "R script to produce a PDF image about the model based on your data"
    outputSource: macs2_callpeak/moder_r_file

  macs2_gapped_peak:
    type: File?
    label: "Gapped peak"
    format: "http://edamontology.org/format_3586"
    doc: "Contains both the broad region and narrow peaks"
    outputSource: macs2_callpeak/gapped_peak_file

  macs2_log:
    type: File?
    label: "MACS2 log"
    format: "http://edamontology.org/format_2330"
    doc: "MACS2 output log"
    outputSource: macs2_callpeak/macs_log

  get_stat_log:
    type: File?
    label: "Bowtie & Samtools Rmdup combined log"
    format: "http://edamontology.org/format_2330"
    doc: "Processed and combined Bowtie aligner and Samtools rmdup log"
    outputSource: get_stat/output_file

  get_stat_formatted_log:
    type: File?
    label: "Bowtie & Samtools Rmdup combined formatted log"
    format: "http://edamontology.org/format_3475"
    doc: "Processed and combined Bowtie aligner and Samtools rmdup formatted log"
    outputSource: get_stat/formatted_output_file

  macs2_fragment_stat:
    type: File?
    label: "FRAGMENT, FRAGMENTE, ISLANDS"
    format: "http://edamontology.org/format_2330"
    doc: "fragment, calculated fragment, islands count from MACS2 results"
    outputSource: macs2_callpeak/macs2_stat_file

  trim_report_upstream:
    type: File
    label: "TrimGalore report Upstream"
    doc: "TrimGalore generated log for upstream FASTQ"
    outputSource: trim_fastq/report_file

  trim_report_downstream:
    type: File
    label: "TrimGalore report Downstream"
    doc: "TrimGalore generated log for downstream FASTQ"
    outputSource: trim_fastq/report_file_pair

  preseq_estimates:
    type: File?
    label: "Preseq estimates"
    format: "http://edamontology.org/format_3475"
    doc: "Preseq estimated results"
    outputSource: preseq/estimates_file

  nucl_occ_tracks:
    type: File?
    outputSource: nucleoatac/nucl_occ_tracks

  nucl_occ_lower_bound_tracks:
    type: File?
    outputSource: nucleoatac/nucl_occ_lower_bound_tracks

  nucl_occ_upper_bound_tracks:
    type: File?
    outputSource: nucleoatac/nucl_occ_upper_bound_tracks

  nucl_dist_txt:
    type: File?
    outputSource: nucleoatac/nucl_dist_txt

  nucl_dist_plot:
    type: File?
    outputSource: nucleoatac/nucl_dist_plot

  fragsize_in_peaks_txt:
    type: File?
    outputSource: nucleoatac/fragsize_in_peaks_txt

  nucl_occ_fit_txt:
    type: File?
    outputSource: nucleoatac/nucl_occ_fit_txt

  nucl_occ_fit_plot:
    type: File?
    outputSource: nucleoatac/nucl_occ_fit_plot

  nucl_occ_peaks_bed:
    type: File?
    outputSource: nucleoatac/nucl_occ_peaks_bed

  nucl_vplot_data:
    type: File?
    outputSource: nucleoatac/nucl_vplot_data

  nucl_pos_bed:
    type: File?
    outputSource: nucleoatac/nucl_pos_bed

  nucl_pos_redundant_bed:
    type: File?
    outputSource: nucleoatac/nucl_pos_redundant_bed

  nucl_norm_crosscor_tracks:
    type: File?
    outputSource: nucleoatac/nucl_norm_crosscor_tracks

  nucl_norm_smooth_crosscor_tracks:
    type: File?
    outputSource: nucleoatac/nucl_norm_smooth_crosscor_tracks

  combined_nucl_pos_bed:
    type: File?
    outputSource: nucleoatac/combined_nucl_pos_bed

  nfr_pos_bed:
    type: File?
    outputSource: nucleoatac/nfr_pos_bed

  nucleoatac_stderr:
    type: File?
    outputSource: nucleoatac/nucleoatac_stderr

  nucleoatac_stdout:
    type: File?
    outputSource: nucleoatac/nucleoatac_stdout


steps:

  extract_fastq_upstream:
    run: ../tools/extract-fastq.cwl
    in:
      compressed_file: fastq_file_upstream
    out: [fastq_file]

  extract_fastq_downstream:
    run: ../tools/extract-fastq.cwl
    in:
      compressed_file: fastq_file_downstream
    out: [fastq_file]

  trim_fastq:
    run: ../tools/trimgalore.cwl
    in:
      input_file: extract_fastq_upstream/fastq_file
      input_file_pair: extract_fastq_downstream/fastq_file
      dont_gzip:
        default: true
      length:
        default: 30
      trim1:
        default: true
      paired:
        default: true
    out:
      - trimmed_file
      - trimmed_file_pair
      - report_file
      - report_file_pair

  rename_upstream:
    run: ../tools/rename.cwl
    in:
      source_file: trim_fastq/trimmed_file
      target_filename:
        source: extract_fastq_upstream/fastq_file
        valueFrom: $(self.basename)
    out:
      - target_file

  rename_downstream:
    run: ../tools/rename.cwl
    in:
      source_file: trim_fastq/trimmed_file_pair
      target_filename:
        source: extract_fastq_downstream/fastq_file
        valueFrom: $(self.basename)
    out:
      - target_file

  fastx_quality_stats_upstream:
    run: ../tools/fastx-quality-stats.cwl
    in:
      input_file: rename_upstream/target_file
    out: [statistics_file]

  fastx_quality_stats_downstream:
    run: ../tools/fastx-quality-stats.cwl
    in:
      input_file: rename_downstream/target_file
    out: [statistics_file]

  bowtie_aligner:
    run: ../tools/bowtie-alignreads.cwl
    in:
      upstream_filelist: rename_upstream/target_file
      downstream_filelist: rename_downstream/target_file
      indices_folder: indices_folder
      clip_3p_end: clip_3p_end
      clip_5p_end: clip_5p_end
      v:
        default: 3
      m:
        default: 1
      best:
        default: true
      strata:
        default: true
      sam:
        default: true
      threads: threads
      q:
        default: true
      X:
        default: 500  
    out: [sam_file, log_file]

  samtools_view:
    run: ../tools/samtools-view.cwl
    in:
      view_input: bowtie_aligner/sam_file
      bed_overlap: blacklist_regions_file
      filtered_out:
        default: "filtered.sam"
      samheader:
        default: true
      threads: threads
    out: [filtered_file]

  samtools_sort_index:
    run: ../tools/samtools-sort-index.cwl
    in:
      sort_input: samtools_view/filtered_file
      threads: threads
    out: [bam_bai_pair]

  preseq:
    run: ../tools/preseq-lc-extrap.cwl
    in:
      bam_file: samtools_sort_index/bam_bai_pair
      pe_mode:
        default: true
    out: [estimates_file]

  samtools_rmdup:
    run: ../tools/samtools-rmdup.cwl
    in:
      trigger: remove_duplicates
      bam_file: samtools_sort_index/bam_bai_pair
    out: [rmdup_output, rmdup_log]

  samtools_sort_index_after_rmdup:
    run: ../tools/samtools-sort-index.cwl
    in:
      trigger: remove_duplicates
      sort_input: samtools_rmdup/rmdup_output
      threads: threads
    out: [bam_bai_pair]

  macs2_callpeak:
    run: ../tools/macs2-callpeak-biowardrobe-only.cwl
    in:
      treatment_file: samtools_sort_index_after_rmdup/bam_bai_pair
      control_file: control_file
      nolambda:
        source: control_file
        valueFrom: $(!self)
      genome_size: genome_size
      mfold:
        default: "4 40"
      verbose:
        default: 3
      nomodel: force_fragment_size
      extsize: exp_fragment_size
      bw: exp_fragment_size
      broad: broad_peak
      call_summits:
        source: broad_peak
        valueFrom: $(!self)
      keep_dup:
        default: auto
      q_value:
        default: 0.05
      format_mode:
        default: BAMPE
      buffer_size:
        default: 10000
    out:
      - peak_xls_file
      - narrow_peak_file
      - peak_summits_file
      - broad_peak_file
      - moder_r_file
      - gapped_peak_file
      - treat_pileup_bdg_file
      - control_lambda_bdg_file
      - macs_log
      - macs2_stat_file
      - macs2_fragments_calculated

  nucleoatac:
    run: ../tools/nucleoatac.cwl
    in:
      bam_file: samtools_sort_index_after_rmdup/bam_bai_pair
      bed_file: macs2_callpeak/broad_peak_file
      fasta_file: genome_fasta_file
      output_basename:
        default: "nucleoatac_results"
      threads: threads
    out:
      - nucl_occ_tracks
      - nucl_occ_lower_bound_tracks
      - nucl_occ_upper_bound_tracks
      - nucl_dist_txt
      - nucl_dist_plot
      - fragsize_in_peaks_txt
      - nucl_occ_fit_txt
      - nucl_occ_fit_plot
      - nucl_occ_peaks_bed
      - nucl_vplot_data
      - nucl_pos_bed
      - nucl_pos_redundant_bed
      - nucl_norm_crosscor_tracks
      - nucl_norm_smooth_crosscor_tracks
      - combined_nucl_pos_bed
      - nfr_pos_bed
      - nucleoatac_stderr
      - nucleoatac_stdout
      
  bam_to_bigwig:
    run: ../subworkflows/bam-bedgraph-bigwig.cwl
    in:
      bam_file: samtools_sort_index_after_rmdup/bam_bai_pair
      chrom_length_file: chrom_length
      mapped_reads_number: get_stat/mapped_reads
      fragment_size: macs2_callpeak/macs2_fragments_calculated
      pairchip:
        default: true
    out: [bigwig_file]

  get_stat:
      run: ../tools/python-get-stat-chipseq.cwl
      in:
        bowtie_log: bowtie_aligner/log_file
        rmdup_log: samtools_rmdup/rmdup_log
      out:
        - output_file
        - mapped_reads
        - formatted_output_file

  island_intersect:
      run: ../tools/iaintersect.cwl
      in:
        input_filename: macs2_callpeak/peak_xls_file
        annotation_filename: annotation_file
        promoter_bp:
          default: 1000
      out: [result_file, log_file]

  average_tag_density:
      run: ../tools/atdp.cwl
      in:
        input_file: samtools_sort_index_after_rmdup/bam_bai_pair
        annotation_filename: annotation_file
        fragmentsize_bp: macs2_callpeak/macs2_fragments_calculated
        avd_window_bp:
          default: 5000
        avd_smooth_bp:
          default: 50
        ignore_chr:
          default: chrM
        double_chr:
          default: "chrX chrY"
        avd_heat_window_bp:
          default: 200
        mapped_reads: get_stat/mapped_reads
      out: [result_file, log_file]