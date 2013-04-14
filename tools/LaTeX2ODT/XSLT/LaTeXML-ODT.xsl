<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-ODT.xsl                                                    |
|  Stylesheet for converting LaTeXML documents to Open Document Text  |
|=====================================================================|
| not yet Part of LaTeXML: http://dlmf.nist.gov/LaTeXML/              |
|=====================================================================|
| Michael Kohlhase http://kwarc.info/kohlhase                 #_#     |
| Public domain software                                     (o o)    |
\=========================================================ooo==U==ooo=/
-->
<xsl:stylesheet version = "1.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:ltx   = "http://dlmf.nist.gov/LaTeXML"
    exclude-result-prefixes = "ltx">

<!-- not yet  <xsl:include href="LaTeXML-ODT-common.xsl"/> -->
  <xsl:include href="LaTeXML-inline-ODT.xsl"/>
  <xsl:include href="LaTeXML-block-ODT.xsl"/>
  <xsl:include href="LaTeXML-misc-ODT.xsl"/>
  <xsl:include href="LaTeXML-meta-ODT.xsl"/>
  <xsl:include href="LaTeXML-para-ODT.xsl"/>
  <xsl:include href="LaTeXML-math-ODT.xsl"/>
  <xsl:include href="LaTeXML-tabular-ODT.xsl"/>
  <xsl:include href="LaTeXML-picture-ODT.xsl"/>
  <xsl:include href="LaTeXML-structure-ODT.xsl"/>
<!-- we have two ways of treating bibs, 
     the first one just makes it look like a bib, 
     the second one (experimental) uses ODT's mechanisms -->
  <xsl:include href="LaTeXML-bib-ODT.xsl"/>
<!--  <xsl:include href="LaTeXML-bib-ODT.xsl"/>-->

  <xsl:output method="xml" encoding='utf-8'/>

<!-- fallback for debugging -->
<xsl:template match="*">
  <xsl:message>cannot deal with element <xsl:value-of select="local-name()"/> yet!</xsl:message>
  <xsl:comment >*** cannot deal with element <xsl:value-of select="local-name()"/> here yet! ***</xsl:comment>
</xsl:template>

<xsl:template match="/">
  <xsl:comment>generated from LTXML</xsl:comment>
  <xsl:apply-templates/>
</xsl:template>

<!-- not appliccable -->
<xsl:template match="ltx:resource"/>


</xsl:stylesheet>
