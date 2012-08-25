<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0"
    xmlns:exslt="http://exslt.org/common"
    xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:fn="http://www.w3.org/2005/xpath-functions"
    xmlns:r="ddi:reusable:3_1"
    xmlns:xhtml="http://www.w3.org/1999/xhtml"
    xmlns:cfg="rml:RamonaConfig_v1"
    exclude-result-prefixes="r exslt cfg"
    extension-element-prefixes="exslt">
    <xsl:template match="/">
        <xsl:apply-templates select="//r:SourceQuestionReference[1]"/>
    </xsl:template>
    <xsl:template match="*" mode="DDIReferenceResolver_3_1">
        <xsl:param name="mode" select="'local'"/>
        <xsl:variable name="id">
            <xsl:value-of select="r:ID"/>
        </xsl:variable>
        <xsl:variable name="v">
            <xsl:value-of select="r:Version"/>
        </xsl:variable>
        <xsl:variable name="a">
            <xsl:value-of select="r:IdentifyingAgency"/>
        </xsl:variable>
        <xsl:choose>
            <xsl:when test="r:URN">
                <xsl:value-of select="r:URN"/>
            </xsl:when>
            <xsl:when test="$mode = 'local'" >
                <xsl:apply-templates select="//*[@id=$id and ($v='' or @version = $v)][1]"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:comment>
                    <xsl:copy-of select="."/>
                </xsl:comment>
            </xsl:otherwise>            
        </xsl:choose>        
    </xsl:template>
</xsl:stylesheet>