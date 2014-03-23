#TODO 1 implement distall target

	# This file shall be sourced here. It should only contain project specific versions of the param
PARAMS_FILE 		:= Makefile_params
PARAMS_FILE_LOCAL	:= Makefile_params_local

-include $(PARAMS_FILE)
-include $(PARAMS_FILE_LOCAL)

	# Extension of input files:
IN_EXTS   	:= .tex .md
IN_DIR   	?= src/
	# Dir where output files such as .pdf will be put. slash terminated:
BUILD_DIR  	?= _build/
	# Dir where auxiliary files such as `.out` will be put. slash terminated.
	# TODO 1 get this to work for a different dir than BUILD_DIR. The problem is that synctex won't allow this!
	#AUX_DIR  	?= _aux/
AUX_DIR  	?= $(BUILD_DIR)
DIST_DIR  	?= _dist/
	# Extension of output:
OUT_EXT 	:= .pdf

VIEW		?= index.pdf
LINE		?= 1
PAGE		?=
VIEWER 		?= okular --unique -p $$PAGE "$(VIEW_PATH)"

TAG 				?= $(shell git tag --contains HEAD | sort | head -n1 )
TAG_DEFAULT			?= latest
ifeq ($(strip $(TAG)),)
	TAG := $(TAG_DEFAULT)
endif
PROJECT_NAME		?= $(shell basename `pwd`)
FTP_HOST 			?=
FTP_USER 			?=
REMOTE_SUBDIR_PREF 	?=
REMOTE_SUBDIR 		?= $(REMOTE_SUBDIR_PREF)$(PROJECT_NAME)/$(TAG)

	# Name or root directory inside of the zip:
IN_ZIP_NAME 		?= $(PROJECT_NAME)-$(TAG)

CC_LATEX 	?= env "TEXINPUTS=./media//:./media-gen/out//:" pdflatex -output-directory "$(AUX_DIR)"
INTERACT 	?= 0
ifeq ($(INTERACT),1)
	CC_LATEX_INTERACTION :=
else
	CC_LATEX_INTERACTION := -interaction=nonstopmode
endif
CC_MD	 	?= pandoc -s --toc --mathml -N

MEDIA_GEN_DIR ?= ./media-gen/

ERASE_MSG 	:= 'Dont put anything important in those directories since `make clean` erases them!'

INS			:= $(foreach IN_EXT, $(IN_EXTS), $(wildcard $(IN_DIR)*$(IN_EXT)))
INS_NODIR 	:= $(notdir $(INS))
OUTS_NODIR	:= $(addsuffix $(OUT_EXT), $(basename $(INS_NODIR)))
OUTS		:= $(addprefix $(BUILD_DIR), $(OUTS_NODIR))

STYS		:= $(wildcard *.sty)
BIBS		:= $(wildcard *.bib)

VIEW_PATH := $(shell echo `pwd`/$(BUILD_DIR)$$(echo -n $(VIEW) | sed -r "s|$$(pwd)/$(IN_DIR)(.*)\.[^.]*|\1$(OUT_EXT)|"))

# Remove automatic rules:
.SUFFIXES:

.PHONY: all clean help install-deps-ubuntu media-gen mkdir upload_output view

all: media-gen mkdir $(OUTS) rm-empty
	@if [ $(MAKELEVEL) -eq 0 ]; then for IN_DIR in `find $(IN_DIR) ! -path $(IN_DIR) -type d`; do $(MAKE) IN_DIR="$$IN_DIR/" BUILD_DIR="$(BUILD_DIR)$${IN_DIR#$(IN_DIR)}/"; done; fi
	@#echo 'Auxiliary files put into: $(AUX_DIR)'
	@#echo 'Output    files put into: $(BUILD_DIR)'
	@#echo $(ERASE_MSG)

#$(STYS) $(BIBS) are here so that if any include files are modified, make again:
$(BUILD_DIR)%$(OUT_EXT): $(IN_DIR)%.tex $(STYS) $(BIBS)
	@# Make PDF with bibtex and synctex:
	@$(CC_LATEX) $(CC_LATEX_INTERACTION) "$<" | perl -0777 -ne 'print m/\n! .*?\nl\.\d.*?\n.*?(?=\n)/gs'
	@# Allowing for error here in case tex has no bib files:
	@-bibtex "$(AUX_DIR)$*" >/dev/null
	@$(CC_LATEX) -interaction=nonstopmode "$<" >/dev/null
	@$(CC_LATEX) -interaction=nonstopmode -synctex=1 "$<" >/dev/null
	@# Move output to out dir if they are different:
	@if [ ! $(AUX_DIR) = $(BUILD_DIR) ]; then mv -f $(AUX_DIR)$*$(OUT_EXT) "$(BUILD_DIR)"; fi

$(BUILD_DIR)%$(OUT_EXT): $(IN_DIR)%.md
	@$(CC_MD) -o "$@" "$<"

