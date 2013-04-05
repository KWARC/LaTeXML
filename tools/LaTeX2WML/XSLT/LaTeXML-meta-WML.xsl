<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  LaTeXML-meta-ODT.xsl                                               |
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
       Typically invisible meta elements
       ltx:note, ltx:indexmark, ltx:rdf, ltx:ERROR
       ====================================================================== -->

<!-- fix this when llncs.cls.ltxml is fixed -->
<xsl:template match="ltx:note[@role='institutetext']">
  <text:p text:style-name="address"><xsl:apply-templates/></text:p>
</xsl:template>

<xsl:template match="ltx:note[@role='footnote']">
  <text:note note-class="footnote">
    <text:note-citation><xsl:value-of select="@mark"/></text:note-citation>
    <text:note-body>
      <text:p text:style-name="Footnote"><xsl:apply-templates/></text:p>
    </text:note-body>
  </text:note>
</xsl:template>

<!-- eventually use this for generation of meta.xml? -->
<xsl:template match="ltx:rdf"/>

</xsl:stylesheet>

