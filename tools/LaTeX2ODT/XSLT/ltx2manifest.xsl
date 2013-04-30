<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ltx="http://dlmf.nist.gov/LaTeXML"
  xmlns:manifest="urn:oasis:names:tc:opendocument:xmlns:manifest:1.0"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0" 
  version="1.0">  
  
<xsl:output method="xml" indent="yes"/>

<!-- fallback for debugging -->
<xsl:template match="*">
  <xsl:message>cannot deal with element <xsl:value-of select="local-name()"/> yet!</xsl:message>
</xsl:template>

<xsl:template match="/">
  <xsl:comment>generated from LTXML</xsl:comment>
  <manifest:manifest office:version="1.2">
    <manifest:file-entry manifest:media-type="application/vnd.oasis.opendocument.text" manifest:full-path="/"/>
    <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="content.xml"/>
    <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="meta.xml"/>
    <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="settings.xml"/>
    <manifest:file-entry manifest:media-type="text/xml" manifest:full-path="styles.xml"/> 
    <xsl:apply-templates select="//ltx:graphics"/>
    <xsl:apply-templates select="//ltx:Math"/>
  </manifest:manifest>
</xsl:template>

<xsl:template match="ltx:Math">
  <xsl:variable name="filename" select="substring-after(@imagesrc,'mi/')"/>
<!-- do not generate until we copy the MathML over
     <manifest:file-entry manifest:full-path="{$filename}/content.xml" manifest:media-type="text/xml"/>
     <manifest:file-entry manifest:full-path="{$filename}/" manifest:version="1.2" manifest:media-type="application/vnd.oasis.opendocument.formula"/>
-->
<!-- should we do something about settings (probably never)
     <manifest:file-entry manifest:full-path="${filename}/settings.xml" manifest:media-type="text/xml"/>-->
 <manifest:file-entry manifest:full-path="Pictures/{$filename}" manifest:media-type="image/png"/>
</xsl:template>

<xsl:template match="ltx:graphics">
  <manifest:file-entry manifest:full-path="Pictures/{@candidates}" manifest:media-type=""/>
</xsl:template>
	      
</xsl:stylesheet>
