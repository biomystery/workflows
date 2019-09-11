cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: ShellCommandRequirement
- class: InlineJavascriptRequirement
  expressionLib:
  - var get_output_filename = function() {
        if (inputs.output_filename) {
          return inputs.output_filename;
        }
        var root = inputs.bam_statistics_report.basename.split('.').slice(0,-1).join('.');
        var ext = "_collected_statistics_report.txt";
        return (root == "")?inputs.bam_statistics_report.basename+ext:root+ext;
    };


hints:
- class: DockerRequirement
  dockerPull: biowardrobe2/scidap:v0.0.3


inputs:

  script:
    type: string?
    default: |
      #!/usr/bin/env python
      import sys, re

      collected_results = []

      def get_value(l):
          return l.split(":")[1].strip().split()[0]

      collected_results.append(["#", "Adapter trimming statistics"])

      with open(sys.argv[1], 'r') as s:
          for l in s:
              if "Total reads processed" in l:
                  collected_results.append( [ "Total reads processed (FASTQ1):", get_value(l) ] )
              if "Reads with adapters" in l:
                  collected_results.append( [ "Reads with adapters (FASTQ1):",   get_value(l) ] )
              if "Reads written (passing filters)" in l:
                  collected_results.append( [ "Reads passing filters (FASTQ1):", get_value(l) ] )

      with open(sys.argv[2], 'r') as s:
          for l in s:
              if "Total reads processed" in l:
                  collected_results.append( [ "Total reads processed (FASTQ2):",    get_value(l) ] )
              if "Reads with adapters" in l:
                  collected_results.append( [ "Reads with adapters (FASTQ2):",      get_value(l) ] )
              if "Reads written (passing filters)" in l:
                  collected_results.append( ["Reads passing filters (FASTQ2):",     get_value(l) ] )
              if "Number of sequence pairs removed" in l:
                  collected_results.append( ["Number of sequence pairs removed:", get_value(l) ] )

      collected_results.append(["#", "BAM statistics"])

      with open(sys.argv[3], 'r') as s:
          for l in s:
              if "SN\traw total sequences:" in l:
                  collected_results.append( [ "Raw total sequences:", get_value(l) ] )
              if "SN\t1st fragments:" in l:
                  collected_results.append( [ "1st fragments:",       get_value(l) ] )
              if "SN\tlast fragments:" in l:
                  collected_results.append( [ "Last fragments:",      get_value(l) ] )
              if "SN\treads mapped:" in l:
                  collected_results.append( [ "Reads mapped:",        get_value(l) ] )
              if "SN\taverage length:" in l:
                  collected_results.append( [ "Average length:",      get_value(l) ] )
              if "SN\tmaximum length:" in l:
                  collected_results.append( [ "Maximum length:",      get_value(l) ] )
              if "SN\taverage quality:" in l:
                  collected_results.append( [ "Average quality:",     get_value(l) ] )
              if "SN\tinsert size average:" in l:
                  collected_results.append( [ "Insert size average:", get_value(l) ] )
              if "SN\tinsert size standard deviation:" in l:
                  collected_results.append( [ "Insert size standard deviation", get_value(l) ] )
        
      with open(sys.argv[4], 'r') as s:
          for l in s:
              if "aligned concordantly exactly 1 time" in l:
                  collected_results.append( [ "Aligned concordantly exactly 1 time:", l.split()[0].strip() ] )

      collected_results.append(["#", "BAM statistics after quality and duplicate filtering"])

      with open(sys.argv[5], 'r') as s:
          for l in s:
              if "SN\traw total sequences:" in l:
                  collected_results.append( [ "Raw total sequences:", get_value(l) ] )
              if "SN\t1st fragments:" in l:
                  collected_results.append( [ "1st fragments:",       get_value(l) ] )
              if "SN\tlast fragments:" in l:
                  collected_results.append( [ "Last fragments:",      get_value(l) ] )
              if "SN\treads mapped:" in l:
                  collected_results.append( [ "Reads mapped:",        get_value(l) ] )
              if "SN\taverage length:" in l:
                  collected_results.append( [ "Average length:",      get_value(l) ] )
              if "SN\tmaximum length:" in l:
                  collected_results.append( [ "Maximum length:",      get_value(l) ] )
              if "SN\taverage quality:" in l:
                  collected_results.append( [ "Average quality:",     get_value(l) ] )
              if "SN\tinsert size average:" in l:
                  collected_results.append( [ "Insert size average:", get_value(l) ] )
              if "SN\tinsert size standard deviation:" in l:
                  collected_results.append( [ "Insert size standard deviation:", get_value(l) ] )


      collected_results.append(["#", "Blacklisted regions filtering"])
      collected_results.append( [ "Reads after blackisted regions removal:", str(len(open(sys.argv[6]).readlines())) ] )

      collected_results.append(["#", "Peak calling"])
      collected_results.append( [ "Number of peaks called:", str(len(open(sys.argv[7]).readlines())) ] )
      collected_results.append( [ "Number of peaks after merging:", str(len(open(sys.argv[8]).readlines())) ] )


      with open(sys.argv[9], 'w') as fstream:
          for i in collected_results:
              fstream.write("\t".join(i)+"\n")
    inputBinding:
      position: 5

  trimgalore_report_fastq_1:
    type: File
    inputBinding:
      position: 6

  trimgalore_report_fastq_2:
    type: File
    inputBinding:
      position: 7

  bam_statistics_report:
    type: File
    inputBinding:
      position: 8

  bowtie_alignment_report:
    type: File
    inputBinding:
      position: 9

  bam_statistics_report_after_filtering:
    type: File
    inputBinding:
      position: 10

  reads_after_removal_blacklisted:
    type: File
    inputBinding:
      position: 11

  peaks_called:
    type: File
    inputBinding:
      position: 12

  peaks_merged:
    type: File
    inputBinding:
      position: 13

  output_filename:
    type: string?
    inputBinding:
      position: 14
      valueFrom: $(get_output_filename())
    default: ""


outputs:

  collected_statistics:
    type: File
    outputBinding:
      glob: $(get_output_filename())


baseCommand: [python, '-c']