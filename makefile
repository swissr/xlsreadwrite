###
### Makefile for xlsReadWrite
### - to be run in a cmd console (PowerShell/Terminator do not run atm
### - include.mk file modifies the system path!
###

include Rversion.mk 
include include.mk
$(info *************************************************)
$(info *   XLSREADWRITE MAKEFILE)
$(info *)
$(info *   R version $(R_VERSION) is being used)
$(info *)
$(info *   Path has been modified:)
$(info $(PATH))
$(info *************************************************)

# targets
.PHONY: check release push-release
.PHONY: check-reg build-reg release-reg
.PHONY: check-cran build-cran release-cran check-cran-final

# catch all, testing
all:
	@echo AUX_DEF: $(AUX_DEV)
	@echo "!! Select a specific target !!"


### reg - regular/pascal version ##############################################
### ('flags=<xy>' to optionally pass arguments for check and build) ###########
###############################################################################

check-reg: clean-gen populate-gen-reg
	@echo "### check-reg ###"
	@cd $(GEN) && $(RCMD) check --no-latex $(flags) $(PKG)
	@$(MAKE) $(W) clean-gen-src

build-reg: clean-gen populate-gen-reg $(GENDIR_GEN)
	@echo "### build-reg ###"
	# update COMMIT file
	@$(GIT) rev-parse HEAD > $(GEN)/$(PKG)/inst/COMMIT
ifneq (,$(findstring --allow-dirty,$(flags))) 
	@HASDIFF="`$(GIT) diff HEAD 2> $(NULL)`" && if (test "$$HASDIFF"); then echo "dirty" >> $(GEN)/$(PKG)/inst/COMMIT; fi
else
	@HASDIFF="`$(GIT) diff HEAD 2> $(NULL)`" && if (test "$$HASDIFF"); then echo "!!! workspace is not clean (commit changes or use 'flags=--allow-dirty')" && exit 1; fi
endif
	# src
	@cd $(GEN) && $(RCMD) build $(PKG)
	@mv $(GEN)/$(PKG)_$(PKG_VERSION).tar.gz $(GEN)/src/$(PKG)_$(PKG_VERSION).tar.gz
	# bin
	@cd $(GEN) && $(RCMD) build --auto-zip --binary $(PKG)
	@mv $(GEN)/$(PKG)_$(PKG_VERSION).zip $(GEN)/bin/$(PKG)_$(PKG_VERSION).zip
	# shlib
	$(MAKE) -C $(GEN)/$(PKG)/src -f Makevars
	@cd $(GEN)/$(PKG)/src && zip $(PKG)_$(PKG_VERSION)_$(DLL).zip $(PKG).$(DLL) >/dev/null
	@mv $(GEN)/$(PKG)/src/$(PKG)_$(PKG_VERSION)_$(DLL).zip $(GEN)/bin
	# src with shlib
	@mv $(GEN)/$(PKG)/src/$(PKG).$(DLL) $(GEN)/$(PKG)/inst/libs
	@rm -fr $(GEN)/$(PKG)/src
	@cd $(GEN) && $(RCMD) build $(PKG)
	@mv $(GEN)/$(PKG)_$(PKG_VERSION).tar.gz $(GEN)/bin/$(PKG)_$(PKG_VERSION).tar.gz 

release-reg: $(RELDIR_REL) build-reg
	@echo "### release-reg ###"
	# src
	@mv $(GEN)/src/$(PKG)_$(PKG_VERSION).tar.gz $(REL)/src
	@$(RSCRIPT) -e "library(tools);write(md5sum('$(REL)/src/$(PKG)_$(PKG_VERSION).tar.gz'), '$(REL)/src/$(PKG)_$(PKG_VERSION).tar.gz.md5.txt')"
	# bin
	@mv $(GEN)/bin/$(PKG)_$(PKG_VERSION).zip $(REL)/bin/$(OS_FOLDER)/$(R_MAJVER)
	@$(RSCRIPT) -e "library(tools);write(md5sum('$(REL)/bin/$(OS_FOLDER)/$(R_MAJVER)/$(PKG)_$(PKG_VERSION).zip'), '$(REL)/bin/$(OS_FOLDER)/$(R_MAJVER)/$(PKG)_$(PKG_VERSION).zip.md5.txt')"
	# shlib
	@mv $(GEN)/bin/$(PKG)_$(PKG_VERSION)_$(DLL).zip $(REL)/bin/$(OS_FOLDER)/shlib
	@$(RSCRIPT) -e "library(tools);write(md5sum('$(REL)/bin/$(OS_FOLDER)/shlib/$(PKG)_$(PKG_VERSION)_$(DLL).zip'), '$(REL)/bin/$(OS_FOLDER)/shlib/$(PKG)_$(PKG_VERSION)_$(DLL).zip.md5.txt')"
	# src with shlib
	@mv $(GEN)/bin/$(PKG)_$(PKG_VERSION).tar.gz $(REL)/bin/$(OS_FOLDER)/src
	@$(RSCRIPT) -e "library(tools);write(md5sum('$(REL)/bin/$(OS_FOLDER)/src/$(PKG)_$(PKG_VERSION).tar.gz'), '$(REL)/bin/$(OS_FOLDER)/src/$(PKG)_$(PKG_VERSION).tar.gz.md5.txt')"
	# update dropbox listing
	@cd $(REL) && echo -e "# Listing of SwissR' swissrpkg dropbox folder\n# URL root: http://dl.dropbox.com/u/2602516/swissrpkg\n# URL text listing: http://dl.dropbox.com/u/2602516/swissrpkg/listing.txt\n# URL html listing: http://dl.dropbox.com/u/2602516/swissrpkg/index.html\n# More info at: http://www.swissr.org\n" > listing.txt && ls -1rRp >> listing.txt 
	# generate html listing
	$(GENLISTEXE) $(REL)/listing.txt $(GENLIST)/index.html.template $(REL)/index.html


