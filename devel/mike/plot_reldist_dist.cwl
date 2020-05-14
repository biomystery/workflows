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
      raw_data = pd.read_table(raw_data_file, index_col=0, sep="\t")
      raw_data.plot(y="fraction", marker='o', legend=False)
      plt.title("Relative Distance Distribution")
      plt.suptitle(header)
      plt.ylabel("Frequency")
      plt.xlabel("Relative distance")
      plt.ylim(bottom=0)
      plt.xlim(left=0, right=0.55)
      plt.savefig(output_file, bbox_inches="tight")
      plt.close("all")
    inputBinding:
      position: 5
    doc: "Python script to plot relative distance distribution"

  relative_distance_distribution:
    type: File
    inputBinding:
      position: 6
    doc: "Relative distance distribution file from bedtools reldist"

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

  relative_distance_distribution_plot:
    type: File
    outputBinding:
      glob: "*"

baseCommand: ["python", "-c"]