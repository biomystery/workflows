cwlVersion: v1.0
class: Workflow


requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement


inputs:

  regions_file_a:
    type: File

  regions_file_a_name:
    type: string



  regions_file_b:
    type: File

  regions_file_b_name:
    type: string



  target_regions:
    type: File

  target_regions_name:
    type: string

  recenter_target_regions:
    type:
      - "null"
      - type: enum
        symbols: ["TSS", "Skip"]
    default: "Skip"



  max_distance:
    type: int

  chrom_length_file:
    type: File

  annotation_file:
    type: File

  annotate_dist:
    type: int


outputs:

  unique_from_a:
    type: File
    outputSource: get_unique_a_within_max_distance_from_target_regions/intersected_file

  unique_from_b:
    type: File
    outputSource: get_unique_b_within_max_distance_from_target_regions/intersected_file

  merged_overlapped_a_and_b:
    type: File
    outputSource: get_merged_overlapped_a_and_b_within_max_distance_from_target_regions/intersected_file
  
  recentered_target_regions:
    type: File
    outputSource: recenter_target_regions/output_file



  annotated_unique_from_a:
    type: File
    outputSource: filter_annotated_unique_a_within_max_distance_from_target_regions/output_file

  annotated_unique_from_b:
    type: File
    outputSource: filter_annotated_unique_b_within_max_distance_from_target_regions/output_file

  annotated_merged_overlapped_a_and_b:
    type: File
    outputSource: filter_annotated_merged_overlapped_a_and_b_within_max_distance_from_target_regions/output_file



  rel_dist_distr_from_unique_a_to_target_regions:
    type: File
    outputSource: get_rel_dist_distr_from_unique_a_to_target_regions/relative_distance_distribution

  rel_dist_distr_from_unique_b_to_target_regions:
    type: File
    outputSource: get_rel_dist_distr_from_unique_b_to_target_regions/relative_distance_distribution

  rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions:
    type: File
    outputSource: get_rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions/relative_distance_distribution

  rel_dist_distr_from_unique_a_to_target_regions_plot:
    type: File
    outputSource: plot_rel_dist_distr_from_unique_a_to_target_regions/relative_distance_distribution_plot

  rel_dist_distr_from_unique_b_to_target_regions_plot:
    type: File
    outputSource: plot_rel_dist_distr_from_unique_b_to_target_regions/relative_distance_distribution_plot

  rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions_plot:
    type: File
    outputSource: plot_rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions/relative_distance_distribution_plot



  rel_dist_distr_from_target_regions_to_unique_a:
    type: File
    outputSource: get_rel_dist_distr_from_target_regions_to_unique_a/relative_distance_distribution

  rel_dist_distr_from_target_regions_to_unique_b:
    type: File
    outputSource: get_rel_dist_distr_from_target_regions_to_unique_b/relative_distance_distribution

  rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b:
    type: File
    outputSource: get_rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b/relative_distance_distribution

  rel_dist_distr_from_target_regions_to_unique_a_plot:
    type: File
    outputSource: plot_rel_dist_distr_from_target_regions_to_unique_a/relative_distance_distribution_plot

  rel_dist_distr_from_target_regions_to_unique_b_plot:
    type: File
    outputSource: plot_rel_dist_distr_from_target_regions_to_unique_b/relative_distance_distribution_plot

  rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b_plot:
    type: File
    outputSource: plot_rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b/relative_distance_distribution_plot



  rel_dist_from_target_regions_to_unique_a:
    type: File
    outputSource: get_rel_dist_from_target_regions_to_unique_a/relative_distance_distribution

  rel_dist_from_target_regions_to_unique_b:
    type: File
    outputSource: get_rel_dist_from_target_regions_to_unique_b/relative_distance_distribution

  rel_dist_from_target_regions_to_merged_overlapped_a_and_b:
    type: File
    outputSource: get_rel_dist_from_target_regions_to_merged_overlapped_a_and_b/relative_distance_distribution

  rel_dist_from_target_regions_to_unique_a_plot:
    type: File
    outputSource: plot_rel_dist_from_target_regions_to_unique_a/relative_distance_plot

  rel_dist_from_target_regions_to_unique_b_plot:
    type: File
    outputSource: plot_rel_dist_from_target_regions_to_unique_b/relative_distance_plot

  rel_dist_from_target_regions_to_merged_overlapped_a_and_b_plot:
    type: File
    outputSource: plot_rel_dist_from_target_regions_to_merged_overlapped_a_and_b/relative_distance_plot


