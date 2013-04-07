<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-inline-ODT.xsl                                             |
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
    xmlns:text  = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes = "ltx text xlink">

  <!-- ======================================================================
       Various inline-level elements:
       ltx:text, ltx:emph, ltx:del, ltx:sub, ltx:sup, ltx:acronym, ltx:rule,
       ltx:anchor, ltx:ref, ltx:cite, ltx:bibref
       ====================================================================== -->

<xsl:template match="ltx:text[@font='bold']">
  <text:span text:style-name="boldtext"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:text[@font='normal']"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:text[@font='italic']">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
</xsl:template>


<xsl:template match="ltx:text[@font='typewriter']">
  <text:span text:style-name="typewriter"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:emph">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:ref[@class='ltx_url' and @href]">
  <text:a xlink:type="simple" xlink:href="{@href}"><xsl:apply-templates/></text:a>
</xsl:template>

<xsl:template match="ltx:ref[@labelref]">
  <xsl:variable name="label" select="@labelref"/>
  <xsl:value-of select="//ltx:*[contains(@labels,$label)]/@refnum"/>
</xsl:template>

<!-- we disregard the [.. ] -->
<xsl:template match="ltx:cite">
  <xsl:apply-templates select="ltx:ref"/>
</xsl:template>

<xsl:template match="ltx:cite/ltx:ref">
  <xsl:variable name="key" select="@idref"/>
  <xsl:message>key: <xsl:value-of select="$key"/></xsl:message>
  <xsl:variable name="bibitem" select="//ltx:bibitem[@xml:id=$key]"/>
  <text:bibliography-mark text:identifier="{.}" text:bibliography-type="{$bibitem/@type}">
      <xsl:if test="$bibitem/ltx:bibtag[@class='ltx_bib_author']">
	<xsl:attribute name="text:author">
	  <xsl:value-of select="normalize-space($bibitem/ltx:bibtag[@class='ltx_bib_author'])"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibitem/ltx:bibtag[@class='ltx_bib_title']">
	<xsl:attribute name="text:title">
	  <xsl:value-of select="normalize-space($bibitem/ltx:bibtag[@class='ltx_bib_title'])"/>
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
      <xsl:if test="$bibitem//ltx:bib-publisher">
	<xsl:attribute name="text:publisher">
	  <xsl:value-of select="normalize-space($bibitem//ltx:bib-publisher)"/>
	</xsl:attribute>
      </xsl:if>
<!-- 	also text:address, text:annote, text:booktitle, text:chapter, text:edition,
	text:editor, text:howpublished, text:identifier, text:institution, text:isbn,
	text:issn, text:month, text:note, text:number, text:organizations,
	text:report-type, text:school, text:series, text:url, text:volume -->
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

