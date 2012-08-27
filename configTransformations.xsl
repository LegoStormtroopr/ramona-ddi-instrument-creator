<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:exslt="http://exslt.org/common"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:cfg="rml:RamonaConfig_v1"
    xmlns:msxsl="urn:schemas-microsoft-com:xslt"
    exclude-result-prefixes="exslt msxsl cfg xs"
    extension-element-prefixes="exslt">
    <xsl:template match="cfg:style">
        <xsl:element name="xhtml:link">
            <xsl:attribute name="rel">stylesheet</xsl:attribute>
            <xsl:attribute name="type">text/css</xsl:attribute>
            <xsl:attribute name="href">
                <xsl:if test="./@relative=true()">
                    <xsl:value-of select="$config/cfg:rootURN"/>/themes/<xsl:value-of select="$config/cfg:themeName"/>
                </xsl:if>/<xsl:value-of select="."/>
            </xsl:attribute>
        </xsl:element>
    </xsl:template>
    <xsl:template match="cfg:logo">
        <xsl:element name="xhtml:img">
            <xsl:attribute name="src">
                <xsl:if test="@relative=true()">
                    <xsl:value-of select="$config/cfg:rootURN"/>/themes/<xsl:value-of select="$config/cfg:themeName"/>
                </xsl:if>/<xsl:value-of select="."/>
            </xsl:attribute>
            <xsl:attribute name="width"><xsl:value-of select="@width"/></xsl:attribute>
            <xsl:attribute name="height"><xsl:value-of select="@height"/></xsl:attribute>
            <xsl:attribute name="class">logo</xsl:attribute>
        </xsl:element>
    </xsl:template>
</xsl:stylesheet>