<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-tabular-ODT.xsl                                               |
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
    xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    exclude-result-prefixes = "ltx text table">

<xsl:template match="ltx:tabular">
  <table:table>
    <table:table-column table:number-columns-repeated="{count(ltx:thead/ltx:tr/ltx:td)}"/>
  <xsl:apply-templates/>
  </table:table>
</xsl:template>

<!-- there is no concept of a table head/body in ODT -->
<xsl:template match="ltx:thead|ltx:tbody"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:tr">
  <table:table-row><xsl:apply-templates/></table:table-row>
</xsl:template>

<xsl:template match="ltx:td">
  <table:table-cell><text:p><xsl:apply-templates/></text:p></table:table-cell>
</xsl:template>
</xsl:stylesheet>

