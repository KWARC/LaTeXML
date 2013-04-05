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
    xmlns:text  = "urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    exclude-result-prefixes = "ltx text">

  <!-- ======================================================================
       Various Block-level elements:
       ltx:p, ltx:equation, ltx:equationgroup, ltx:quote, ltx:block,
       ltx:listingblock, ltx:itemize, ltx:enumerate, ltx:description
       ====================================================================== -->
<xsl:preserve-space elements="ltx:p"/>
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

<xsl:template match="ltx:itemize/ltx:item">
  <xsl:choose>
    <xsl:when test="ltx:tag">
      <text:list-item>
	<text:p>
	  <xsl:apply-templates select="ltx:tag"/>
	  <xsl:apply-templates select="ltx:para/ltx:p[1]" mode="nop"/>
	</text:p>
	<xsl:apply-templates select="ltx:para/ltx:p[position()&gt; 1]"/>
      </text:list-item>
    </xsl:when>
    <xsl:otherwise>
      <text:list-item><xsl:apply-templates/></text:list-item>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="ltx:enumerate/ltx:item">
  <xsl:choose>
    <xsl:when test="ltx:tag">
      <text:list-item>
	<text:p>
	  <xsl:apply-templates select="ltx:tag"/>
	  <xsl:apply-templates select="ltx:para/ltx:p[1]" mode="nop"/>
	</text:p>
	<xsl:apply-templates select="ltx:para/ltx:p[position()&gt; 1]"/>
      </text:list-item>
    </xsl:when>
    <xsl:otherwise>
      <text:list-item><xsl:apply-templates/></text:list-item>
    </xsl:otherwise>
  </xsl:choose>
</xsl:template>

<xsl:template match="ltx:enumerate/ltx:item">
  <text:list-item>
    <text:p>
      <xsl:apply-templates select="ltx:tag"/>
      <xsl:apply-templates select="ltx:para/ltx:p[1]" mode="nop"/>
    </text:p>
    <xsl:apply-templates select="ltx:para/ltx:p[position()&gt; 1]"/>
  </text:list-item>
</xsl:template>

<xsl:template match="ltx:description/ltx:item">
  <text:list-item><xsl:apply-templates/></text:list-item>
</xsl:template>

<xsl:template match="ltx:item/ltx:tag">
  <text:span text:style-name="boldtext"><xsl:apply-templates/></text:span>
</xsl:template>
    
</xsl:stylesheet>

