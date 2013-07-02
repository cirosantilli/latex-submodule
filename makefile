##TODO
#
#- 1 handle case in which repo has no tags

	#this file shall be sourced here. It should only contain project specific versions of the param
PARAMS_FILE 		:= makefile-params
PARAMS_FILE_PRIVATE	:= makefile-params-private

-include $(PARAMS_FILE)
-include $(PARAMS_FILE_PRIVATE)

	#extension of input files:
IN_EXTS   	?= .tex .md
	#directory from which input files come. slash termianted:
IN_DIR   	?= ./src/

	#dir where output files such as .pdf will be put. slash terminated:
OUT_DIR  	?= _out/
	#dir where auxiliary files such as `.out` will be put. slash terminated.
	#TODO 1 get this to work for a different dir than OUT_DIR. The problem is that synctex won't allow this!
#override AUX_DIR  	?= _aux/
AUX_DIR  	?= $(OUT_DIR)
DIST_DIR  	?= _dist/

	#extension of output:
OUT_EXT 	?= .pdf

	#basename without extension of file to view:
VIEW		?= index
	#uses synctex to go to the page corresponding to the given line.
LINE		?= 1
	#viewer command used to view the output.
	#$$PAGE is a bash variable that contains the page to open the document at. It is typically calculated by synctex in this makefile.
VIEWER 	?= okular --unique -p $$PAGE
	#default upload tag, name of directory under which zip file will go
TAG 					?= $(shell git describe --abbrev=0 --tags)
PROJECT_NAME			?= $(shell basename `pwd`)
FTP_HOST 				?=
FTP_USER 				?=
REMOTE_SUBDIR_PREF 		?=
REMOTE_SUBDIR 			?= $(REMOTE_SUBDIR_PREF)$(PROJECT_NAME)/$(TAG)
	#name or root directory inside of the zip
IN_ZIP_NAME 	?= $(PROJECT_NAME)-$(TAG)

	#compile command
CC_LATEX 		?= env "TEXINPUTS=./media//:./media-gen/out//:" pdflatex -interaction=nonstopmode -output-directory "$(AUX_DIR)"
CC_MD	 		?= pandoc -s --toc --mathml -N

MEDIA_GEN_DIR ?= ./media-gen/

ERASE_MSG := 'DONT PUT ANYTHING IMPORTANT IN THOSE DIRECTORIES SINCE `make clean` ERASES THEM!!!'

INS			:= $(foreach IN_EXT, $(IN_EXTS), $(wildcard $(IN_DIR)*$(IN_EXT)))
INS_NODIR 	:= $(notdir $(INS))
OUTS_NODIR	:= $(addsuffix $(OUT_EXT), $(basename $(INS_NODIR)))
OUTS		:= $(addprefix $(OUT_DIR), $(OUTS_NODIR))

STYS		:= $(wildcard *.sty)
BIBS		:= $(wildcard *.bib)

	#path of tex file to be viewed (needed by synctex):
VIEW_TEX_PATH	:= $(IN_DIR)$(VIEW)$(IN_EXT)
	#path of output file to be viewed:
VIEW_OUT_PATH	:= $(OUT_DIR)$(VIEW)$(OUT_EXT)

#remove automatic rules:
.SUFFIXES:

.PHONY: all clean help install-deps-ubuntu media-gen mkdir upload_output view

all: media-gen mkdir $(OUTS)
	if [ $(MAKELEVEL) -eq 0 ]; then for IN_DIR in `find $(IN_DIR) ! -path $(IN_DIR) -type d`; do $(MAKE) IN_DIR="$$IN_DIR/" OUT_DIR="$(OUT_DIR)$${IN_DIR#$(IN_DIR)}/"; done; fi
	@echo 'AUXILIARY FILES WERE PUT INTO:    $(AUX_DIR)'
	@echo 'OUTPUT    FILES WERE BE PUT INTO: $(OUT_DIR)'
	@echo $(ERASE_MSG)

#$(STYS) $(BIBS) are here so that if any include files are modified, make again:
$(OUT_DIR)%$(OUT_EXT): $(IN_DIR)%.tex $(STYS) $(BIBS)
	#make pdf with bibtex and synctex:
	$(CC_LATEX) "$<"
	#allowing for error here in case tex has no bib files:
	-bibtex "$(AUX_DIR)$*"
	$(CC_LATEX) "$<"
	$(CC_LATEX) -synctex=1 "$<"
	#move output to out dir if they are different:
	if [ ! $(AUX_DIR) = $(OUT_DIR) ]; then mv -f $(AUX_DIR)$*$(OUT_EXT) "$(OUT_DIR)"; fi

