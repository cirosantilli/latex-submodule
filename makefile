#run `make help` for the documentation

##TODO
#
#- extract upload_tag automatically
#- put docs on a multiline var to avoid tons of echos and quoting hell

override ERASE_MSG := 'DONT PUT ANYTHING IMPORTANT IN THOSE DIRECTORIES SINCE `make clean` ERASES THEM!!!'

	#this file shall be sourced here. It should only contain project specific versions of the param
override PARAMS_FILE 		:= makefile-params
override PARAMS_FILE_LOCAL 	:= makefile-params-local

-include $(PARAMS_FILE)
-include $(PARAMS_FILE_LOCAL)

	#extension of input files:
override IN_EXTS   	?= .tex .md
	#directory from which input files come. slash termianted:
override IN_DIR   	?= ./src/

	#dir where output files such as .pdf will be put. slash terminated:
override OUT_DIR  	?= _out/
	#dir where auxiliary files such as `.out` will be put. slash terminated.
	#TODO: get this to work for a different dir than OUT_DIR. The problem is that synctex won't allow this!
#override AUX_DIR  	?= _aux/
override AUX_DIR  	?= $(OUT_DIR)

	#extension of output:
override OUT_EXT 	?= .pdf

	#basename without extension of file to view:
override VIEW		?= index
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
override CC_LATEX 		?= env "TEXINPUTS=./media//:./media-gen/out//:" pdflatex -interaction=nonstopmode -output-directory "$(AUX_DIR)"
override CC_MD	 		?= pandoc -s --toc --mathml -N

override MEDIA_GEN_DIR ?= ./media-gen/

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

.PHONY: all clean help media-gen mkdir ubuntu_install upload_output view

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

clean:
	rm -rf $(OUT_DIR) $(AUX_DIR)
	find $(IN_DIR) -type f \( \
		-iname '*.aux' -o -iname '*.glo' -o -iname '*.idx' -o -iname '*.log' -o -iname '*.toc' -o \
		-iname '*.ist' -o -iname '*.acn' -o -iname '*.acr' -o -iname '*.alg' -o -iname '*.bbl' -o \
		-iname '*.blg' -o -iname '*.dvi' -o -iname '*.glg' -o -iname '*.gls' -o -iname '*.ilg' -o \
		-iname '*.ind' -o -iname '*.lof' -o -iname '*.lot' -o -iname '*.maf' -o -iname '*.mtc' -o \
		-iname '*.out' -o -iname '*.pdf' -o \
		-iname '*.mtc1' -o -iname '*.synctex.gz' -o -iname '*.ps' \) \
		-delete
	if [ -d $(MEDIA_GEN_DIR) ]; then \
		make -C $(MEDIA_GEN_DIR) clean	;\
	fi
	@echo "REMOVED OUTPUT FILES BY EXTENSION IN: ."
	@echo "REMOVED DIRS: $(OUT_DIR) $(AUX_DIR)"
	@echo $(ERASE_MSG)

#generate distribution, for ex: dir with pdfs or zip with pdfs
dist:
	#TODO implement

#clean only the dist
distclean:
	#TODO implement