### cran - CRAN version #######################################################
### ('flags=<xy>' to optionally pass arguments for check and build) ###########
###############################################################################

check-cran: clean-gen populate-gen-cran
	@echo "### check-cran ###"
	@cd $(GEN) && $(RCMD) check --no-latex $(flags) $(PKG)
	@$(MAKE) $(W) clean-gen-src

build-cran: clean-gen populate-gen-cran $(GENDIR_GEN)
	@echo "### build-cran ###"
	# update COMMIT file
	@$(GIT) rev-parse HEAD > $(GEN)/$(PKG)/inst/COMMIT
ifneq (,$(findstring --allow-dirty,$(flags))) 
	@HASDIFF="`$(GIT) diff HEAD 2> $(NULL)`" && if (test "$$HASDIFF"); then echo "dirty" >> $(GEN)/$(PKG)/inst/COMMIT; fi
else
	@HASDIFF="`$(GIT) diff HEAD 2> $(NULL)`" && if (test "$$HASDIFF"); then echo "!!! workspace is not clean (commit changes or use '--allow-dirty' flag)" && exit 1; fi
endif
	# src
	@cd $(GEN) && $(RCMD) build $(PKG)
	@mv $(GEN)/$(PKG)_$(PKG_VERSION).tar.gz $(GEN)/src/$(PKG)_$(PKG_VERSION).tar.gz 
	# bin
	@cd $(GEN) && $(RCMD) build --auto-zip --binary $(PKG)
	@mv $(GEN)/$(PKG)_$(PKG_VERSION).zip $(GEN)/bin/$(PKG)_$(PKG_VERSION).zip

release-cran: $(RELDIR_REL) build-cran
	@echo "### release-cran ###"
	# src
	@mv $(GEN)/src/$(PKG)_$(PKG_VERSION).tar.gz $(REL)/cran/src
	@$(RSCRIPT) -e "library(tools);write(md5sum('$(REL)/cran/src/$(PKG)_$(PKG_VERSION).tar.gz'), '$(REL)/cran/src/$(PKG)_$(PKG_VERSION).tar.gz.md5.txt')"
	# bin
	@mv $(GEN)/bin/$(PKG)_$(PKG_VERSION).zip $(REL)/cran/$(OS_FOLDER)/$(R_MAJVER)
	@$(RSCRIPT) -e "library(tools);write(md5sum('$(REL)/cran/$(OS_FOLDER)/$(R_MAJVER)/$(PKG)_$(PKG_VERSION).zip'), '$(REL)/cran/$(OS_FOLDER)/$(R_MAJVER)/$(PKG)_$(PKG_VERSION).zip.md5.txt')"
	# update dropbox listing
	@cd $(REL) && echo -e "=== Swissr dropbox ===\n(add folder/files to http://dl.dropbox.com/u/2602516/swissrpkg)\n" > listing.txt && ls -1rRp >> listing.txt 
	# generate html listing
	$(GENLISTEXE) $(REL)/listing.txt $(GENLIST)/index.html.template $(REL)/index.html


### development and distribution targets ######################################
###############################################################################

.PHONY: test-dev rdconv singledocu-dev docu-dev shlib-c shlib-pas clean-dev

