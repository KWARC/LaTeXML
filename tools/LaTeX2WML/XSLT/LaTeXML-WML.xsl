<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-WML.xsl                                                    |
|  Stylesheet for converting LaTeXML docs to Open Office XML (WML)    |
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

  <xsl:include href="LaTeXML-inline-WML.xsl"/>
  <xsl:include href="LaTeXML-block-WML.xsl"/>
  <xsl:include href="LaTeXML-misc-WML.xsl"/>
  <xsl:include href="LaTeXML-meta-WML.xsl"/>
  <xsl:include href="LaTeXML-para-WML.xsl"/>
  <xsl:include href="LaTeXML-math-WML.xsl"/>
  <xsl:include href="LaTeXML-tabular-WML.xsl"/>
  <xsl:include href="LaTeXML-picture-WML.xsl"/>
  <xsl:include href="LaTeXML-structure-WML.xsl"/>
  <xsl:include href="LaTeXML-bib-WML.xsl"/>

  <xsl:output method="xml" encoding='utf-8'/>

<!-- fallback for debugging -->
<xsl:template match="*">
  <xsl:message>cannot deal with element <xsl:value-of select="local-name()"/> yet!</xsl:message>
</xsl:template>

<xsl:template match="/">
  <xsl:comment>generated from LTXML</xsl:comment>
  <xsl:apply-templates/>
</xsl:template>

<!-- not appliccable -->
<xsl:template match="ltx:resource"/>


</xsl:stylesheet>
