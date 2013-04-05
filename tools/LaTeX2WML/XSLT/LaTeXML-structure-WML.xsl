<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-structure-ODT.xsl                                               |
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
    xmlns:w="http://schemas.openxmlformats.org/wordprocessingml/2006/main"
    xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
    xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
    exclude-result-prefixes = "ltx w">

  <!-- ======================================================================
       Document Structure
       ====================================================================== -->


<xsl:template match="ltx:document">
  <w:document>
    <w:body>
      <xsl:apply-templates/>
    </w:body>
  </w:document>
</xsl:template>

<!-- not appliccable -->
<xsl:template match="ltx:resource"/>

<xsl:template match="ltx:document/ltx:title">
  <w:p>
    <w:Pr><w:pStyle w:val="style67"/></w:Pr>
    <w:r>
      <w:rPr/>
      <w:t><xsl:apply-templates/></w:t>
    </w:r>
  </w:p>
</xsl:template>

<xsl:template match="ltx:section|ltx:subsection|ltx:subsubsection">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:section/ltx:title">
  <text:h text:outline-level="1"><xsl:apply-templates/></text:h>
</xsl:template>

<xsl:template match="ltx:subsection/ltx:title">
  <text:h text:outline-level="2"><xsl:apply-templates/></text:h>
</xsl:template>

<xsl:template match="ltx:subsubsection/ltx:title">
  <text:h text:outline-level="3"><xsl:apply-templates/></text:h>
</xsl:template>

<!-- do not show tags in titles -->
<xsl:template match="ltx:title/ltx:tag"/>

<xsl:template match="ltx:abstract">
  <text:p text:style-name="abstract">
    <text:span text:style-name="boldtext"><xsl:value-of select="@name"/>: </text:span>
    <xsl:apply-templates select="ltx:p[1]" mode="nop"/>
  </text:p>
  <xsl:apply-templates select="ltx:p[position()&gt;1]" mode="abstract"/>
</xsl:template>

<xsl:template match="ltx:keywords">
  <text:p text:style-name="abstract">
    <text:span text:style-name="boldtext"><xsl:value-of select="@name"/>: </text:span>
    <xsl:apply-templates/>
  </text:p>
</xsl:template>

<xsl:template match="ltx:creator[@role='author']">
  <w:p>
    <w:Pr><w:pStyle w:val="style68"/></w:Pr>
    <w:r>
      <w:rPr/>
      <w:t><xsl:apply-templates/></w:t>
    </w:r>
  </w:p>
</xsl:template>


<xsl:template match="ltx:date[@role='creation']">
  <w:p>
    <w:Pr><w:pStyle w:val="style68"/></w:Pr>
    <w:r>
      <w:rPr/>
      <w:t><xsl:apply-templates/></w:t>
    </w:r>
  </w:p>
</xsl:template>

<xsl:template match="ltx:personname"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:contact[@role='email']">
  <w:p>
    <w:Pr><w:pStyle w:val="style39"/></w:Pr>
    <w:r>
      <w:rPr/>
      <w:t><xsl:apply-templates/></w:t>
    </w:r>
  </w:p>
</xsl:template>

<xsl:variable name="bib" select="//ltx:bibliography/@files"/>
<xsl:variable name="biblist" select="document(concat($bib,'.bib.ltxml'),.)//ltx:bibliography/ltx:biblist"/>

<xsl:template match="ltx:bibliography">
  <w:p>
    <w:Pr><w:pStyle w:val="style39"/></w:Pr>
    <w:r>
      <w:rPr/>
      <w:t>elided References</w:t>
    </w:r>
  </w:p>
<!--   <text:bibliography text:protected="true" name="Rererences1">
    <text:index-body>
      <text:index-title><text:p>References</text:p></text:index-title>
    </text:index-body>
  </text:bibliography>-->
</xsl:template>

</xsl:stylesheet>

