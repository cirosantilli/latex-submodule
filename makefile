#see `make help` for the documentation

##TODO
#
#- extract upload_tag automatically
#- put docs on a multiline var

override ERASE_MSG := 'DONT PUT ANYTHING IMPORTANT IN THOSE DIRECTORIES SINCE `make clean` ERASES THEM!!!'

	#this file shall be sourced here. It should only contain project specific versions of the param
override PARAMS_FILE := makefile-params

-include $(PARAMS_FILE)

	#extension of input files:
override IN_EXT   	?= .tex
	#directory from which input files come. slash termianted:
override IN_DIR   	?= ./tex/

	#dir where output files such as .pdf will be put. slash terminated:
override OUT_DIR  	?= _out/
	#dir where auxiliary files such as `.out` will be put. slash terminated.
	#TODO: get this to work for a different dir than OUT_DIR. The problem is that synctex won't allow this!
#override AUX_DIR  	?= _aux/
override AUX_DIR  	?= $(OUT_DIR)

	#extension of output:
override OUT_EXT 	?= .pdf

	#basename without extension of file to run:
override VIEW		?= cheat
	#uses synctex to go to the page corresponding to the given line.
override LINE		?= 1
	#viewer command used to view the output.
	#$$PAGE is a bash variable that contains the page to open the document at. It is typically calculated by synctex in this makefile.
override VIEWER 	?= okular --unique -p $$PAGE
	#default upload tag, name of directory under which zip file will go
override UPLOAD_TAG ?= 1.2
override FTP_HOST 	?=
override FTP_USER 	?=

	#compile command
override CCC 		?= env "TEXINPUTS=./media//:./media-gen/out//:" pdflatex -interaction=nonstopmode -output-directory "$(AUX_DIR)"

override MEDIA_GEN_DIR ?= ./media-gen/

INS			:= $(wildcard $(IN_DIR)*$(IN_EXT))
INS_NODIR	:= $(notdir $(INS))
OUTS_NODIR	:= $(patsubst %$(IN_EXT),%$(OUT_EXT),$(INS_NODIR))
OUTS		:= $(addprefix $(OUT_DIR),$(OUTS_NODIR))

STYS		:= $(wildcard *.sty)
BIBS		:= $(wildcard *.bib)

	#path of tex file to be viewed (needed by synctex):
VIEW_TEX_PATH	:= $(IN_DIR)$(VIEW)$(IN_EXT)
	#path of output file to be viewed:
VIEW_OUT_PATH	:= $(OUT_DIR)$(VIEW)$(OUT_EXT)

#remove automatic rules:
.SUFFIXES:

.PHONY: all clean help media-gen mkdir run ubuntu_install upload_output

all: $(OUTS) | media-gen mkdir
	if [ $(MAKELEVEL) -eq 0 ]; then for IN_DIR in `find $(IN_DIR) -mindepth 1 -type d`; do $(MAKE) IN_DIR="$$IN_DIR/" OUT_DIR="$(OUT_DIR)$${IN_DIR#$(IN_DIR)}/"; done; fi
	@echo 'AUXILIARY FILES WERE PUT INTO:    $(AUX_DIR)'
	@echo 'OUTPUT    FILES WERE BE PUT INTO: $(OUT_DIR)'
	@echo $(ERASE_MSG)

#$(STYS) $(BIBS) are here so that if any include files are modified, make again:
$(OUT_DIR)%$(OUT_EXT): $(IN_DIR)%$(IN_EXT) $(STYS) $(BIBS)
	#make pdf with bibtex and synctex:
	$(CCC) "$<"
	#allowing for error here in case tex has no bib files:
	-bibtex "$(AUX_DIR)$*"
	$(CCC) "$<"
	$(CCC) -synctex=1 "$<"
	#move output to out dir if they are different:
	if [ ! $(AUX_DIR) = $(OUT_DIR) ]; then mv -f $(AUX_DIR)$*$(OUT_EXT) "$(OUT_DIR)"; fi

#removes the aux and out dirs
#also removes all files with known output extensions
#in case you and to clean after using some ide
#that does not allow for subdirs
clean:
	rm -rf $(OUT_DIR) $(AUX_DIR) \
		*.aux *.glo *.idx *.log *.toc *.ist *.acn *.acr *.alg *.bbl *.blg \
		*.dvi *.glg *.gls *.ilg *.ind *.lof *.lot *.maf *.mtc *.mtc1 *.out \
		*.synctex.gz *.ps *.pdf
	if [ -d $(MEDIA_GEN_DIR) ]; then \
		make -C $(MEDIA_GEN_DIR) clean	;\
	fi
	@echo "REMOVED OUTPUT FILES BY EXTENSION IN: ."
	@echo "REMOVED DIRS: $(OUT_DIR) $(AUX_DIR)"
	@echo $(ERASE_MSG)

