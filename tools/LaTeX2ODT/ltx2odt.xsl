<?xml version="1.0" encoding="utf-8"?>
<xsl:stylesheet 
  xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
  xmlns:ltx="http://dlmf.nist.gov/LaTeXML"
  xmlns:xlink="http://www.w3.org/1999/xlink"
  xmlns:office="urn:oasis:names:tc:opendocument:xmlns:office:1.0"
  xmlns:style="urn:oasis:names:tc:opendocument:xmlns:style:1.0"
  xmlns:text="urn:oasis:names:tc:opendocument:xmlns:text:1.0"
  xmlns:table="urn:oasis:names:tc:opendocument:xmlns:table:1.0"
  xmlns:draw="urn:oasis:names:tc:opendocument:xmlns:drawing:1.0"
  xmlns:svg="urn:oasis:names:tc:opendocument:xmlns:svg-compatible:1.0"
  xmlns:fo="urn:oasis:names:tc:opendocument:xmlns:xsl-fo-compatible:1.0"
  version="1.0">  
  
<xsl:output method="xml" indent="yes"/>
<xsl:strip-space elements="ltx:*"/>
<xsl:preserve-space elements="ltx:p"/>

<xsl:variable name="bib" select="//ltx:bibliography/@files"/>
<xsl:variable name="biblist" select="document(concat($bib,'.bib.ltxml'),.)//ltx:bibliography/ltx:biblist"/>

<!-- fallback for debugging -->
<xsl:template match="*">
  <xsl:message>cannot deal with element <xsl:value-of select="local-name()"/> yet!</xsl:message>
</xsl:template>

<xsl:template match="/">
  <xsl:comment>generated from LTXML</xsl:comment>
  <xsl:apply-templates/>
</xsl:template>

<xsl:template match="ltx:document">
  <office:document-content office:version="1.2">
    <office:scripts/>
    <xsl:copy-of select="document('minimal/font-face-decls.xml')//office:font-face-decls"/>
    <office:body>
      <office:text>
	<text:sequence-decls/>
	<xsl:apply-templates/>
      </office:text>
    </office:body>
  </office:document-content>
</xsl:template>

<!-- not appliccable -->
<xsl:template match="ltx:resource"/>

<xsl:template match="ltx:document/ltx:title">
  <text:p text:style-name="title"><xsl:apply-templates/></text:p>
</xsl:template>

<xsl:template match="ltx:creator[@role='author']">
  <text:p text:style-name="author"><xsl:apply-templates/></text:p>
</xsl:template>


<xsl:template match="ltx:date[@role='creation']">
  <text:p text:style-name="address"><xsl:apply-templates/></text:p>
</xsl:template>

<xsl:template match="ltx:personname"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:contact[@role='email']">
  <text:p text:style-name="email"><xsl:apply-templates/></text:p>
</xsl:template>

<!-- fix this when llncs.cls.ltxml is fixed -->
<xsl:template match="ltx:note[@role='institutetext']">
  <text:p text:style-name="address"><xsl:apply-templates/></text:p>
</xsl:template>

<xsl:template match="ltx:abstract">
  <text:p text:style-name="abstract">
    <text:span fo:font-weight="bold" style:font-weight-asian="bold"><xsl:value-of select="@name"/></text:span>
    <xsl:apply-templates/>
  </text:p>
</xsl:template>

<xsl:template match="ltx:keywords">
  <text:p text:style-name="abstract">
    <text:span text:style-name="boldtext"><xsl:value-of select="@name"/></text:span>
    <xsl:apply-templates/>
  </text:p>
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

<!-- there is no para concept in ODT, so skip -->
<xsl:template match="ltx:para"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:p">
  <text:p><xsl:apply-templates/></text:p>
</xsl:template>

<xsl:template match="ltx:p" mode="nop"><xsl:apply-templates/></xsl:template>

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
      <text:list-item text:style-name="bulletitem"><xsl:apply-templates/></text:list-item>
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
      <text:list-item text:style-name="numitem"><xsl:apply-templates/></text:list-item>
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

<xsl:template match="ltx:ref[@class='ltx_url' and @href]">
  <text:a xlink:type="simple" xlink:href="{@href}"><xsl:apply-templates/></text:a>
</xsl:template>

<!-- extend styles, this is the fallback -->
<!-- <xsl:template match="ltx:text">***<xsl:value-of select="@font"/></xsl:template> -->

<xsl:template match="ltx:text[@font='bold']">
  <text:span text:style-name="boldtext"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:text[@font='normal']"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:text[@font='italic']">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
