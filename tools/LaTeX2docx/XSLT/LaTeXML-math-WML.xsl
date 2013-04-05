<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-math-ODT.xsl                                               |
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
    xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
    xmlns:text  = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    xmlns:xlink="http://www.w3.org/1999/xlink"
    exclude-result-prefixes = "ltx text xlink draw">

<!-- this does not even start to work; we really need a special post-processor for this
<xsl:template match="ltx:Math">
<draw:frame draw:style-name="fr1" draw:name="Object1" text:anchor-type="as-char" svg:y="-0.1811in" svg:width="1.0575in" svg:height="0.2508in" draw:z-index="0">
  <draw:object-ole xlink:href="./Object 1" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
  <draw:image xlink:href="./ObjectReplacements/Object 1" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
</draw:frame>
  <xsl:copy-of select="m:math"/>
</xsl:template>
-->

</xsl:stylesheet>

