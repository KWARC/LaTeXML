<?xml version="1.0" encoding="utf-8"?>
<!-- this style sheet transforms the tex.xml file to OMDoc   -->
<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns="http://docbook.org/ns/docbook"
		xmlns:ltx="http://dlmf.nist.gov/LaTeXML"
		xmlns:m="http://www.w3.org/1998/Math/MathML"
		xmlns:str="http://exslt.org/strings" 
		xmlns:xlink="http://www.w3.org/1999/xlink"
		extension-element-prefixes="str"
		exclude-result-prefixes="xsl ltx m xlink">

<xsl:output method="xml" indent="yes"/>
<xsl:strip-space elements="ltx:tabular ltx:tr ltx:td"/>
<xsl:template match="/">
  <xsl:comment>This DocBook document is generated from an sTeX-encoded one via LaTeXML, you may want to reconsider editing it.</xsl:comment>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:*">
  <xsl:message>cannot-deal with element <xsl:value-of select="local-name()"/> yet!</xsl:message>
</xsl:template>

<xsl:template match="ltx:document">
  <article version="5.0-subset Balisage-1.1">
    <xsl:apply-templates select="ltx:title"/>
    <info>
      <confgroup>
	<conftitle>Balisage: The Markup Conference</conftitle>
	<confdates>11 - 14 August 2009</confdates>
      </confgroup>
      <xsl:apply-templates select="ltx:abstract"/>
      <xsl:apply-templates select="ltx:creator"/>
    </info>
    <xsl:apply-templates select="ltx:section"/>
    <xsl:apply-templates select="ltx:bibliography"/>
  </article>
</xsl:template>

<xsl:template match="ltx:para">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:emph">
  <emphasis role="ital"><xsl:apply-templates/></emphasis>
</xsl:template>

<!-- from snippet -->
<xsl:template match="ltx:text[@font='typewriter']" mode="simple"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:text[@font='typewriter']">
  <command><xsl:apply-templates/></command>
</xsl:template>

<!-- from lstinline -->
<xsl:template match="ltx:text[@class='listing']">
  <literallayout><xsl:apply-templates/></literallayout>
</xsl:template>

<!-- we do not care about sizes -->
<xsl:template match="ltx:text[@size]">
  <xsl:apply-templates/>
</xsl:template>

<!-- this is only in titles-->
<xsl:template match="ltx:text[@font='bold']">
  <xsl:apply-templates/>
</xsl:template>

<!-- only in assertions -->
<xsl:template match="ltx:text[@font='italic']">
  <emphasis role="ital"><xsl:apply-templates/></emphasis>
</xsl:template>

<!-- otherwise disregrad -->
<xsl:template match="ltx:text">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:anchor">
  <xsl:apply-templates/><xsl:text>) </xsl:text>
</xsl:template>

<xsl:template match="ltx:p">
  <para><xsl:apply-templates/></para>
</xsl:template>

<!-- ****** -->
<xsl:template match="ltx:ref[@labelref]">
  <xref linkend="{translate(@labelref,':','.')}"/>
</xsl:template>

<xsl:template match="ltx:ref[@class='url']">
  <link xlink:type="simple" xlink:href="{@href}"><xsl:value-of select="@href"/></link>
</xsl:template>

<xsl:template match="ltx:bibblock/ltx:ref[@class='url']">
  <biblioid><link xlink:type="simple" xlink:href="{@href}"><xsl:value-of select="@href"/></link></biblioid>
</xsl:template>

<xsl:template match="ltx:figure">
  <figure floatstyle="1">
    <xsl:if test="@labels"><xsl:attribute name="xml:id"><xsl:value-of select="translate(@labels,':','.')"/></xsl:attribute></xsl:if>
    <xsl:attribute name="xreflabel"><xsl:text>Figure</xsl:text></xsl:attribute>
    <xsl:apply-templates select="ltx:caption"/>
    <mediaobject>
      <imageobject>
	<imagedata scale="100" format="application/pdf" fileref="{ltx:graphics/@graphic}.pdf"/>
      </imageobject>
    </mediaobject>
  </figure>
</xsl:template>

<xsl:template match="ltx:note[@class='footnote']">
  <footnote><para><xsl:apply-templates/></para></footnote>
</xsl:template>

<xsl:template match="ltx:abstract">
  <abstract><xsl:apply-templates/></abstract>
</xsl:template>

<xsl:template match="ltx:itemize">
  <itemizedlist><xsl:apply-templates/></itemizedlist>
