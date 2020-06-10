.PHONY: always
txt/all_hc.csv:  .make/specturm.ls
	./gen_csv.R

.make/pdf.ls:  .make/specturm.ls | .make
	./gen_pdf.bash
	mkls $@ pdfs 

.make/specturm.ls: always | .make
	# N.B. probably need to manually unzip HPC data
	mkls $@ /Volumes/Hera/Raw/MRprojects/7TBrainMech/MRSI_BrainMechR01/HPC/*/

.make:
	@-mkdir $@

