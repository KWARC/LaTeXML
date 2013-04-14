<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-realbib-ODT.xsl                                            |
|  Stylesheet for converting LaTeXML documents to Open Document Text  |
|=====================================================================|
| not yet Part of LaTeXML: http://dlmf.nist.gov/LaTeXML/              |
|=====================================================================|
| Michael Kohlhase http://kwarc.info/kohlhase                 #_#     |
| Public domain software                                     (o o)    |
\=========================================================ooo==U==ooo=/
-->
<xsl:stylesheet
    version     = "1.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:ltx   = "http://dlmf.nist.gov/LaTeXML"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    exclude-result-prefixes = "ltx text office">


<xsl:variable name="bib" select="//ltx:bibliography/@files"/>
<xsl:variable name="biblist" select="document(concat($bib,'.bib.ltxml'),.)//ltx:bibliography/ltx:biblist"/>

<xsl:template match="ltx:bibliography">
  <text:bibliography text:protected="true" name="Rererences1">
    <text:index-body>
      <text:index-title><text:p>References</text:p></text:index-title>
    </text:index-body>
  </text:bibliography>
</xsl:template>

<!-- we disregard the [.. ] -->
<xsl:template match="ltx:cite">
  <xsl:apply-templates select="ltx:ref"/>
</xsl:template>

<xsl:template match="ltx:cite/ltx:ref">
  <xsl:variable name="key" select="@idref"/>
  <xsl:variable name="bibitem" select="//ltx:bibitem[@xml:id=$key]"/>
  <text:bibliography-mark text:identifier="{.}" text:bibliography-type="{$bibitem/@type}">
    <xsl:if test="$bibitem/ltx:bibtag[@class='ltx_bib_author']">
      <xsl:attribute name="text:author">
	<xsl:value-of select="normalize-space($bibitem/ltx:bibtag[@class='ltx_bib_author'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:text[@class='ltx_bib_editor']">
      <xsl:attribute name="text:editor">
	<xsl:value-of select="normalize-space($bibitem//ltx:text[@class='ltx_bib_editor'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem/ltx:bibtag[@class='ltx_bib_title']">
      <xsl:attribute name="text:title">
	<xsl:value-of select="normalize-space($bibitem/ltx:bibtag[@class='ltx_bib_title'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem/ltx:bibtag[@class='ltx_bib_booktitle']">
      <xsl:attribute name="text:booktitle">
	<xsl:value-of select="normalize-space($bibitem/ltx:bibtag[@class='ltx_bib_booktitle'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:text[@class='ltx_bib_journal']">
      <xsl:attribute name="text:journal">
	<xsl:value-of select="normalize-space($bibitem//ltx:text[@class='ltx_bib_journal'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem/ltx:bibtag[@class='ltx_bib_year']">
      <xsl:attribute name="text:year">
	<xsl:value-of select="normalize-space($bibitem/ltx:bibtag[@class='ltx_bib_year'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:bib-part[@role='pages']">
      <xsl:attribute name="text:pages">
	<xsl:value-of select="normalize-space($bibitem//ltx:bib-part[@role='pages'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:bib-part[@role='volume']">
      <xsl:attribute name="text:volume">
	<xsl:value-of select="normalize-space($bibitem//ltx:bib-part[@role='volume'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:bib-part[@role='number']">
      <xsl:attribute name="text:number">
	<xsl:value-of select="normalize-space($bibitem//ltx:bib-part[@role='number'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:bib-part[@role='series']">
      <xsl:attribute name="text:series">
	<xsl:value-of select="normalize-space($bibitem//ltx:bib-part[@role='series'])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:bib-publisher">
      <xsl:attribute name="text:publisher">
	<xsl:value-of select="normalize-space($bibitem//ltx:bib-publisher)"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:bib-note">
      <xsl:attribute name="text:note">
	<xsl:value-of select="normalize-space($bibitem//ltx:bib-note)"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:bib-annote">
      <xsl:attribute name="text:annote">
	<xsl:value-of select="normalize-space($bibitem//ltx:bib-annote)"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:text[contains(@class,'isbn')]">
      <xsl:attribute name="text:isbn">
	<xsl:value-of select="normalize-space($bibitem//ltx:text[contains(@class,'isbn')])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:text[contains(@class,'issn')]">
      <xsl:attribute name="text:issn">
	<xsl:value-of select="normalize-space($bibitem//ltx:text[contains(@class,'issn')])"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:ref[@class='ltx_bib_external']">
      <xsl:attribute name="text:url">
	<xsl:value-of select="normalize-space($bibitem//ltx:ref[@class='ltx_bib_external']/@href)"/>
      </xsl:attribute>
    </xsl:if>
    <xsl:if test="$bibitem//ltx:text[@class='ltx_bib_crossref']">
      <xsl:attribute name="text:howpublished">
	<xsl:text>in [</xsl:text>
	<xsl:value-of select="normalize-space($bibitem//ltx:text[@class='ltx_bib_crossref']/ltx:cite/ltx:ref)"/>
	<xsl:text>]</xsl:text>
      </xsl:attribute>
    </xsl:if>
<!-- 	also text:address, text:chapter, text:edition,
	text:howpublished, text:identifier, text:institution,
	text:month, text:organizations,
	text:report-type, text:school -->
	<xsl:text>[</xsl:text>
	<xsl:value-of select="."/>
	<xsl:text>]</xsl:text>
    </text:bibliography-mark>

  <xsl:apply-templates select="ltx:ref"/>
</xsl:template>

<!-- the old way: we get the information directly from the bib
<xsl:template match="ltx:cite">
  <xsl:for-each select="ltx:bibref/@bibrefs">
    <xsl:variable name="key" select="."/>
    <xsl:variable name="bibref" select="$biblist/ltx:bibentry[@key=$key]"/>
    <text:bibliography-mark text:identifier="{.}" text:bibliography-type="{$bibref/@type}">
      <xsl:if test="$bibref/ltx:bib-name">
	<xsl:attribute name="text:author">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-name)"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-title">
	<xsl:attribute name="text:title">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-title)"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-related[@role='host' and type='journal']">
	<xsl:attribute name="text:journal">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-related[@role='host' and type='journal']/ltx:bib-title)"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-date[@role='publication']">
	<xsl:attribute name="text:year">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-date[@role='publication'])"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-part[@role='pages']">
	<xsl:attribute name="text:year">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-part[@role='pages'])"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-publisher">
	<xsl:attribute name="text:year">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-publisher)"/>
	</xsl:attribute>
      </xsl:if>
	also text:address, text:annote, text:booktitle, text:chapter, text:edition,
	text:editor, text:howpublished, text:identifier, text:institution, text:isbn,
	text:issn, text:month, text:note, text:number, text:organizations,
	text:report-type, text:school, text:series, text:url, text:volume
	<xsl:text>[</xsl:text>
	<xsl:value-of select="$key"/>
	<xsl:text>]</xsl:text>
    </text:bibliography-mark>
  </xsl:for-each>
</xsl:template>
-->
    

</xsl:stylesheet>