steps:

  dedup_and_sort_a:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: regions_file_a
      script:
        default: |
          cat "$0" | tr -d '\r' | tr "," "\t" | cut -f 1-3 | sort -u | sort -k1,1 -k2,2n > filtered_by_max_distance_unique_from_a.bed
    out:
      - output_file

  dedup_and_sort_b:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: regions_file_b
      script:
        default: |
          cat "$0" | tr -d '\r' | tr "," "\t" | cut -f 1-3 | sort -u | sort -k1,1 -k2,2n > filtered_by_max_distance_unique_from_b.bed
    out:
      - output_file

  get_unique_from_a:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: dedup_and_sort_a/output_file
      file_b: dedup_and_sort_b/output_file
      no_overlaps:
        default: true
    out: [intersected_file]

  sort_unique_from_a:
    run: ../../tools/linux-sort.cwl
    in:
      unsorted_file: get_unique_from_a/intersected_file
      key:
        default: ["1,1","2,2n"]
    out:
      - sorted_file

  get_unique_from_b:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: dedup_and_sort_b/output_file
      file_b: dedup_and_sort_a/output_file
      no_overlaps:
        default: true
    out: [intersected_file]

  sort_unique_from_b:
    run: ../../tools/linux-sort.cwl
    in:
      unsorted_file: get_unique_from_b/intersected_file
      key:
        default: ["1,1","2,2n"]
    out:
      - sorted_file

  get_overlapped_from_a:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: dedup_and_sort_a/output_file
      file_b: dedup_and_sort_b/output_file
      report_from_a_once:
        default: true
    out: [intersected_file]

  get_overlapped_from_b:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: dedup_and_sort_b/output_file
      file_b: dedup_and_sort_a/output_file
      report_from_a_once:
        default: true
    out: [intersected_file]

  combine_overlapped_from_a_and_b:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: [get_overlapped_from_a/intersected_file, get_overlapped_from_b/intersected_file]
      script:
        default: |
          cat "$0" > temp.tsv
          cat "$1" >> temp.tsv
          cat temp.tsv | sort -u | sort -k1,1 -k2,2n > filtered_by_max_distance_merged_overlapped_a_and_b.bed
          rm temp.tsv
    out:
      - output_file

  merge_overlapped_a_and_b:
    run: ../../tools/bedtools-merge.cwl
    in:
      bed_file: combine_overlapped_from_a_and_b/output_file
    out: [merged_bed_file]

  sort_merged_overlapped_a_and_b:
    run: ../../tools/linux-sort.cwl
    in:
      unsorted_file: merge_overlapped_a_and_b/merged_bed_file
      key:
        default: ["1,1","2,2n"]
    out:
      - sorted_file

  recenter_target_regions:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: target_regions
      param: recenter_target_regions
      script:
        default: |
          if [ "$1" == "TSS" ]
          then
            echo "Recenter target regions by TSS"
            # chrom  start  end  name  score strand
            cat "$0" | awk '{tss=$2; if ($6=="-") tss=$3; print $1"\t"tss"\t"tss"\t"$4"\t"$5"\t"$6}' > "recentered_by_tss_target_regions.bed"
          else
            echo "Skip recentering target regions"
            cat "$0" > "not_recentered_target_regions.bed"
          fi
    out:
      - output_file

  extend_recentered_target_regions:
    run: ../../tools/bedtools-slop.cwl
    in:
      bed_file: recenter_target_regions/output_file
      chrom_length_file: chrom_length_file
      bi_direction: max_distance
    out:
      - extended_bed_file

  get_unique_a_within_max_distance_from_target_regions:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: sort_unique_from_a/sorted_file
      file_b: extend_recentered_target_regions/extended_bed_file
      report_from_a_once:
        default: true
    out: [intersected_file]

  get_unique_b_within_max_distance_from_target_regions:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: sort_unique_from_b/sorted_file
      file_b: extend_recentered_target_regions/extended_bed_file
      report_from_a_once:
        default: true
    out: [intersected_file]

  get_merged_overlapped_a_and_b_within_max_distance_from_target_regions:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: sort_merged_overlapped_a_and_b/sorted_file
      file_b: extend_recentered_target_regions/extended_bed_file
      report_from_a_once:
        default: true
    out: [intersected_file]




  convert_to_xls_unique_a_within_max_distance_from_target_regions:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: get_unique_a_within_max_distance_from_target_regions/intersected_file
      script:
        default: >
          cat $0 | awk
          'BEGIN {print "chr\tstart\tend\tlength\tabs_summit\tpileup\t-log10(pvalue)\tfold_enrichment\t-log10(qvalue)\tname"}
          {print $1"\t"$2"\t"$3"\t"$3-$2+1"\t0\t0\t0\t0\t0\t0"}' > `basename $0`
    out: [output_file]

  annotate_unique_a_within_max_distance_from_target_regions:
      run: ../../tools/iaintersect.cwl
      in:
        input_filename: convert_to_xls_unique_a_within_max_distance_from_target_regions/output_file
        annotation_filename: annotation_file
        promoter_bp: annotate_dist
        upstream_bp:
          default: 100
        output_filename:
          default: "annotated_filtered_by_max_distance_unique_from_a.tsv"
      out: [result_file]

  filter_annotated_unique_a_within_max_distance_from_target_regions:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: annotate_unique_a_within_max_distance_from_target_regions/result_file
      script:
        default: >
          cat $0 | grep -v "intergenic" | awk
          '{print $6"\t"$7"\t"$8"\t"$2"\t"$1}' > `basename $0`
    out: [output_file]


  convert_to_xls_unique_b_within_max_distance_from_target_regions:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: get_unique_b_within_max_distance_from_target_regions/intersected_file
      script:
        default: >
          cat $0 | awk
          'BEGIN {print "chr\tstart\tend\tlength\tabs_summit\tpileup\t-log10(pvalue)\tfold_enrichment\t-log10(qvalue)\tname"}
          {print $1"\t"$2"\t"$3"\t"$3-$2+1"\t0\t0\t0\t0\t0\t0"}' > `basename $0`
    out: [output_file]

  annotate_unique_b_within_max_distance_from_target_regions:
      run: ../../tools/iaintersect.cwl
      in:
        input_filename: convert_to_xls_unique_b_within_max_distance_from_target_regions/output_file
        annotation_filename: annotation_file
        promoter_bp: annotate_dist
        upstream_bp:
          default: 100
        output_filename:
          default: "annotated_filtered_by_max_distance_unique_from_b.tsv"
      out: [result_file]

  filter_annotated_unique_b_within_max_distance_from_target_regions:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: annotate_unique_b_within_max_distance_from_target_regions/result_file
      script:
        default: >
          cat $0 | grep -v "intergenic" | awk
          '{print $6"\t"$7"\t"$8"\t"$2"\t"$1}' > `basename $0`
    out: [output_file]


  convert_to_xls_merged_overlapped_a_and_b_within_max_distance_from_target_regions:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: get_merged_overlapped_a_and_b_within_max_distance_from_target_regions/intersected_file
      script:
        default: >
          cat $0 | awk
          'BEGIN {print "chr\tstart\tend\tlength\tabs_summit\tpileup\t-log10(pvalue)\tfold_enrichment\t-log10(qvalue)\tname"}
          {print $1"\t"$2"\t"$3"\t"$3-$2+1"\t0\t0\t0\t0\t0\t0"}' > `basename $0`
    out: [output_file]

  annotate_merged_overlapped_a_and_b_within_max_distance_from_target_regions:
      run: ../../tools/iaintersect.cwl
      in:
        input_filename: convert_to_xls_merged_overlapped_a_and_b_within_max_distance_from_target_regions/output_file
        annotation_filename: annotation_file
        promoter_bp: annotate_dist
        upstream_bp:
          default: 100
        output_filename:
          default: "annotated_filtered_by_max_distance_merged_overlapped_a_and_b.tsv"
      out: [result_file]

  filter_annotated_merged_overlapped_a_and_b_within_max_distance_from_target_regions:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: annotate_merged_overlapped_a_and_b_within_max_distance_from_target_regions/result_file
      script:
        default: >
          cat $0 | grep -v "intergenic" | awk
          '{print $6"\t"$7"\t"$8"\t"$2"\t"$1}' > `basename $0`
    out: [output_file]




  get_rel_dist_distr_from_unique_a_to_target_regions:
    run: bedtools-reldist.cwl
    in:
      file_a: get_unique_a_within_max_distance_from_target_regions/intersected_file
      file_b: recenter_target_regions/output_file
      detailed_report:
        default: false
      output_filename:
        default: "rel_dist_distr_from_unique_a_to_target_regions.tsv"
    out:
      - relative_distance_distribution

  get_rel_dist_distr_from_unique_b_to_target_regions:
    run: bedtools-reldist.cwl
    in:
      file_a: get_unique_b_within_max_distance_from_target_regions/intersected_file
      file_b: recenter_target_regions/output_file
      detailed_report:
        default: false
      output_filename:
        default: "rel_dist_distr_from_unique_b_to_target_regions.tsv"
    out:
      - relative_distance_distribution

  get_rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions:
    run: bedtools-reldist.cwl
    in:
      file_a: get_merged_overlapped_a_and_b_within_max_distance_from_target_regions/intersected_file
      file_b: recenter_target_regions/output_file
      detailed_report:
        default: false
      output_filename:
        default: "rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions.tsv"
    out:
      - relative_distance_distribution

  plot_rel_dist_distr_from_unique_a_to_target_regions:
    run: plot_reldist_dist.cwl
    in:
      relative_distance_distribution: get_rel_dist_distr_from_unique_a_to_target_regions/relative_distance_distribution
      header:
        source: [regions_file_a_name, target_regions_name]
        valueFrom: $("From " + self[0] + " to " + self[1])
      output_filename:
        default: "rel_dist_distr_from_unique_a_to_target_regions.pdf"
    out:
      - relative_distance_distribution_plot

  plot_rel_dist_distr_from_unique_b_to_target_regions:
    run: plot_reldist_dist.cwl
    in:
      relative_distance_distribution: get_rel_dist_distr_from_unique_b_to_target_regions/relative_distance_distribution
      header:
        source: [regions_file_b_name, target_regions_name]
        valueFrom: $("From " + self[0] + " to " + self[1])
      output_filename:
        default: "rel_dist_distr_from_unique_b_to_target_regions.pdf"
    out:
      - relative_distance_distribution_plot

  plot_rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions:
    run: plot_reldist_dist.cwl
    in:
      relative_distance_distribution: get_rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions/relative_distance_distribution
      header:
        source: [regions_file_a_name, regions_file_b_name, target_regions_name]
        valueFrom: $("From merged overlapped " + self[0] + " and " + self[1] + " to " + self[2])
      output_filename:
        default: "rel_dist_distr_from_merged_overlapped_a_and_b_to_target_regions.pdf"
    out:
      - relative_distance_distribution_plot




  get_rel_dist_distr_from_target_regions_to_unique_a:
    run: bedtools-reldist.cwl
    in:
      file_a: recenter_target_regions/output_file
      file_b: get_unique_a_within_max_distance_from_target_regions/intersected_file
      detailed_report:
        default: false
      output_filename:
        default: "rel_dist_distr_from_target_regions_to_unique_a.tsv"
    out:
      - relative_distance_distribution

  get_rel_dist_distr_from_target_regions_to_unique_b:
    run: bedtools-reldist.cwl
    in:
      file_a: recenter_target_regions/output_file
      file_b: get_unique_b_within_max_distance_from_target_regions/intersected_file
      detailed_report:
        default: false
      output_filename:
        default: "rel_dist_distr_from_target_regions_to_unique_b.tsv"
    out:
      - relative_distance_distribution

  get_rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b:
    run: bedtools-reldist.cwl
    in:
      file_a: recenter_target_regions/output_file
      file_b: get_merged_overlapped_a_and_b_within_max_distance_from_target_regions/intersected_file
      detailed_report:
        default: false
      output_filename:
        default: "rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b.tsv"
    out:
      - relative_distance_distribution

  plot_rel_dist_distr_from_target_regions_to_unique_a:
    run: plot_reldist_dist.cwl
    in:
      relative_distance_distribution: get_rel_dist_distr_from_target_regions_to_unique_a/relative_distance_distribution
      header:
        source: [regions_file_a_name, target_regions_name]
        valueFrom: $("From " + self[1] + " to " + self[0])
      output_filename:
        default: "rel_dist_distr_from_target_regions_to_unique_a.pdf"
    out:
      - relative_distance_distribution_plot

  plot_rel_dist_distr_from_target_regions_to_unique_b:
    run: plot_reldist_dist.cwl
    in:
      relative_distance_distribution: get_rel_dist_distr_from_target_regions_to_unique_b/relative_distance_distribution
      header:
        source: [regions_file_b_name, target_regions_name]
        valueFrom: $("From " + self[1] + " to " + self[0])
      output_filename:
        default: "rel_dist_distr_from_target_regions_to_unique_b.pdf"
    out:
      - relative_distance_distribution_plot

  plot_rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b:
    run: plot_reldist_dist.cwl
    in:
      relative_distance_distribution: get_rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b/relative_distance_distribution
      header:
        source: [regions_file_a_name, regions_file_b_name, target_regions_name]
        valueFrom: $("From " + self[2] + " to merged overlapped " + self[0] + " and " + self[1])
      output_filename:
        default: "rel_dist_distr_from_target_regions_to_merged_overlapped_a_and_b.pdf"
    out:
      - relative_distance_distribution_plot




  get_rel_dist_from_target_regions_to_unique_a:
    run: bedtools-reldist.cwl
    in:
      file_a: recenter_target_regions/output_file
      file_b: get_unique_a_within_max_distance_from_target_regions/intersected_file
      detailed_report:
        default: true
      output_filename:
        default: "rel_dist_from_target_regions_to_unique_a.tsv"
    out:
      - relative_distance_distribution

  get_rel_dist_from_target_regions_to_unique_b:
    run: bedtools-reldist.cwl
    in:
      file_a: recenter_target_regions/output_file
      file_b: get_unique_b_within_max_distance_from_target_regions/intersected_file
      detailed_report:
        default: true
      output_filename:
        default: "rel_dist_from_target_regions_to_unique_b.tsv"
    out:
      - relative_distance_distribution

  get_rel_dist_from_target_regions_to_merged_overlapped_a_and_b:
    run: bedtools-reldist.cwl
    in:
      file_a: recenter_target_regions/output_file
      file_b: get_merged_overlapped_a_and_b_within_max_distance_from_target_regions/intersected_file
      detailed_report:
        default: true
      output_filename:
        default: "rel_dist_from_target_regions_to_merged_overlapped_a_and_b.tsv"
    out:
      - relative_distance_distribution

  plot_rel_dist_from_target_regions_to_unique_a:
    run: plot_reldist.cwl
    in:
      relative_distance: get_rel_dist_from_target_regions_to_unique_a/relative_distance_distribution
      header:
        source: [regions_file_a_name, target_regions_name]
        valueFrom: $("From " + self[1] + " to " + self[0])
      output_filename:
        default: "rel_dist_from_target_regions_to_unique_a.pdf"
    out:
      - relative_distance_plot

  plot_rel_dist_from_target_regions_to_unique_b:
    run: plot_reldist.cwl
    in:
      relative_distance: get_rel_dist_from_target_regions_to_unique_b/relative_distance_distribution
      header:
        source: [regions_file_b_name, target_regions_name]
        valueFrom: $("From " + self[1] + " to " + self[0])
      output_filename:
        default: "rel_dist_from_target_regions_to_unique_b.pdf"
    out:
      - relative_distance_plot

  plot_rel_dist_from_target_regions_to_merged_overlapped_a_and_b:
    run: plot_reldist.cwl
    in:
      relative_distance: get_rel_dist_from_target_regions_to_merged_overlapped_a_and_b/relative_distance_distribution
      header:
        source: [regions_file_a_name, regions_file_b_name, target_regions_name]
        valueFrom: $("From " + self[2] + " to merged overlapped " + self[0] + " and " + self[1])
      output_filename:
        default: "rel_dist_from_target_regions_to_merged_overlapped_a_and_b.pdf"
    out:
      - relative_distance_plot