TARGET ?= test.tex
LTXML = $(TARGET:%.tex=%.ltxml)
CXML = $(TARGET:%.tex=%.ltxml)
MXML = $(TARGET:%.tex=%.manifest.xml)
ODT = $(TARGET:%.tex=%.odt)
BIB ?= test.bib
LTBIB = $(BIB:%.bib=%.test.bib.ltxml)

IMG ?= campanile_fog.jpg

all: $(ODT)

$(LTXML): %.ltxml: %.tex
	latexmlc --profile=odt $< --destination $@ --log $<.log

$(LTBIB): %.bib.ltxml: %.bib
	latexmlc $< --destination $@ --log $<.bib.log

$(CXML): %.xml: %.ltxml ltx2odt.xsl %.bib.ltxml
#	latexmlpost $< --stylesheet ltx2odt.xsl --destination $@ $< --log $<.log
	xsltproc ltx2odt.xsl $< > $@

$(MXML): %.manifest.xml: %.ltxml ltx2manifest.xsl
#	latexmlpost $< --stylesheet ltx2odt.xsl --destination $@ $< --log $<.log
	xsltproc ltx2manifest.xsl $< > $@

$(ODT): %.odt: %.xml $(IMG) %.manifest.xml
	rm -Rf tmp2zip
	mkdir tmp2zip
	cp minimal/styles.xml minimal/meta.xml minimal/settings.xml tmp2zip
	cp $< tmp2zip/content.xml
	mkdir tmp2zip/META-INF
	cp $(basename $<).manifest.xml tmp2zip/META-INF/manifest.xml
	mkdir tmp2zip/Pictures
	cp $(IMG) tmp2zip/Pictures
	cd tmp2zip; zip -r ../$@ *;cd -
	rm -Rf tmp2zip 

odtclean:
	rm *.css $(MXML) $(CXML) $(LTBIB) $(LTXML)

texclean: 
	rm -Rf auto
	rm *.aux *.log *.synctex.gz *.bbl *.blg

clean:	odtclean texclean
