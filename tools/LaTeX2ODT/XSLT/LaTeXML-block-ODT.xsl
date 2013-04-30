<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-block-ODT.xsl                                              |
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
    xmlns:text  = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    exclude-result-prefixes = "ltx text table">

  <!-- ======================================================================
       Various Block-level elements:
       ltx:p, ltx:equation, ltx:equationgroup, ltx:quote, ltx:block,
       ltx:listingblock, ltx:itemize, ltx:enumerate, ltx:description
       ====================================================================== -->
<xsl:preserve-space elements="ltx:p ltx:text"/>
<xsl:strip-space elements="ltx:*"/>


<xsl:template match="ltx:p">
  <text:p><xsl:apply-templates/></text:p>
</xsl:template>

<xsl:template match="ltx:p" mode="nop"><xsl:apply-templates/></xsl:template>
<xsl:template match="ltx:p" mode="abstract">
  <text:p text:style-name="abstract"><xsl:apply-templates/></text:p>
</xsl:template>

<xsl:template match="ltx:itemize">
  <text:list text:style-name="WW8Num13"><xsl:apply-templates/></text:list>
</xsl:template>

<xsl:template match="ltx:enumerate">
  <text:list text:style-name="WW8Num16"><xsl:apply-templates/></text:list>
</xsl:template>

<!-- not sure which style to use here -->
<xsl:template match="ltx:description">
  <text:list text:style-name="WW8Num13"><xsl:apply-templates/></text:list>
</xsl:template>

<xsl:template match="ltx:itemize/ltx:item|ltx:enumerate/ltx:item|ltx:description/ltx:item">
  <xsl:choose>
    <xsl:when test="ltx:tag">
      <text:list-item>
	<text:p>
	  <xsl:apply-templates select="ltx:tag"/>
	  <xsl:apply-templates select="ltx:para[1]/*[1]" mode="nop"/>
	</text:p>
	<xsl:apply-templates select="ltx:para[1]/*[position()&gt; 1]"/>
	<xsl:apply-templates select="*[position()&gt; 1]"/>
      </text:list-item>
    </xsl:when>
    <xsl:otherwise>
      <text:list-item><xsl:apply-templates/></text:list-item>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>


<xsl:template match="ltx:item/ltx:tag">
  <text:span text:style-name="boldtext"><xsl:apply-templates/></text:span>
  <xsl:text> </xsl:text>
</xsl:template>

<xsl:template match="ltx:inline-block">
  <xsl:apply-templates/>
</xsl:template>

<!-- **fixme** (remove mode) when the generated markup is more sane -->
<!-- this seems to be used for inparaenum and friends -->
<xsl:template match="ltx:text[ltx:anchor]">
  <xsl:apply-templates mode="paralist"/>
</xsl:template>
<xsl:template match="ltx:text" mode="paralist">
  <xsl:apply-templates mode="paralist"/>
</xsl:template>
<xsl:template match="ltx:anchor" mode="paralist">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
  <xsl:text> </xsl:text>
</xsl:template>
<!-- ** end fixme ** -->

<xsl:template match="ltx:quote">
  <xsl:apply-templates mode="quote"/>
</xsl:template>

<xsl:template match="ltx:p" mode="quote">
 <text:p text:style-name="quote"><xsl:apply-templates/></text:p>
</xsl:template>

<!-- we flatten out the listings table structure -->
<xsl:template match="ltx:listingblock">
  <xsl:apply-templates mode="listing"/>
</xsl:template>

<xsl:template match="ltx:tr" mode="listing">
  <xsl:apply-templates mode="listing"/>
  <xsl:text>&#xA;</xsl:text>
</xsl:template>    

<xsl:template match="ltx:table|ltx:td|ltx:text" mode="listing">
  <xsl:apply-templates mode="listing"/>
</xsl:template>

<!-- display math -->
<xsl:template match="ltx:equation">
  <text:p text:style-name="abstract"><xsl:apply-templates/></text:p>
</xsl:template>

<!-- a real equation -->
<xsl:template match="ltx:equation">
  <table:table>
    <table:table-row>
      <table:table-cell>
	<text:p text:style-name="abstract"><xsl:apply-templates/></text:p>
      </table:table-cell>
      <table:table-cell>
	<text:p><xsl:value-of select="@frefnum"/></text:p>
      </table:table-cell>
    </table:table-row>
  </table:table>
</xsl:template>

</xsl:stylesheet>

