To run these tools:

cwltool --no-match-user --no-read-only altanalyze_dbfetch.cwl input_fetch.json
cwltool --no-match-user --no-read-only altanalyze_test.cwl input_run.json

You should have CWL installed already on your computer. If you do not, you can use either of the following commands:

pip install cwlref-runner
pip install cwltool

You should then be able to run the scripts. All output will appear in the folder where you execute the cwl tools. Logs and errors for the database fetching step will have the prefix "aadbfetch", while logs and errors for the altanalyze testing step will have the prefix "aatest".