TARGET ?= test.tex
LTXML = $(TARGET:%.tex=%.ltxml)
CXML = $(TARGET:%.tex=%.xml)
MXML = $(TARGET:%.tex=%.content_types.xml)
DOCX = $(TARGET:%.tex=%.docx)
BIBS ?= test.bib
LTBIBS = $(BIBS:%=%.ltxml)

IMG ?= campanile_fog.jpg
L2ODIR ?= .

all: $(DOCX)

# if we are using biblatex:
# Change \bibstyle to plain in your .aux file, delete the \citation{biblatex-control}, and remove *-blx.bib \bibdata
local.bib: $(TARGET:%.tex=%.aux)
	bibtool -x $< -o local.bib

$(LTXML): %.ltxml: %.tex
	latexmlc --includestyles --format=xml --pmml --profile=$(L2ODIR)/docx $< --destination $@ --log $@.log

$(LTBIBS): %.bib.ltxml: %.bib
	latexmlc $< --destination $@ --log $@.log

$(CXML): %.xml: %.ltxml $(L2ODIR)/ltx2docx.xsl $(LTBIBS)
	xsltproc $(L2ODIR)/ltx2docx.xsl $< > $@

$(MXML): %.content_types.xml: %.ltxml $(L2ODIR)/ltx2content_types.xsl
	xsltproc $(L2ODIR)/ltx2content_types.xsl $< > $@

$(DOCX): %.docx: %.xml $(IMG) %.content_types.xml
	rm -Rf tmp2zip
	mkdir tmp2zip
	cp -r $(L2ODIR)/minimal/_rels tmp2zip
	cp -r $(L2ODIR)/minimal/docProps tmp2zip
	mkdir tmp2zip/word
	cp $< tmp2zip/word/document.xml
	cp $(basename $<).content_types.xml tmp2zip/\[Content_Types\].xml
	mkdir tmp2zip/media
	cp $(IMG) tmp2zip/media
	cd tmp2zip; zip -r ../$@ *;cd -
#	rm -Rf tmp2zip 

docxclean:
	rm *.css $(MXML) $(CXML) $(LTBIBS) $(LTXML)

texclean: 
	rm -Rf auto
	rm *.aux *.log *.synctex.gz *.bbl *.blg

clean:	docxclean texclean