</xsl:template>


<xsl:template match="ltx:text[@font='typewriter']">
  <text:span text:style-name="typewriter"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:emph">
  <text:span text:style-name="italictext"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:tabular">
  <table:table>
    <table:table-column table:number-columns-repeated="{count(ltx:thead/ltx:tr/ltx:td)}"/>
  <xsl:apply-templates/>
  </table:table>
</xsl:template>

<!-- there is no concept of a table head/body in ODT -->
<xsl:template match="ltx:thead|ltx:tbody"><xsl:apply-templates/></xsl:template>

<xsl:template match="ltx:tr">
  <table:table-row><xsl:apply-templates/></table:table-row>
</xsl:template>

<xsl:template match="ltx:td">
  <table:table-cell><text:p><xsl:apply-templates/></text:p></table:table-cell>
</xsl:template>


<xsl:template match="ltx:note[@role='footnote']">
  <text:note>
    <text:note-citation><xsl:value-of select="@mark"/></text:note-citation>
    <text:note-body>
      <text:p text:style-name="Footnote"><xsl:apply-templates/></text:p>
    </text:note-body>
  </text:note>
</xsl:template>

<xsl:template match="ltx:ref[@labelref]">
  <xsl:variable name="label" select="@labelref"/>
  <xsl:value-of select="//ltx:*[contains(@labels,$label)]/@refnum"/>
</xsl:template>

<!-- need width,height treatment and a treatment for frame styles-->
<xsl:template match="ltx:graphics">
  <text:p text:style-name="image">
    <draw:frame draw:style-name="Graphics" draw:name="graphics1" text:anchor-type="paragraph" draw:z-index="0">
      <draw:image xlink:href="Pictures/{@candidates}" xlink:type="simple" xlink:show="embed" xlink:actuate="onLoad"/>
     </draw:frame>
  </text:p>
</xsl:template>

<!-- need width,height treatment and a treatment for frame styles-->
<xsl:template match="ltx:figure">
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
  <text:span text:style-name="boldtext"><xsl:apply-templates/></text:span>
</xsl:template>

<xsl:template match="ltx:caption">
  <text:p text:style-name="figurecaption">
    <xsl:apply-templates/> 
  </text:p>
</xsl:template>
	      
<xsl:template match="ltx:cite">
  <!-- only works for one file now -->
  <xsl:for-each select="ltx:bibref/@bibrefs">
    <xsl:variable name="key" select="."/>
    <xsl:variable name="bibref" select="$biblist/ltx:bibentry[@key=$key]"/>
    <text:bibliography-mark text:identifier="{.}" text:bibliography-type="{$bibref/@type}">
      <xsl:if test="$bibref/ltx:bib-name">
	<xsl:attribute name="text:author">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-name)"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-title">
	<xsl:attribute name="text:title">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-title)"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-related[@role='host' and type='journal']">
	<xsl:attribute name="text:journal">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-related[@role='host' and type='journal']/ltx:bib-title)"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-date[@role='publication']">
	<xsl:attribute name="text:year">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-date[@role='publication'])"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-part[@role='pages']">
	<xsl:attribute name="text:year">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-part[@role='pages'])"/>
	</xsl:attribute>
      </xsl:if>
      <xsl:if test="$bibref/ltx:bib-publisher">
	<xsl:attribute name="text:year">
	  <xsl:value-of select="normalize-space($bibref/ltx:bib-publisher)"/>
	</xsl:attribute>
      </xsl:if>
	<!-- also text:address, text:annote, text:booktitle, text:chapter, text:edition,
	     text:editor, text:howpublished, text:identifier, text:institution, text:isbn,
	     text:issn, text:month, text:note, text:number, text:organizations,
	     text:report-type, text:school, text:series, text:url, text:volume -->
	<xsl:text>[</xsl:text>
	<xsl:value-of select="$key"/>
	<xsl:text>]</xsl:text>
    </text:bibliography-mark>
  </xsl:for-each>
</xsl:template>

<xsl:template match="ltx:break"><text:line-break/></xsl:template>


<xsl:template match="ltx:bibliography">
  <text:bibliography text:protected="true">
    <text:index-body>
      <text:index-title><text:p>Bibliography</text:p></text:index-title>
    </text:index-body>
  </text:bibliography>
</xsl:template>

<!-- eventually use this for generation of meta.xml? -->
<xsl:template match="ltx:rdf"/>

</xsl:stylesheet>
