<?xml version="1.0" encoding="utf-8"?>
<!--
/=====================================================================\ 
|  Common utility functions for stylesheet; for inclusion             |
|=====================================================================|
| Part of LaTeXML:                                                    |
|  Public domain software, produced as part of work done by the       |
|  United States Government & not subject to copyright in the US.     |
|=====================================================================|
| Bruce Miller <bruce.miller@nist.gov>                        #_#     |
| http://dlmf.nist.gov/LaTeXML/                              (o o)    |
\=========================================================ooo==U==ooo=/
-->
<xsl:stylesheet
    version     = "1.0"
    xmlns:xsl   = "http://www.w3.org/1999/XSL/Transform"
    xmlns:ltx   = "http://dlmf.nist.gov/LaTeXML"
    xmlns:string= "http://exslt.org/strings"
    xmlns:func  = "http://exslt.org/functions"
    xmlns:f     = "http://dlmf.nist.gov/LaTeXML/functions"
    extension-element-prefixes="func f"
    exclude-result-prefixes = "ltx f func string">

  <!-- Copy ID info from latexml elements to generated element.-->
  <xsl:template name="add_id">
    <xsl:if test="@fragid">
      <xsl:attribute name="id"><xsl:value-of select="@fragid"/></xsl:attribute>
    </xsl:if>
  </xsl:template>

  <!-- Add the various common attributes to the html element being generated
       according to the attributes of the context node.
       This is an entry point for extensibilty.
       Would be nice if we could make provision for "extra classes",
       then we could incorporate the class attribute, as well.
       -->
  <xsl:template name="add_attributes">
    <xsl:param name="extra_classes" select="''"/>
    <xsl:param name="extra_style" select="''"/>
    <xsl:call-template name="add_classes">
      <xsl:with-param name="extra_classes" select="string($extra_classes)"/>
    </xsl:call-template>
    <xsl:call-template name="add_style">
      <xsl:with-param name="extra_style" select="string($extra_style)"/>
    </xsl:call-template>
  </xsl:template>


  <!-- Three-way if as function: f:if(test,iftrue,iffalse)
       Returns either the iftrue or iffalse branch, depending on test. -->
  <func:function name="f:if">
    <xsl:param name="test"/>
    <xsl:param name="iftrue"/>
    <xsl:param name="iffalse"/>
    <xsl:choose>
      <xsl:when test="$test"><func:result><xsl:value-of select="$iftrue"/></func:result></xsl:when>
      <xsl:otherwise><func:result><xsl:value-of select="$iffalse"/></func:result></xsl:otherwise>
    </xsl:choose>
  </func:function>

  <!-- Add a class attribute value to the current html element
       according to the attributes of the context element:
       * the element name (this should be prefixed somehow!!!)
       * the class attribute
       * attributes in the Fontable.attribute set
       * content passed in via the parameter $extra_classes.
  -->
  <xsl:template name="add_classes">
    <xsl:param name="extra_classes" select="''"/>
      <xsl:attribute name="class">
	<xsl:value-of
	    select="concat(local-name(.),
		           f:if(@class,concat(' ',@class),''),
			   f:if(@font,concat(' ',@font),''),
			   f:if(@fontsize,concat(' ',@fontsize),''),
			   f:if($extra_classes,concat(' ',$extra_classes),'')
			 )"/>
      </xsl:attribute>
  </xsl:template>

  <!-- template add_style adds a css style attribute to the current html element
       according to attributes of the context node.
       * Positionable.attributes
       * Colorable.attributes

       Note that width & height (& padding versions)
       will be ignored in most cases... silly CSS.
       Note that some attributes clash because they're setting
       the same CSS property; there's no combining here (yet?).   
  -->
  <xsl:template name="add_style">
    <xsl:param name="extra_style" select="''"/>
    <xsl:if test="@float or @width or @height or @pad-width or @pad-height or @xoffset or @yoffset
		  or @color or @backgroundcolor or @opacity or @framed or @aligned or @vattach
		  or @imagedepth or boolean($extra_style)">
      <xsl:attribute name="style">
	<xsl:if test="@float">
	  <xsl:value-of select="concat('float:',@float,';')"/>
	</xsl:if>
	<xsl:if test="@width">
	  <xsl:value-of select="concat('width:',@width,';')"/>
	</xsl:if>
	<xsl:if test="@height">
	  <xsl:value-of select="concat('height:',@height,';')"/>
	</xsl:if>
	<xsl:if test="@depth">
	  <xsl:value-of select="concat('vertical-align:',@depth,';')"/>
	</xsl:if>
	<xsl:if test="@pad-width">
	  <xsl:value-of select="concat('height:',@pad-width,';')"/>
	</xsl:if>
	<xsl:if test="@pad-height">
	  <xsl:value-of select="concat('height:',@pad-height,';')"/>
	</xsl:if>
	<xsl:if test="@xoffset">
	  <xsl:value-of select="concat('position:relative; left:',@xoffset,';')"/>
	</xsl:if>
	<xsl:if test="@yoffset">
	  <xsl:value-of select="concat('position:relative; bottom:',@yoffset,';')"/>
	</xsl:if>
	<xsl:if test="@color">
	  <xsl:value-of select="concat('color:',@color,';')"/>
	</xsl:if>
	<xsl:if test="@backgroundcolor">
	  <xsl:value-of select="concat('background-color:',@backgroundcolor,';')"/>
	</xsl:if>
	<xsl:if test="@opacity">
	  <xsl:value-of select="concat('opacity:',@opacity,';')"/>
	</xsl:if>
	<xsl:if test="@framed='rectangle'">
	  <xsl:value-of select="'border:1px solid black;'"/>
	</xsl:if>
	<xsl:if test="@framed='underline'">
	  <xsl:value-of select="'text-decoration:underline;'"/>
	</xsl:if>
	<xsl:if test="@align">
	  <xsl:value-of select="concat('text-align:',@align,';')"/>
	</xsl:if>
	<xsl:if test="@vattach">
	  <xsl:value-of select="concat('vertical-align:',@vattach,';')"/>
	</xsl:if>
	<xsl:if test="$extra_style">
	  <xsl:value-of select="$extra_style"/>
	</xsl:if>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>