clean: distclean
	@rm -rf $(BUILD_DIR) $(AUX_DIR)
	@find $(IN_DIR) -type f \( \
		-iname '*.aux' -o -iname '*.glo' -o -iname '*.idx' -o -iname '*.log' -o -iname '*.toc' -o \
		-iname '*.ist' -o -iname '*.acn' -o -iname '*.acr' -o -iname '*.alg' -o -iname '*.bbl' -o \
		-iname '*.blg' -o -iname '*.dvi' -o -iname '*.glg' -o -iname '*.gls' -o -iname '*.ilg' -o \
		-iname '*.ind' -o -iname '*.lof' -o -iname '*.lot' -o -iname '*.maf' -o -iname '*.mtc' -o \
		-iname '*.out' -o -iname '*.pdf' -o \
		-iname '*.mtc1' -o -iname '*.synctex.gz' -o -iname '*.ps' \) \
		-delete
	@if [ -f $(MEDIA_GEN_DIR)makefile ]; then \
	   make -C $(MEDIA_GEN_DIR) clean	;\
	fi
	@#echo "Removed output files by extension in: $(IN_DIR)"
	@#echo "Removed dirs: $(BUILD_DIR) $(AUX_DIR)"

# Generate distribution, for ex: dir with PDFs or zip with HTML.
dist: all
ifeq ($(strip $(TAG)),)
	@echo 'ERROR: TAG is currently empty. First give a tag to the current repo with `git tag`'
	@exit 1
endif
	@mkdir -p "$(DIST_DIR)/$(TAG)/pdf/"
	@cp -lr "$(BUILD_DIR)"* "$(DIST_DIR)/$(TAG)/pdf/"
	@cd "$(DIST_DIR)/$(TAG)" &&\
	@find "pdf" -type f ! -iname "*$(OUT_EXT)" -delete &&\
	@mv pdf "$(IN_ZIP_NAME)-pdf" &&\
	@zip -r "pdf.zip" "$(IN_ZIP_NAME)-pdf" &&\
	@mv "$(IN_ZIP_NAME)-pdf" pdf
	@#echo 'Dist files were be put into: $(DIST_DIR)'
	@#echo $(ERASE_MSG)

# Clean only the dist.
distclean:
	@rm -rf $(DIST_DIR)

# - remove any directory with the same name as the uploaded tag directory
# - upload
# 
# Only files with the OUT_EXT will be kept in the output.
# 
# Will attempt to upload the current tag only.
distup: dist
	@cd $(DIST_DIR) && lftp -c "open -u $(FTP_USER) $(FTP_HOST) && rm -rf \"$(REMOTE_SUBDIR)\"; mkdir -p \"$(REMOTE_SUBDIR)\" && mirror -R \"$(TAG)\" \"$(REMOTE_SUBDIR)\""
	#TODO 0 prevent rm -rf from failing if dir does not exist, this forces us to use `;` instead of &&
	#the desired command would be:
	#cd $(DIST_DIR) && lftp -c "open -u $(FTP_USER) $(FTP_HOST) && rm -rf \"$(REMOTE_SUBDIR)\" && mkdir -p \"$(REMOTE_SUBDIR)\" && mirror -R \"$(TAG)\" \"$(REMOTE_SUBDIR)\""
	#cd $(DIST_DIR) && lftp -c "open -u $(FTP_USER) $(FTP_HOST) && mkdir -p \"$(REMOTE_SUBDIR)\" && mirror --delete-first -R \"$(TAG)\" \"$(REMOTE_SUBDIR)\""

# Makes and uploads all tags.
#
# Useful when you want to move dist files to a new server.
distall: dist

distupall: dist distup

help:
	@echo 'See the shared/README.md "Make targets" section for full documentation.'
	@echo ''
	@echo 'all .................. Default target. Build PDF output.'
	@echo ''
	@echo 'clean ................ Remove all compiled outputs.'
	@echo ''
	@echo 'dist ................. Build output for distribution. Implies `all`'
	@echo ''
	@echo 'distup ............... Upload built dist output via FTP. Configured by FTP_HOST and FTP_USER. Implies `dist`.'
	@echo ''
	@echo 'install-deps-ubuntu .. Install missing dependencies on a clean Ubuntu 12.04.'
	@echo ''
	@echo 'media-gen ............ Build media under media-gen.'
	@echo ''
	@echo 'view ................. Open compiled output in a viewer. Configured by VIEWER, VIEW and LINE. Implies `all`.'

install-deps-ubuntu:
	@sudo apt-get install -y aptitude
	@sudo aptitude install -y texlive-full
	@sudo aptitude install -y pandoc
	@sudo aptitude install -y okular
	@sudo aptitude install -y lftp

# Generate media generated programtically.
media-gen:
	@if [ -d "$(MEDIA_GEN)" ]; then make -C "$(MEDIA_GEN_DIR)"; fi

mkdir:
	@mkdir -p "$(AUX_DIR)"
	@mkdir -p "$(BUILD_DIR)"
	@#echo "Made dirs: $(BUILD_DIR) $(AUX_DIR)"
	@#echo $(ERASE_MSG)

rm-empty:
	@find $(BUILD_DIR) -depth -type d -exec rmdir {} \; 2>/dev/null

view: all
	@( \
		if [ -z "$(PAGE)" ]; then \
			SYNCTEX_OUT="`synctex view -i "$(LINE):1:$(VIEW)" -o "$(VIEW_PATH)"`" ;\
			PAGE="`echo "$$SYNCTEX_OUT" | awk -F: '$$1 ~/Page/ { print $$2; exit }'`" ;\
			if [ -z "$$PAGE" ]; then \
				PAGE="1" ;\
			fi ;\
		fi ;\
		nohup $(VIEWER) >/dev/null & \
	)
