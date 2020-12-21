cwlVersion: v1.0
class: Workflow

requirements:
 ScatterFeatureRequirement: {}

hints:
  - class: DockerRequirement
    dockerPull: haysb1991/altanalyze-test:version6

inputs: []

outputs: []

steps:
    step1:
      run: altanalyze_dbfetch.cwl
      in: []
      out: [stderr_log, stdout_log, database]

    step2:
      run: altanalyze_test.cwl
      in:
        data_in: step1/database
      out: [stderr_log, stdout_log]