<?xml version="1.0" encoding="UTF-8"?>
<!-- Honestly, I think this whole section can be replaced with exslt - but I need to check -->
<xsl:stylesheet version="1.0" xmlns:exslt="http://exslt.org/common" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rml="http://legostormtoopr/response">
	<xsl:output method="xml"/>
	<!--
		Author: Samuel Spencer
		Date: 2012-02-03
		Version: 1.0
		Assorted XSLT String functions

		Why is XSLT 2.0 not more widely available? :(
	-->
	<!--
		Test Case
		Splits a string, delimited by a single space, into a node list, then merges into comma-separated list.
		
		Illustrates:
			how to split strings
			how to split on whitespace
			how to join strings
	-->
	<xsl:template match="/">
		<test>
			<xsl:variable name="split">
				<xsl:call-template name="tokenize">
					<xsl:with-param name="string">1 2 3 4</xsl:with-param>
					<xsl:with-param name="token">
						<xsl:value-of select="' '"/>
					</xsl:with-param>
				</xsl:call-template>
			</xsl:variable>
			<xsl:call-template name="string-join">
				<xsl:with-param name="node-set">
					<xsl:copy-of select="$split"/>
				</xsl:with-param>
				<xsl:with-param name="token">,</xsl:with-param>
			</xsl:call-template>
		</test>
	</xsl:template>
	<!--
		Tokenize with a string and token allows us to split up string on a given token and return a node-set of all of the separate components in <match> tags.
		Example 1: 
			<xsl:call-template name="tokenize">
					<xsl:with-param name="string">1,2,3;4,5,6</xsl:with-param>
					<xsl:with-param name="token">;</xsl:with-param>
			</xsl:call-template>
			Returns:
			<match>1,2,3</match>
			<match>4,5,6</match>

		Example 2: 
			<xsl:call-template name="tokenize">
					<xsl:with-param name="string">1,2,3;4,5,6</xsl:with-param>
					<xsl:with-param name="token">,</xsl:with-param>
			</xsl:call-template>
			Returns:
			<match>1</match>
			<match>2</match>
			<match>3;4</match>
			<match>5</match>
			<match>6</match>

		Taken from: http://stackoverflow.com/a/141022/764357
		Then modified to use a generic split token.
	-->
	<xsl:template name="tokenize">
		<xsl:param name="string"/>
		<xsl:param name="token" select="','"/>
		<xsl:param name="count" select="0"/>
		<xsl:variable name="first_elem" select="substring-before(concat($string,$token), $token)"/>
		<!-- Make sure at least one token at the end exists -->
		<xsl:variable name="remaining" select="substring-after($string, $token)"/>
		<match>
			<xsl:value-of select="$first_elem"/>
		</match>
		<!--
			We check that the remaining list is not just a single token, if it is then the recursive base case has been identified.
		-->
		<xsl:if test="$remaining and $remaining != $token">
			<xsl:call-template name="tokenize">
				<xsl:with-param name="string" select="$remaining"/>
				<xsl:with-param name="token" select="$token"/>
				<xsl:with-param name="count" select="$count + 1"/>
			</xsl:call-template>
		</xsl:if>
	</xsl:template>
	<!--
		Concatenate a list of nodes, with a specific spearator between each string.
		Example 1: 
			<xsl:call-template name="string-join">
					<xsl:with-param name="string">
						<match>X</match>
						<match>Y</match>
					</xsl:with-param>
					<xsl:with-param name="token">,</xsl:with-param>
			</xsl:call-template>
			Returns:
				"X,Y"
	-->
	<xsl:template name="string-join">
		<xsl:param name="node-set"/>
		<xsl:param name="token" select="','"/>
		<xsl:value-of select="exslt:node-set($node-set)/*[position() = 1]"/>
		<xsl:for-each select="exslt:node-set($node-set)/*[position() > 1]">
			<xsl:value-of select="$token"/>
			<xsl:value-of select="node()"/>
		</xsl:for-each>
	</xsl:template>
</xsl:stylesheet>