help:
	@echo 'compile all latex files under a given directory into pdfs'
	@echo ''
	@echo 'install dependencies on Ubuntu:'
	@echo ''
	@echo '#forward search'
	@echo ''
	@echo 'supports editor agnostic forward search'
	@echo ''
	@echo '      example of vim configuration for forward make:'
	@echo ''
	@echo 'au BufEnter,BufRead *.tex nnoremap <F6> :w<CR>:exe ':sil ! make run VIEW=''"%:r"'' LINE=''"' . line(".") . '"'''<CR>'
	@echo ''
	@echo '# sample invocations'
	@echo ''
	@echo '    ubuntu_install_deps'
	@echo '    make'
	@echo '    make clean'
	@echo ''
	@echo 'view the default output file with our default view command'
	@echo ''
	@echo '    make run'
	@echo ''
	@echo 'view another file:'
	@echo ''
	@echo '    make run VIEW=main'
	@echo ''
	@echo 'will view file main$$(OUT_EXT) (main.pdf or main.ps typically)'
	@echo ''
	@echo '# configuration'
	@echo ''
	@echo 'many parameters can be controlled by defining variables on a file named `makefile-params`'
	@echo 'placed in the same directory as this makefile'
	@echo ''
	@echo 'the `makefile-params` file uses regular makefile syntax, but it may *not* contain any rules'
	@echo 'only variable definitions and possibly computation steps required to reach those variables'
	@echo ''
	@echo 'for example, the `makefile-params` could contain:'
	@echo ''
	@echo '    FTP_HOST := http://ftp.a.com'
	@echo '    A := $$(shell echo -n username )'
	@echo '    FTP_USER := $$(A)'
	@echo ''
	@echo 'each parameter has a default value which shall be taken in case it does not appear in the'
	@echo '`makefile-params` file. That value may however equal the empty string.'
	@echo ''
	@echo 'if you use a variable with a supported name as an intemediate buffer, dont forget to unsed that variable before the end.'
	@echo ''
	@echo 'example ( highly *not* recommended usage, but valid):'
	@echo ''
	@echo '    FTP_USER = a'
	@echo '    b = FTP_USER'
	@echo '    unset FTP_USER'
	@echo ''
	@echo 'those parameters can be equally given on the command line to make using the usual syntax'
	@echo ''
	@echo '    make PARAM_NAME=PARAM_VAL'
	@echo ''
	@echo 'the following options are supported:'
	@echo ''
	@echo '- FTP_HOST'
	@echo ''
	@echo '    host to upload output files to'
	@echo ''
	@echo '    default: EMPTY'
	@echo ''
	@echo '- FTP_USER'
	@echo ''
	@echo '    username to connect to the ftp host'
	@echo ''
	@echo '    default: EMPTY'
	@echo ''
	@#TODO manage   page to allow this:
	@#echo '  #views given file with given command:'
	@#echo "    make run VIEWER='\"evince -f\"'"

#generate media generated programtically
media-gen:
	if [ -d "$(MEDIA_GEN)" ]; then make -C "$(MEDIA_GEN_DIR)"; fi

mkdir:
	mkdir -p "$(AUX_DIR)"
	mkdir -p "$(OUT_DIR)"
	@echo "MADE DIRS: $(OUT_DIR) $(AUX_DIR)"
	@echo $(ERASE_MSG)

#view output.
#called `run` for compatibility with makefiles that make executables.
#TODO: get synctex to work if aux != out!!
#PAGE="`echo "$$SYNCTEX_OUT" | awk -F: '$$1 ~/Page/ { print $$2; exit }'`" ;\
#SYNCTEX_OUT="`synctex view -i "$(LINE):1:$(VIEW_TEX_PATH)" -o "$(VIEW_OUT_PATH)" -d "$(../AUX_DIR)"`" ;\
#echo $$PDF_PAGE ;
run: all
	( \
		SYNCTEX_OUT="`synctex view -i "$(LINE):1:$(VIEW_TEX_PATH)" -o "$(VIEW_OUT_PATH)"`" ;\
		PAGE="`echo "$$SYNCTEX_OUT" | awk -F: '$$1 ~/Page/ { print $$2; exit }'`" ;\
		nohup $(VIEWER) $(VIEW_OUT_PATH) >/dev/null & \
	)

ubuntu_install_deps:
	sudo aptitude install -y texlive-full
	sudo aptitude install -y okular

#- create what will be output to a web host on a temporary dir
#- upload the files
#- remove the temporary dir
#
#only files with the OUT_EXT will be kept in the output
upload_output: all
	if [ -z "$(UPLOAD_TAG)" ]; then echo "UPLOAD_TAG not specified"; fi
	TMP_DIR="`mktemp -d --tmpdir latex.XXXXXX`" 			&&\
	mkdir -p "$$TMP_DIR/$(UPLOAD_TAG)/tree/" 				&&\
	cp -lr "$(OUT_DIR)"* "$$TMP_DIR/$(UPLOAD_TAG)/tree/" 	&&\
	cd "$$TMP_DIR/$(UPLOAD_TAG)" 							&&\
	pwd &&\
	find "tree" -mindepth 1 ! -iname "*$(OUT_EXT)" -delete 	&&\
	if [ ! "$(UPLOAD_TAG)" = "tree" ]; then mv "tree" "$(UPLOAD_TAG)"; fi	&&\
	zip -r "$(UPLOAD_TAG)".zip "$(UPLOAD_TAG)"*								&&\
	if [ ! "$(UPLOAD_TAG)" = "tree" ]; then mv "$(UPLOAD_TAG)" "tree" ; fi	&&\
	cd ..																	&&\
	lftp -c "open -u $(FTP_USER) $(FTP_HOST) && mkdir -p \"$(REMOTE_SUBDIR)\" && mirror -R \"$(UPLOAD_TAG)\" \"$(REMOTE_SUBDIR)\"" &&\
	rm -r "$$TMP_DIR"