help:
	@echo 'compile all latex files under a given directory into pdfs'
	@echo ''
	@echo '#forward search'
	@echo ''
	@echo 'supports editor agnostic forward search'
	@echo ''
	@echo 'example of vim configuration for forward make:'
	@echo ''
	@echo '    au BufEnter,BufRead *.tex nnoremap <F6> :w<CR>:exe ':sil ! make view VIEW=''"%:r"'' LINE=''"' . line(".") . '"'''<CR>'
	@echo ''
	@echo '# targets'
	@echo ''
	@echo 'targets are sorted by increasing usefulness, simplicity or grouped by function:'
	@echo ''
	@echo '- ubuntu_install_deps'
	@echo ''
	@echo '    installs all the required dependencies supposing user is on a ubuntu machine'
	@echo ''
	@echo '- all (default target)'
	@echo ''
	@echo '    makes all tex files under IN_DIR configuration parameter (recursive) into pdfs'
	@echo ''
	@echo '    puts outputs under OUT_DIR configuraion parameter'
	@echo ''
	@echo '- view'
	@echo ''
	@echo '    requires the make target'
	@echo ''
	@echo '    view the file whose relative path without extension from IN_DIR'
	@echo '    equals VIEW using the viewer program VIEWER'
	@echo '    using the viewer program VIEWER'
	@echo ''
	@echo '    example:'
	@echo ''
	@echo '        make view VIEWER=okular VIEW=subdir/index'
	@echo ''
	@echo '- clean'
	@echo ''
	@echo '    remove OUT_DIR and AUX_DIR and any files which are any type output by either latex, pdflatex, bibtex or synctex'
	@echo '    for example `.pdf`, `.ps`, `synctex.gz`, `.out`, etc'
	@echo ''
	@echo '    the removal of files under IN_DIR is done so that users who use their editors to compile'
	@echo '    the pdfs on the same directory as the tex sources will also get a clean repo'
	@echo ''
	@echo '    it is however recommended that users configure their editors to use this makefile via command bindings'
	@echo ''
	@echo '# configuration parameters'
	@echo ''
	@echo 'the following files which may contain configurations parameters for this makefile:'
	@echo ''
	@echo '- makefile-params'
	@echo '- makefile-params-local'
	@echo ''
	@echo 'they must be placed in the same directory as this makefile'
	@echo ''
	@echo 'any of those files may not exist, in which case it is as if it was an empty file'
	@echo ''
	@echo 'those files use regular makefile syntax, but it may *not* contain any rules,'
	@echo 'only variable definitions and possibly intermediate computation steps to reach the values'
	@echo ''
	@echo 'the difference between both is that the local version'
	@echo 'shall not be tracked by git, and therefore can contain settings that'
	@echo 'vary between different users of the same project'
	@echo ''
	@echo 'the local version shall be run by make *after* the non local one,'
	@echo 'therefore any definition done there with `:=` shall override values in the non local params file'
	@echo 'while definitions done with `?=` shall provide default values in case those are not yet defined'
	@echo ''
	@echo 'for example, `makefile-params` could contain:'
	@echo ''
	@echo '    FTP_HOST := a.com'
	@echo '    A := $$(shell echo -n username )'
	@echo '    FTP_USER := $$(A)'
	@echo ''
	@echo 'now if `makefile-params-local` contains:'
	@echo ''
	@echo '    FTP_HOST := b.com'
	@echo '    FTP_USER ?= username2'
	@echo ''
	@echo 'then in the end, the configuration will be `FTP_HOST := b.com` (because is was defined with `:=`)'
	@echo ''
	@echo '    FTP_HOST := b.com'
	@echo ''
	@echo 'because is was defined with `:=` in the local file which is read afterwards and'
	@echo ''
	@echo '    FTP_USER := b.com'
	@echo ''
	@echo 'because is was defined with `?=` in the local file'
	@echo ''
	@echo 'Each parameter has a default value which shall be taken in case it does not appear in the'
	@echo 'parameter files. That value may however equal the empty string.It is recommended that you'
	@echo 'use the default values whenever you can unless you have a good reason not to do so,'
	@echo 'since it will be easier for people to understand your project then.'
	@echo ''
	@echo 'If you use a variable with a supported name as an intemediate buffer,'
	@echo 'dont forget to unsed that variable before the end, or it shall be taken as a parameter value'
	@echo ''
	@echo 'example ( highly *not* recommended usage, but valid ):'
	@echo ''
	@echo '    FTP_USER = a'
	@echo '    b = FTP_USER'
	@echo '    unset FTP_USER'
	@echo ''
	@echo 'those parameters can be equally given on the command line to make using the usual syntax'
	@echo ''
	@echo '    make PARAM_NAME=PARAM_VAL'
	@echo ''
	@echo 'the following configuration parameters are supported:'
	@echo ''
	@echo '- IN_DIR'
	@echo ''
	@echo '    directory which shall contain all of the .tex source files'
	@echo ''
	@echo '    IN_DIR must not be `.` Rationale: only way to clean editor generated'
	@echo '    files such as .pdf s which are put on the same directory as the .tex'
	@echo '    is removing files by extension, but it is possible that users want to'
	@echo '    include pdfs as media in their project, and that media would get wiped out'
	@echo '    by clean also. It would be possible to get around that by not removing'
	@echo '    files under certain directories, but that would be annoying to implement'
	@echo '	   since whenever a new directory is created it would be necessary to add it'
	@echo '    to the dont clear directory list.'
	@echo ''
	@echo '    default: src/'
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
