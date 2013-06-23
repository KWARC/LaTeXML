TARGET ?= test.tex
LTXML = $(TARGET:%.tex=%.ltxml)
CXML = $(TARGET:%.tex=%.xml)
MXML = $(TARGET:%.tex=%.content_types.xml)
DOCX = $(TARGET:%.tex=%.docx)
BIBS ?= test.bib
LTBIBS = $(BIBS:%=%.ltxml)

IMG ?= campanile_fog.jpg
L2WDIR ?= .
XSLT = $(shell ls $(L2WDIR)/XSLT/*.xsl)
MXSL = $(L2WDIR)/XSLT/ltx2content_types.xsl
OXSL = $(L2WDIR)/XSLT/LaTeXML-WML.xsl

all: $(DOCX)

# if we are using biblatex:
# Change \bibstyle to plain in your .aux file, delete the \citation{biblatex-control}, and remove *-blx.bib from \bibdata
local.bib: $(TARGET:%.tex=%.aux)
	bibtool -x $< -o local.bib

$(LTXML): %.ltxml: %.tex $(LTBIBS)
#	latexmlc --includestyles --format=xml --pmml --profile=$(L2WDIR)/docx $< --destination $@ --log $@.log
	latexml --includestyles $< --destination $<.xml
	latexmlpost --format=xml --pmml  $<.xml --destination $@ --bib=$(LTBIBS)

$(LTBIBS): %.bib.ltxml: %.bib
#	latexmlc $< --destination $@ --log $@.log
	latexml $< --destination $@

$(CXML): %.xml: %.ltxml $(XSLT) $(LTBIBS)
	xsltproc $(OXSL) $< > $@

$(MXML): %.content_types.xml: %.ltxml $(XSLT)
	xsltproc $(MXSL) $< > $@

$(DOCX): %.docx: %.xml $(IMG) %.content_types.xml
	rm -Rf tmp2zip
	mkdir tmp2zip
	cp -r $(L2WDIR)/minimal/_rels tmp2zip
	cp -r $(L2WDIR)/minimal/docProps tmp2zip
	cp -r $(L2WDIR)/minimal/word tmp2zip
	cp $< tmp2zip/word/document.xml
	cp $(basename $<).content_types.xml tmp2zip/\[Content_Types\].xml
	mkdir tmp2zip/media
	cp $(IMG) tmp2zip/media
	cd tmp2zip; zip -r ../$@ *;cd -
	rm -Rf tmp2zip 

docxclean:
	rm *.css $(MXML) $(CXML) $(LTBIBS) $(LTXML)

texclean: 
	rm -Rf auto
	rm *.aux *.log *.synctex.gz *.bbl *.blg

clean:	docxclean texclean

echo: 	
	echo $(XSLT)
