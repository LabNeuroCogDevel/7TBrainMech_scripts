.PHONY: install test

test:    .make/test
install: .make/install

.make/install: R/*.R | .make
	Rscript -e "devtools::document(); devtools::install('./')" | tee $@

.make/test: tests/testthat/*.R R/*.R install | .make
	cd tests/ && Rscript "testthat.R" | tee ../$@

.make:
	@mkdir .make
