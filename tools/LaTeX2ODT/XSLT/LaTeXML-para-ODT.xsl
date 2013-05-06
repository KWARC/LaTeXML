<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-para-ODT.xsl                                               |
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
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:text  = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
    exclude-result-prefixes = "ltx text svg draw">

  <!-- ======================================================================
       Logical paragraphs
       ====================================================================== -->

<!-- there is no para concept in ODT, so skip -->
<xsl:template match="ltx:para"><xsl:apply-templates/></xsl:template>

<!-- need width,height treatment and a treatment for frame styles-->
<xsl:template match="ltx:figure|ltx:table">
  <text:p>
    <draw:frame draw:style-name="Graphics" draw:name="graphics1" text:anchor-type="paragraph" draw:z-index="0"
		svg:width="10cm" svg:height="10cm">
      <draw:text-box>
	<xsl:apply-templates/>
      </draw:text-box>
    </draw:frame>
  </text:p>
</xsl:template>

<!-- reconsider this? it should add to the list of figures --> 
<xsl:template match="ltx:toccaption"/>

<xsl:template match="ltx:caption/ltx:tag">
  <text:span text:style-name="boldtext"><xsl:apply-templates/><xsl:value-of select="@close"/></text:span>
</xsl:template>

<xsl:template match="ltx:caption">
  <text:p text:style-name="figurecaption">
    <xsl:apply-templates/> 
  </text:p>
</xsl:template>
	      




</xsl:stylesheet>

