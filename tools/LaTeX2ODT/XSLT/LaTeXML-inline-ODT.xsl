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
       ltx:anchor, ltx:ref, 
       ====================================================================== 
       ltx:cite, ltx:bibref are treated in LaTeXML-*bib-ODT.xsl
       ====================================================================== 
-->

<xsl:template match="ltx:text[@font='bold']">
  <text:span text:style-name="boldtext"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:text[@font='sansserif']">
  <text:span text:style-name="sansserif"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:text[@font='normal']"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:text[@font='italic']">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
</xsl:template>


<xsl:template match="ltx:text[@font='typewriter']">
  <text:span text:style-name="typewriter"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:text[@font='smallcaps']">
  <text:span text:style-name="smallcaps"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:text[contains(@class,'ltx_lstlisting')]">
  <text:span text:style-name="typewriter"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:text[contains(@class,'ltx_lst_space')]">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:emph">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:sup">
  <text:span text:style-name="superscript"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:sub">
  <text:span text:style-name="subscript"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:ref[@class='ltx_url' and @href]">
  <text:a xlink:type="simple" xlink:href="{@href}"><xsl:apply-templates/></text:a>
</xsl:template>

<xsl:template match="ltx:ref[@labelref]">
  <xsl:variable name="label" select="@labelref"/>
  <xsl:value-of select="//ltx:*[contains(@labels,$label)]/@refnum"/>
</xsl:template>

</xsl:stylesheet>