</xsl:template>

<xsl:template match="ltx:enumerate">
  <itemizedlist><xsl:apply-templates/></itemizedlist>
</xsl:template>

<xsl:template match="ltx:description">
  <variablelist><xsl:apply-templates/></variablelist>
</xsl:template>

<xsl:template match="ltx:tag">
  <term><xsl:apply-templates/></term>
</xsl:template>

<xsl:template match="ltx:theorem">
  <formalpara>
    <xsl:if test="@labels"><xsl:attribute name="xml:id"><xsl:value-of select="translate(@labels,':','.')"/></xsl:attribute></xsl:if>
    <xsl:apply-templates select="ltx:title"/>
    <xsl:apply-templates select="*[local-name()!='title']/*"/>
  </formalpara>
</xsl:template>

<xsl:template match="ltx:description/ltx:item">
  <varlistentry>
    <xsl:apply-templates select="ltx:tag"/>
    <listitem><xsl:apply-templates select="ltx:para/*"/></listitem>
  </varlistentry>
</xsl:template>

<xsl:template match="ltx:item">
  <listitem><xsl:apply-templates select="ltx:para/*"/></listitem>
</xsl:template>

<xsl:template match="ltx:caption">
  <title><xsl:apply-templates/></title>
</xsl:template>

<xsl:template match="ltx:title">
  <title><xsl:apply-templates/></title>
</xsl:template>

<xsl:template match="ltx:cite">[<xsl:apply-templates select="ltx:bibref"/>]</xsl:template>
<xsl:template match="ltx:bibref">
  <xsl:for-each select="str:tokenize(@bibrefs,',')">
    <xref linkend="{translate(.,':','.')}"/>
    <xsl:if test="position()!=last()"><xsl:text>,</xsl:text></xsl:if>
  </xsl:for-each>
</xsl:template>

<xsl:template match="ltx:creator">
  <author><xsl:apply-templates select="ltx:personname/text()"/></author>
</xsl:template>

<xsl:template match="ltx:section|ltx:subsection|ltx:subsubsection|ltx:paragraph">
  <section>
    <xsl:if test="@labels"><xsl:attribute name="xml:id"><xsl:value-of select="translate(@labels,':','.')"/></xsl:attribute></xsl:if>
    <xsl:apply-templates/>
  </section>
</xsl:template>

<xsl:template match="ltx:Math[@mode='inline']">
  <inlineequation><xsl:copy-of select="*"/></inlineequation>
</xsl:template>

<!-- all others must be display -->
<xsl:template match="ltx:Math[@mode='display']">
  <informalequation><xsl:copy-of select="*"/></informalequation>
</xsl:template>

<xsl:template match="ltx:listingblock">
  <programlisting>
    <xsl:for-each select="ltx:tabular/ltx:tr/ltx:td[2]">
      <xsl:apply-templates/>
      <xsl:text>&#xA;</xsl:text>
    </xsl:for-each>
  </programlisting>
</xsl:template>

<xsl:template match="ltx:listing">
  <figure floatstyle="1">
    <xsl:if test="@labels"><xsl:attribute name="xml:id"><xsl:value-of select="translate(@labels,':','.')"/></xsl:attribute></xsl:if>
    <xsl:attribute name="xreflabel"><xsl:value-of select="ltx:caption"/></xsl:attribute>
    <xsl:apply-templates select="ltx:caption"/>
    <programlisting>
      <xsl:for-each select="ltx:tabular/ltx:tr/ltx:td[2]">
	<xsl:apply-templates/>
	<xsl:text>&#xA;</xsl:text>
      </xsl:for-each>
    </programlisting>
  </figure>
</xsl:template>

<xsl:template match="ltx:bibliography">
  <bibliography>
    <title>References</title>
    <xsl:apply-templates select="ltx:biblist/*"/>
  </bibliography>
</xsl:template>

<xsl:template match="ltx:bibitem">
  <bibliomixed>
    <xsl:variable name="key"><xsl:value-of select="translate(@key,':','.')"/></xsl:variable>
    <xsl:attribute name="xml:id"><xsl:value-of select="$key"/></xsl:attribute>
    <xsl:attribute name="xreflabel"><xsl:value-of select="ltx:bibtag"/></xsl:attribute>
    <xsl:apply-templates select="ltx:bibblock"/>
  </bibliomixed>
</xsl:template>


<xsl:template match="ltx:bibblock">
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:indexmark"/>
<xsl:template match="ltx:break"/>
</xsl:stylesheet>
