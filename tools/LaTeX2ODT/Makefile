TARGET ?= test.tex
LTXML = $(TARGET:%.tex=%.ltxml)
CXML = $(TARGET:%.tex=%.xml)
MXML = $(TARGET:%.tex=%.manifest.xml)
ODT = $(TARGET:%.tex=%.odt)
BIBS ?= test.bib
LTBIBS = $(BIBS:%=%.ltxml)

IMG ?= campanile_fog.jpg
L2ODIR ?= .
XSLT = $(shell ls $(L2ODIR)/XSLT/*.xsl)
MXSL = $(L2ODIR)/XSLT/ltx2manifest.xsl
OXSL = $(L2ODIR)/XSLT/LaTeXML-ODT.xsl

all: $(ODT)

# if we are using biblatex:
# Change \bibstyle to plain in your .aux file, delete the \citation{biblatex-control}, and remove *-blx.bib from \bibdata
local.bib: $(TARGET:%.tex=%.aux)
	bibtool -x $< -o local.bib

$(LTXML): %.ltxml: %.tex $(LTBIBS)
#	latexmlc --includestyles --format=xml --pmml --profile=$(L2ODIR)/odt $< --destination $@ --log $@.log
	latexml --includestyles $< --destination $<.xml
	latexmlpost --format=xml --pmml  $<.xml --destination $@ --bib=$(LTBIBS)

$(LTBIBS): %.bib.ltxml: %.bib
#	latexmlc $< --destination $@ --log $@.log
	latexml $< --destination $@

$(CXML): %.xml: %.ltxml $(XSLT) $(LTBIBS)
	xsltproc $(OXSL) $< > $@

$(MXML): %.manifest.xml: %.ltxml $(XSLT)
	xsltproc $(MXSL) $< > $@

$(ODT): %.odt: %.xml $(IMG) %.manifest.xml
	rm -Rf tmp2zip
	mkdir tmp2zip
	cp  $(L2ODIR)/minimal/mimetype tmp2zip
	cp $(L2ODIR)/minimal/styles.xml $(L2ODIR)/minimal/meta.xml $(L2ODIR)/minimal/settings.xml tmp2zip
	cp $< tmp2zip/content.xml
	touch tmp2zip/content.xml # so that mimetype is first
	mkdir tmp2zip/META-INF
	cp $(basename $<).manifest.xml tmp2zip/META-INF/manifest.xml
	mkdir tmp2zip/Pictures
	cp $(IMG) tmp2zip/Pictures
	cd tmp2zip; zip -r ../$@ *;cd -
	rm -Rf tmp2zip 

odtclean:
	rm *.css $(MXML) $(CXML) $(LTBIBS) $(LTXML)

texclean: 
	rm -Rf auto
	rm *.aux *.log *.synctex.gz *.bbl *.blg

clean:	odtclean texclean
