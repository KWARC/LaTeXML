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
    xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0" 
    xmlns:xlink="http://www.w3.org/1999/xlink"
    xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
    xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
    exclude-result-prefixes = "ltx text xlink draw m svg style fo">

<!-- this does not even start to work; we really need a special post-processor for this
<xsl:template match="ltx:Math">
  <xsl:variable name="mo" select="count(preceding::ltx:Math)+1"/>
  <draw:frame draw:style-name="fr1" draw:name="{concat('Object ',$mo)}" 
	      text:anchor-type="as-char" 
	      svg:y="-0.1811in" svg:width="1.0575in" svg:height="0.2508in" 
	      draw:z-index="0">
    <draw:object-ole xlink:href="{concat('Object ',$mo)}" 
		     xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
    <draw:image xlink:href="./ObjectReplacements/{concat('Object ',$mo)}" 
		xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
  </draw:frame>
  <xsl:copy-of select="m:math"/>
</xsl:template> -->

<xsl:template match="ltx:Math">
  <xsl:variable name="filename" select="substring-after(@imagesrc,'mi/')"/>
  <draw:frame draw:style-name="formula-{substring-before($filename,'.png')}" draw:name="{$filename}" 
	      text:anchor-type="as-char" 
	      svg:y="{-@imagedepth * .75}px" svg:width="{@imagewidth * .75}px" svg:height="{@imageheight * .75}px" 
	      draw:z-index="0">
    <draw:image xlink:href="Pictures/{$filename}" 
		xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
  </draw:frame>
</xsl:template>

<xsl:template match="ltx:Math" mode="automatic-styles">
  <xsl:variable name="filename" select="substring-before(substring-after(@imagesrc,'mi/'),'.png')"/>
  <style:style name="formula-{$filename}" style:family="graphic" style:parent-style-name="Graphics">
      <style:graphic-properties TexMathsArgs="{@tex}"
				fo:margin-top="0in" fo:margin-bottom="0in" 
				style:vertical-pos="from-top" style:horizontal-pos="center" style:horizontal-rel="paragraph" 
				style:mirror="none"/> 
  </style:style>
</xsl:template>
</xsl:stylesheet>

