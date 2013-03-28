TARGET ?= test.tex
LTXML = $(TARGET:%.tex=%.ltxml)
CXML = $(TARGET:%.tex=%.xml)
MXML = $(TARGET:%.tex=%.manifest.xml)
ODT = $(TARGET:%.tex=%.odt)
BIBS ?= test.bib
LTBIBS = $(BIBS:%=%.ltxml)

IMG ?= campanile_fog.jpg
L2ODIR ?= .

all: $(ODT)

# if we are using biblatex:
# Change \bibstyle to plain in your .aux file, delete the \citation{biblatex-control}, and remove *-blx.bib \bibdata
local.bib: $(TARGET:%.tex=%.aux)
	bibtool -x $< -o local.bib

$(LTXML): %.ltxml: %.tex
	latexmlc --includestyles --format=xml --pmml --profile=$(L2ODIR)/odt $< --destination $@ --log $@.log

$(LTBIBS): %.bib.ltxml: %.bib
	latexmlc $< --destination $@ --log $@.log

$(CXML): %.xml: %.ltxml $(L2ODIR)/ltx2odt.xsl $(LTBIBS)
	xsltproc $(L2ODIR)/ltx2odt.xsl $< > $@

$(MXML): %.manifest.xml: %.ltxml $(L2ODIR)/ltx2manifest.xsl
	xsltproc $(L2ODIR)/ltx2manifest.xsl $< > $@

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
