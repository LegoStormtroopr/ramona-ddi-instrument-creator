<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:exslt="http://exslt.org/common"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events"
	xmlns:ddi="ddi:instance:3_1" xmlns:a="ddi:archive:3_1" xmlns:r="ddi:reusable:3_1" xmlns:dc="ddi:dcelements:3_1" xmlns:ns7="http://purl.org/dc/elements/1.1/" xmlns:cm="ddi:comparative:3_1" xmlns:d="ddi:datacollection:3_1" xmlns:l="ddi:logicalproduct:3_1" xmlns:c="ddi:conceptualcomponent:3_1" xmlns:ds="ddi:dataset:3_1" xmlns:p="ddi:physicaldataproduct:3_1" xmlns:pr="ddi:ddiprofile:3_1" xmlns:s="ddi:studyunit:3_1" xmlns:g="ddi:group:3_1" xmlns:pi="ddi:physicalinstance:3_1" xmlns:m3="ddi:physicaldataproduct_ncube_inline:3_1" xmlns:m1="ddi:physicaldataproduct_ncube_normal:3_1" xmlns:m2="ddi:physicaldataproduct_ncube_tabular:3_1"
	xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xf="http://www.w3.org/2002/xforms"
	xmlns:rml="http://legostormtoopr/response" xmlns:skip="http://legostormtoopr/skips" extension-element-prefixes="exslt"
	exclude-result-prefixes="ddi a r dc ns7 cm d l c ds p pr s g pi m3 m1 m2 exslt skip fo xs">
	<xsl:import href="./DDI_to_ResponseML.xsl"/>

	<xsl:template match="/">
		<html>
			<body>
				<!-- xsl:apply-templates select="$instrumentModel" mode="cleanr"/ -->
			<xsl:variable name="skips">
				<xsl:call-template name="makeSkips2">
					<xsl:with-param name="doc" select="$instrumentModel"/>
				</xsl:call-template>
			</xsl:variable>
			<xsl:element name="img">
				<xsl:attribute name="src">https://chart.googleapis.com/chart?chl=digraph x %7B<xsl:apply-templates select="exslt:node-set($skips)//skips2//skip:link"  mode="graphBuilder"/>%7D&amp;cht=gv</xsl:attribute>
			</xsl:element>
			<xsl:element name="img">
				<xsl:attribute name="src">https://chart.googleapis.com/chart?chl=digraph x %7B<xsl:apply-templates select="exslt:node-set($skips)//skip:skips/*"  mode="graphBuilder2"/>%7D&amp;cht=gv</xsl:attribute>
			</xsl:element>
			<pre><xsl:copy-of select="$skips"/>
				<xsl:copy-of select="exslt:node-set($instrumentModel)"/>
			</pre>
			</body>
		</html>
	</xsl:template>


	<xsl:template match="d:Instrument">
		<xsl:apply-templates select="//d:Instrument" mode="graphBuilder"/>
	</xsl:template>

	<xsl:template match="d:Instrument" mode="graphBuilder">
			<xsl:variable name="skips">
				<xsl:call-template name="makeSkips2">
					<xsl:with-param name="doc" select="$instrumentModel"/>
				</xsl:call-template>
			</xsl:variable>digraph x %7B<xsl:apply-templates select="exslt:node-set($skips)//skips2//skip:link"  mode="graphBuilder"/>%7D
	</xsl:template>
	<!-- xsl:template match="d:Instrument" mode="graphBuilder">
		<xsl:variable name="skips">
			<xsl:call-template name="makeSkips">
				<xsl:with-param name="doc">
					<xsl:copy-of select="$instrumentModel"/>
				</xsl:with-param>
			</xsl:call-template>
		</xsl:variable>digraph x %7B<xsl:apply-templates select="exslt:node-set($skips)/skip:link"  mode="graphBuilder"/>%7D
		<! - - xsl:copy-of select="$skips"/ - ->
	</xsl:template -->
	
	<xsl:template match="skip:link" mode="graphBuilder"><xsl:variable name="from" select="@from"/><xsl:variable name="to" select="@to"/>"<xsl:value-of select="exslt:node-set($numbers)/question[@qcID=$from]"/>"-%3E"<xsl:value-of select="exslt:node-set($numbers)/question[@qcID=$to]"/>";</xsl:template>
	<xsl:template match="skip:link" mode="graphBuilder2">"<xsl:value-of select="@from"/>"-%3E"<xsl:value-of select="@to"/>";</xsl:template>
	<xsl:template match="skip:sequenceGuide" mode="graphBuilder2"><xsl:variable name="from" select="@from"/>"<xsl:value-of select="@from"/>" [shape=diamond];<xsl:for-each select="skip:link">"<xsl:value-of select="$from"/>"-%3E"<xsl:value-of select="@to"/>";</xsl:for-each></xsl:template>
</xsl:stylesheet>
