cwlVersion: v1.0
class: Workflow


requirements:
  - class: StepInputExpressionRequirement
  - class: InlineJavascriptRequirement
  - class: MultipleInputFeatureRequirement


inputs:

  peaks_file:
    type: File

  annotation_file:
    type: File

  radius_from_tss:
    type: int

  chrom_length_file:
    type: File


outputs:

  peaks_within_a_certain_radius_from_tss:
    type: File
    outputSource: get_peaks_within_a_certain_radius_from_tss/intersected_file

  peaks_outside_of_a_certain_radius_from_tss:
    type: File
    outputSource: get_peaks_outside_of_a_certain_radius_from_tss/intersected_file


steps:

  dedup_and_sort_peaks:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: peaks_file
      script:
        default: |
          cat "$0" | tr -d '\r' | tr "," "\t" | cut -f 1-3 | sort -u -k1,1 -k2,2n -k3,3n > sorted_unique_peaks.bed
    out:
    - output_file

  recenter_genes_on_tss:
    run: ../../tools/custom-bash.cwl
    in:
      input_file: annotation_file
      script:
        default: |
          echo "Recenter genes by TSS"
          # bin	name	chrom	strand	txStart	txEnd	cdsStart	cdsEnd	exonCount	exonStarts	exonEnds	score	name2	cdsStartStat	cdsEndStat	exonFrames
          cat "$0" | grep -v "txStart" | awk '{tss=$5; if ($4=="-") tss=$6; print $3"\t"tss"\t"tss+1}' > "genes_tss.bed"
    out:
    - output_file

  extend_genes_tss:
    run: ../../tools/bedtools-slop.cwl
    in:
      bed_file: recenter_genes_on_tss/output_file
      chrom_length_file: chrom_length_file
      bi_direction: radius_from_tss
    out:
    - extended_bed_file

  get_peaks_within_a_certain_radius_from_tss:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: dedup_and_sort_peaks/output_file
      file_b: extend_genes_tss/extended_bed_file
      report_from_a_once:
        default: true
      output_filename:
        default: "peaks_within_a_certain_radius_from_tss.bed"
    out:
    - intersected_file

  get_peaks_outside_of_a_certain_radius_from_tss:
    run: ../../tools/bedtools-intersect.cwl
    in:
      file_a: dedup_and_sort_peaks/output_file
      file_b: extend_genes_tss/extended_bed_file
      no_overlaps:
        default: true
      output_filename:
        default: "peaks_outside_of_a_certain_radius_from_tss.bed"
    out:
    - intersected_file