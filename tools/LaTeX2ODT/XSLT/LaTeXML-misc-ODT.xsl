<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-misc-ODT.xsl                                               |
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
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes = "ltx text xlink draw">

  <!-- ======================================================================
       Various things that aren't clearly inline or blocks, or can be both:
       ltx:inline-block, ltx:verbatim, ltx:break, ltx:graphics, ltx:svg, ltx:rawhtml
       ====================================================================== -->

<xsl:template match="ltx:break"><text:line-break/></xsl:template>

<xsl:template match="ltx:verbatim[@font='typewriter']">
  <text:span text:style-name="typewriter"><xsl:apply-templates/></text:span>
</xsl:template>

<!-- need width,height treatment and a treatment for frame styles-->
<xsl:template match="ltx:graphics">
  <text:p text:style-name="image">
    <draw:frame draw:style-name="Graphics" draw:name="graphics1" text:anchor-type="paragraph" draw:z-index="0">
      <draw:image xlink:href="Pictures/{@candidates}" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
     </draw:frame>
  </text:p>
</xsl:template>

    
</xsl:stylesheet>

