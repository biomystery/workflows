cwlVersion: v1.0
class: Workflow


requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement


inputs:

  regions_files_a:
    type: File[]

  regions_files_b:
    type: File[]

  diff_regions_file_a:
    type: File
  
  diff_regions_file_b:
    type: File

  min_signal_regions_a:
    type: string

  min_signal_regions_b:
    type: string

  genome_fasta_file:
    type: File

  motifs_db:
    type:
      - "null"
      - type: enum
        symbols: ["vertebrates", "insects", "worms", "plants", "yeast", "all"]

  chopify_background_regions:
    type: boolean

  apply_mask_on_genome:
    type: boolean

  skip_denovo:
    type: boolean

  skip_known:
    type: boolean

  use_hypergeometric:
    type: boolean
  
  search_size:
    type: string

  motif_length:
    type: string

  threads:
    type: int


outputs:

  concatenated_sorted_unique_regions_from_a:
    type: File
    outputSource: concat_dedup_and_sort_regions_a/output_file

  concatenated_sorted_unique_regions_from_b:
    type: File
    outputSource: concat_dedup_and_sort_regions_b/output_file

  concatenated_sorted_unique_regions_from_a_overlapped_with_diff:
    type: File
    outputSource: get_overlapped_with_diff_regions_a/intersected_file

  concatenated_sorted_unique_regions_from_b_overlapped_with_diff:
    type: File
    outputSource: get_overlapped_with_diff_regions_b/intersected_file

  merged_overlapped_with_diff_concatenated_sorted_unique_regions_from_a:
    type: File
    outputSource: merge_overlapped_with_diff_regions_a/merged_bed_file

  merged_overlapped_with_diff_concatenated_sorted_unique_regions_from_b:
    type: File
    outputSource: merge_overlapped_with_diff_regions_b/merged_bed_file

  sorted_unique_diff_regions_from_a:
    type: File
    outputSource: dedup_and_sort_diff_regions_a/output_file

  sorted_unique_diff_regions_from_b:
    type: File
    outputSource: dedup_and_sort_diff_regions_b/output_file

  homer_found_motifs:
    type: File
    outputSource: find_motifs/compressed_results_folder

  homer_known_motifs:
    type: File?
    outputSource: find_motifs/known_motifs

  homer_denovo_motifs:
    type: File?
    outputSource: find_motifs/denovo_motifs

  homer_stdout_log:
    type: File
    outputSource: find_motifs/stdout_log

  homer_stderr_log:
    type: File
    outputSource: find_motifs/stderr_log


steps:

  dedup_and_sort_diff_regions_a:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: diff_regions_file_a
      script:
        default: |
          cat "$0" | tr -d '\r' | tr "," "\t" | awk NF | sort -u -k1,1 -k2,2n -k3,3n | awk '{print $1"\t"$2"\t"$3"\tp"NR"\t"$5"\t"$6}' > sorted_unique_diff_regions_from_a.bed
    out:
      - output_file

  dedup_and_sort_diff_regions_b:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: diff_regions_file_b
      script:
        default: |
          cat "$0" | tr -d '\r' | tr "," "\t" | awk NF | sort -u -k1,1 -k2,2n -k3,3n | awk '{print $1"\t"$2"\t"$3"\tp"NR"\t"$5"\t"$6}' > sorted_unique_diff_regions_from_b.bed
    out:
      - output_file

  concat_dedup_and_sort_regions_a:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: regions_files_a
      param: min_signal_regions_a
      script:
        default: |
          set -- "$0" "$@"
          echo "files: " "${@:1:$#-1}"
          TH="${@: -1}"
          echo "Threashold" "$TH"
          cat "${@:1:$#-1}" | tr -d '\r' | tr "," "\t" | awk NF | awk -v th=$TH '{if ($7 >= th) print $0}' | sort -u -k1,1 -k2,2n -k3,3n | awk '{print $1"\t"$2"\t"$3"\tp"NR"\t"$5"\t"$6}' > concatenated_sorted_unique_regions_from_a.bed
    out:
      - output_file

  concat_dedup_and_sort_regions_b:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: regions_files_b
      param: min_signal_regions_b
      script:
        default: |
          set -- "$0" "$@"
          echo "files: " "${@:1:$#-1}"
          TH="${@: -1}"
          echo "Threashold" "$TH"
          cat "${@:1:$#-1}" | tr -d '\r' | tr "," "\t" | awk NF | awk -v th=$TH '{if ($7 >= th) print $0}' | sort -u -k1,1 -k2,2n -k3,3n | awk '{print $1"\t"$2"\t"$3"\tp"NR"\t"$5"\t"$6}' > concatenated_sorted_unique_regions_from_b.bed
    out:
      - output_file

  get_overlapped_with_diff_regions_a:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: concat_dedup_and_sort_regions_a/output_file
      file_b: dedup_and_sort_diff_regions_a/output_file
      report_from_a_once:
        default: true
      output_filename:
        default: "concatenated_sorted_unique_regions_from_a_overlapped_with_diff.bed"
    out: [intersected_file]

  get_overlapped_with_diff_regions_b:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: concat_dedup_and_sort_regions_b/output_file
      file_b: dedup_and_sort_diff_regions_b/output_file
      report_from_a_once:
        default: true
      output_filename:
        default: "concatenated_sorted_unique_regions_from_b_overlapped_with_diff.bed"
    out: [intersected_file]

  merge_overlapped_with_diff_regions_a:
    run: ../../tools/bedtools-merge.cwl
    in:
      bed_file: get_overlapped_with_diff_regions_a/intersected_file
      output_filename:
        default: "merged_overlapped_with_diff_concatenated_sorted_unique_regions_from_a.bed"
    out: [merged_bed_file]
  
  merge_overlapped_with_diff_regions_b:
    run: ../../tools/bedtools-merge.cwl
    in:
      bed_file: get_overlapped_with_diff_regions_b/intersected_file
      output_filename:
        default: "merged_overlapped_with_diff_concatenated_sorted_unique_regions_from_b.bed"
    out: [merged_bed_file]

  find_motifs:
    run: ../../tools/homer-find-motifs-genome.cwl
    in:
      target_regions_file: merge_overlapped_with_diff_regions_a/merged_bed_file
      background_regions_file: merge_overlapped_with_diff_regions_b/merged_bed_file
      genome_fasta_file: genome_fasta_file
      chopify_background_regions: chopify_background_regions
      search_size: search_size
      motif_length: motif_length
      apply_mask_on_genome: apply_mask_on_genome
      use_hypergeometric: use_hypergeometric
      skip_denovo: skip_denovo
      skip_known: skip_known
      motifs_db: motifs_db
      threads: threads
    out:
      - compressed_results_folder
      - known_motifs
      - denovo_motifs
      - stdout_log
      - stderr_log