<!--
  <xsl:template name="add_style">
    <xsl:param name="extra_style" select="''"/>
    <xsl:if test="@float or @width or @height or @pad-width or @pad-height or @xoffset or @yoffset
		  or @color or @backgroundcolor or @opacity or @framed or @aligned or @vattach
		  or @imagedepth or boolean($extra_style)">
      <xsl:attribute name="style">
	<xsl:value-of
	    select="concat(f:if(@float,     concat('float:',@float,';'),''),
		           f:if(@width,     concat('width:',@width,';'),''),
			   f:if(@height,    concat('height:',@height,';'),''),
			   f:if(@depth,     concat('vertical-align:',@depth,';'),''),
			   f:if(@pad-width, concat('height:',@pad-width,';'),''),
			   f:if(@pad-height,concat('height:',@pad-height,';'),''),
			   f:if(@xoffset,   concat('position:relative; left:',@xoffset,';'),''),
		           f:if(@yoffset,   concat('position:relative; bottom:',@yoffset,';'),''),
		           f:if(@color,     concat('color:',@color,';'),''),
			   f:if(@backgroundcolor,concat('background-color:',@backgroundcolor,';'),''),
		           f:if(@opacity,   concat('opacity:',@opacity,';'),''),
			   f:if(@framed = 'rectangle','border:1px solid black;',''),
			   f:if(@framed = 'underline','text-decoration:underline;',''),
			   f:if(@align,     concat('text-align:',@align,';'),''),
			   f:if(@vattach,   concat('vertical-align:',@vattach,';'),''),
			   f:if($extra_style,concat($extra_style,';'),'')
			 )"/>
      </xsl:attribute>
    </xsl:if>
  </xsl:template>
-->

</xsl:stylesheet>