$(OUT_DIR)%$(OUT_EXT): $(IN_DIR)%.md
	$(CC_MD) -o "$@" "$<"

clean: distclean
	rm -rf $(OUT_DIR) $(AUX_DIR)
	find $(IN_DIR) -type f \( \
		-iname '*.aux' -o -iname '*.glo' -o -iname '*.idx' -o -iname '*.log' -o -iname '*.toc' -o \
		-iname '*.ist' -o -iname '*.acn' -o -iname '*.acr' -o -iname '*.alg' -o -iname '*.bbl' -o \
		-iname '*.blg' -o -iname '*.dvi' -o -iname '*.glg' -o -iname '*.gls' -o -iname '*.ilg' -o \
		-iname '*.ind' -o -iname '*.lof' -o -iname '*.lot' -o -iname '*.maf' -o -iname '*.mtc' -o \
		-iname '*.out' -o -iname '*.pdf' -o \
		-iname '*.mtc1' -o -iname '*.synctex.gz' -o -iname '*.ps' \) \
		-delete
	if [ -f $(MEDIA_GEN_DIR)makefile ]; then \
	   make -C $(MEDIA_GEN_DIR) clean	;\
	fi
	echo "REMOVED OUTPUT FILES BY EXTENSION IN: ."
	echo "REMOVED DIRS: $(OUT_DIR) $(AUX_DIR)"
	echo $(ERASE_MSG)

#generate distribution, for ex: dir with pdfs or zip with pdfs
dist: all
	mkdir -p $(DIST_DIR)
	if [ -z "$(TAG)" ]; then echo "TAG not specified"; fi
	mkdir -p "$(DIST_DIR)/$(TAG)/pdf/"
	cp -lr "$(OUT_DIR)"* "$(DIST_DIR)/$(TAG)/pdf/"
	cd "$(DIST_DIR)/$(TAG)" &&\
	find "pdf" -type f ! -iname "*$(OUT_EXT)" -delete &&\
	mv pdf "$(IN_ZIP_NAME)-pdf" &&\
	zip -r "pdf.zip" "$(IN_ZIP_NAME)-pdf" &&\
	mv "$(IN_ZIP_NAME)-pdf" pdf
	@echo 'DIST FILES WERE BE PUT INTO: $(DIST_DIR)'
	@echo $(ERASE_MSG)

#clean only the dist
distclean:
	rm -rf $(DIST_DIR)

#- remove any directory with the same name as the uploaded tag directory
#- upload
#
#only files with the OUT_EXT will be kept in the output
distup: dist
	cd $(DIST_DIR) && lftp -c "open -u $(FTP_USER) $(FTP_HOST) && rm -rf \"$(REMOTE_SUBDIR)\"; mkdir -p \"$(REMOTE_SUBDIR)\" && mirror -R \"$(TAG)\" \"$(REMOTE_SUBDIR)\""
	#TODO 0 prevent rm -rf from failing if dir does not exist, this forces us to use `;` instead of &&
	#the desired command would be:
	#cd $(DIST_DIR) && lftp -c "open -u $(FTP_USER) $(FTP_HOST) && rm -rf \"$(REMOTE_SUBDIR)\" && mkdir -p \"$(REMOTE_SUBDIR)\" && mirror -R \"$(TAG)\" \"$(REMOTE_SUBDIR)\""

help:
	@echo 'See the readme.md file for the documentation.'

#generate media generated programtically
media-gen:
	if [ -d "$(MEDIA_GEN)" ]; then make -C "$(MEDIA_GEN_DIR)"; fi

mkdir:
	mkdir -p "$(AUX_DIR)"
	mkdir -p "$(OUT_DIR)"
	@echo "MADE DIRS: $(OUT_DIR) $(AUX_DIR)"
	@echo $(ERASE_MSG)

view: all
	( \
		SYNCTEX_OUT="`synctex view -i "$(LINE):1:$(VIEW_TEX_PATH)" -o "$(VIEW_OUT_PATH)"`" ;\
		PAGE="`echo "$$SYNCTEX_OUT" | awk -F: '$$1 ~/Page/ { print $$2; exit }'`" ;\
		nohup $(VIEWER) $(VIEW_OUT_PATH) >/dev/null & \
	)

install-deps-ubuntu:
	sudo apt-get install -y aptitude
	sudo aptitude install -y texlive-full
	sudo aptitude install -y pandoc
	sudo aptitude install -y okular
	sudo aptitude install -y lftp