test-dev:
	@echo "### test-dev"
	@echo "does not work atm" && exit 1
	//@cd $(DEV)/__misc/debug && $(RSCRIPT) -e "source('../dynRunner/dynRunner.R');dynTests()"

rdconv:
	@$(RCMD) Rdconv -t $(TYPE) -o $(DEV)/man/out.$(TYPE) $(DEV)/man/$(FILE)

DOCUFILE=xls.oledatetime
# change here but revert afterwards to prevent git changes
DOCUFILE=xls.oledatetime
singledocu-dev:
	@echo "### singledocu-dev"
	@rm -f $(GEN)/$(PKG)/man/$(DOCUFILE).pdf
	@rm -f $(GEN)/$(PKG)/man/$(DOCUFILE).Rd
	@cp $(DEV)/man/$(DOCUFILE).Rd $(GEN)/$(PKG)/man/$(DOCUFILE).Rd
	@cd $(GEN)/$(PKG)/man && $(RCMD) Rd2pdf $(DOCUFILE).Rd
docu-dev: clean-gen populate-gen
	@echo "### docu-dev"
	@rm -f $(GEN)/xlsReadWrite.pdf
	@cd $(GEN) && $(RCMD) Rd2pdf $(PKG)

shlib-c:
	@echo "### c-dev"
	@cd $(DEV)/src/c && $(RCMD) SHLIB $(PKG).c
shlib-pas:
	@echo "### pas-dev"
	@$(MAKE) $(W) -C $(DEV)/src/pas -f Makevars
clean-dev:
	@echo "### clean-dev"
	@$(MAKE) $(W) -C $(DEV)/src/pas -f Makevars clean
	@rm -f $(DEV)/src/c/*.o $(DEV)/src/c/$(PKG).$(DLL) 

check-cran-final:
	@rm -fr $(DTEMP)/xlsReadWriteCranFinal
	@mkdir $(DTEMP)/xlsReadWriteCranFinal
	@cp $(REL)/cran/src/$(PKG)_$(PKG_VERSION).tar.gz $(DTEMP)/xlsReadWriteCranFinal
	@cd $(DTEMP)/xlsReadWriteCranFinal && $(RCMD) check --no-latex $(DTEMP)/xlsReadWriteCranFinal/$(PKG)_$(PKG_VERSION).tar.gz

push-release:
	@echo "### push-release ###"
	# commit files in $(REL)
	@HASDIFF="`cd "$(REL)" && $(GIT) diff HEAD 2> $(NULL)`" && if (test "$$HASDIFF"); then \
	cd "$(REL)" ;\
	$(GIT) add . ;\
	&& $(GIT) commit -m "Commit updated files";\
	else \
	echo "Already up-to-date." ;\
	fi
	# push $(REL) to redmine.swissr
	@pushexec
	@echo "In new console/process (to avoid 'unable to fork' error)"
	# update local dropbox from $(REL)
	@cd "$(DBOX)" && $(GIT) --git-dir=../../swissrpkg.git --work-tree=. pull origin
	@$(MAKE) $(W) check-cran-final


### combined & helper #########################################################
###############################################################################

check:
	$(MAKE) check-reg
	$(MAKE) check-cran
release:
	$(MAKE) release-reg
	$(MAKE) release-cran


.PHONY: clean-gen clean-gen-src populate-gen-reg populate-gen-cran populate-rel

clean-gen:
	@echo "### clean-gen"
	@rm -rf $(GEN)/*
clean-gen-src:
	@echo "### clean-gen-src"
	@rm -f $(GEN)/$(PKG)/src/*.$(DCU) $(GEN)/$(PKG)/src/*.o $(GEN)/$(PKG)/src/$(PKG).$(DLL) 

populate-gen-reg:
	@echo "### populate-gen-reg"
	# make folders
	@mkdir -p $(GENDIR)
	# copy non source file
	@cp --parents $(AUX_DEV) $(GEN)/$(PKG)
	@rm -f $(GEN)/$(PKG)/inst/unitTests/debug.R
	# copy source file
	@cp $(SRCPAS_DEV) $(GEN)/$(PKG)/src/
	@cp $(SRCRPAS_DEV) $(GEN)/$(PKG)/src/

populate-gen-cran:
	@echo "### populate-gen-reg"
	# make folders
	@mkdir -p $(GENDIR)
	# copy non source file
	@cp --parents $(AUX_DEV) $(GEN)/$(PKG)
	@rm -f $(GEN)/$(PKG)/inst/unitTests/debug.R
	# copy source file
	@cp $(SRCC_DEV) $(GEN)/$(PKG)/src/

populate-rel:
	@echo "### populate-rel"
	# make folders
	@mkdir -p $(RELDIR)