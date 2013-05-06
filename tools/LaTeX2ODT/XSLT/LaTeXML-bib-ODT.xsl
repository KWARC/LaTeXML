<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-bib-ODT.xsl                                               |
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
    xmlns:m="http://www.w3.org/1998/Math/MathML"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    exclude-result-prefixes = "ltx m xlink office text">

  <!-- ======================================================================
       Bibliography
       [AFTER conversion to presentation by postprocessing! ie only bibitem's]
       ====================================================================== -->

<xsl:template match="ltx:cite"><xsl:apply-templates/></xsl:template>
<xsl:template match="ltx:cite/ltx:ref"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:bibliography">
  <xsl:text>&#xA;&#xA;</xsl:text>
  <text:h text:style-name="heading1" text:outline-level="1" text:is-list-header="true">
    <xsl:apply-templates select="ltx:title"/>
  </text:h>
  <xsl:text>&#xA;</xsl:text>
  <xsl:apply-templates select="ltx:biblist"/>
</xsl:template>

<xsl:template match="ltx:bibliography/ltx:title"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:biblist">
  <text:list text:style-name="WW8Num21">
    <xsl:apply-templates/>
  </text:list>
</xsl:template>

<xsl:template match="ltx:bibitem">
  <xsl:text>&#xA;</xsl:text>
  <text:list-item>
    <text:p text:style-name="referenceitem">
      <xsl:apply-templates/>
      <text:s/>
    </text:p>
  </text:list-item>
</xsl:template>

<!-- we do not want to show this information -->
<xsl:template match="ltx:bibtag"/>

<!-- first one without -->
<xsl:template match="ltx:bibblock">
  <xsl:if test="preceding-sibling::ltx:bibblock"><xsl:text> </xsl:text></xsl:if>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:bibblock[ltx:text[@class='ltx_bib_links']]">
  <xsl:apply-templates select="ltx:text/*"/>
</xsl:template>

<!-- disregard these --> 
<xsl:template match="ltx:bibblock[@class='ltx_bib_cited']"/>
<xsl:template match="ltx:bibblock[descendant::ltx:bib-note]"/>

<xsl:template match="ltx:bibblock/ltx:text">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:text[@class='ltx_bib_external']">
  <xsl:apply-templates/>
</xsl:template>
<xsl:template match="ltx:ref[contains(@class,'ltx_bib_external')]">
  <xsl:text> </xsl:text>
  <text:a xlink:type="simple" xlink:href="{@href}"><xsl:value-of select="@href"/></text:a>
</xsl:template>
<xsl:template match="ltx:text[contains(@class,'isbn') or contains(@class,'issn')]">
  <xsl:text> </xsl:text>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:bibblock/ltx:text[@class='ltx_bib_volume' or @class='ltx_bib_year']">
  <xsl:text> </xsl:text>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:text[@class='ltx_bib_journal']">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
</xsl:template>

<!-- *** maybe add crossref *** -->
<xsl:template match="ltx:text[@class='ltx_bib_crossref']">
  <xsl:text>[</xsl:text><xsl:apply-templates/><xsl:text>]</xsl:text>
</xsl:template>

<xsl:template match="ltx:bib-part|ltx:bib-date|ltx:bib-title|ltx:bib-place|ltx:bib-publisher|ltx:bib-organization|
		     ltx:bib-type|ltx:bib-edition|ltx:bib-language">
  <xsl:apply-templates/>
</xsl:template>
</xsl:stylesheet>

