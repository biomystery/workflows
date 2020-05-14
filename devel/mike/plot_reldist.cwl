cwlVersion: v1.0
class: CommandLineTool


requirements:
- class: InlineJavascriptRequirement


hints:
- class: DockerRequirement
  dockerPull: quansight/matplotlib_pandas:v3


inputs:
  
  script:
    type: string?
    default: |
      #!/usr/bin/env python
      import os
      import sys
      import pandas as pd
      import matplotlib.pyplot as plt
      raw_data_file = sys.argv[1]
      header = sys.argv[2]
      output_file = sys.argv[3]
      plt.style.use("ggplot")
      plt.rc("xtick", labelsize=4)
      raw_data = pd.read_table(raw_data_file, index_col=3, names=["chr", "start", "end", "reldist"], sep="\t")
      raw_data.plot(y="reldist", legend=False)
      plt.title("Relative Distance")
      plt.suptitle(header)
      plt.ylabel("Relative Distance")
      plt.xlabel("Gene")
      plt.ylim(bottom=0)
      plt.xticks(range(len(raw_data.index)), raw_data.index, rotation=90)
      plt.savefig(output_file, bbox_inches="tight")
      plt.close("all")
    inputBinding:
      position: 5
    doc: "Python script to plot relative distance"

  relative_distance:
    type: File
    inputBinding:
      position: 6
    doc: "Relative distance file from bedtools reldist -detail"

  header:
    type: string
    inputBinding:
      position: 7
    doc: "Header/Title of the plot"

  output_filename:
    type: string
    inputBinding:
      position: 8
    doc: "Output filename for generated plot"


outputs:

  relative_distance_plot:
    type: File
    outputBinding:
      glob: "*"

baseCommand: ["python", "-c"]