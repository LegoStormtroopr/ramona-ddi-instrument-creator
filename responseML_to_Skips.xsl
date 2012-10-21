<?xml version="1.0" encoding="UTF-8"?>
<!-- edited with XMLSpy v2011 rel. 3 (http://www.altova.com) by .PCSoft (Australian Bureau of Statistics) -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rml="http://legostormtoopr/response" xmlns:skip="http://legostormtoopr/skips" xmlns:exslt="http://exslt.org/common">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<!-- The main template of this file is this section which begins the transformation of the hierarchical ResponseML into a skip based graph.
		 This graph then assists with the creation of the 'Go To' isntructions seen on web and paper forms.
	-->
	
	<xsl:template name="makeSkips">
		<xsl:param name="doc"/>
		<xsl:variable name="cleand">
			<!-- Firstly we clean up the rml:instrument, leaving only ifs,loops,responses and conditions - everything else isn't needed for computing the skips. The mode is called cleanr and the variable cleand, because dropping vowels is so damn Web2.0. -->
			<xsl:apply-templates select="exslt:node-set($doc)" mode="cleanr"/>
		</xsl:variable>
		<xsl:variable name="seqGuide">
			<!--
				Now we make the first pass, and link things in the hierarchy, to the next object. Either their next sibling or their closest 'uncle' - i.e. the first sibling of ancestor.
				We convert if/then/elseif/else constructs to sequence guides.

				TODO: Loops (YOLO)
			-->
			<skip:skips>
				<xsl:apply-templates select="exslt:node-set($cleand)" mode="toSequenceGuides"/>
			</skip:skips>
		</xsl:variable>
		<xsl:variable name="seqGuide2">
			<skips2>
				<xsl:apply-templates select="exslt:node-set($seqGuide)/skip:skips/*[1]" mode="removeSequenceGuides"/>
			</skips2>
		</xsl:variable>
		<xsl:copy-of select="$seqGuide"/>
		<xsl:copy-of select="$seqGuide2"/>
	</xsl:template>
	<xsl:template match="skip:link" mode="removeSequenceGuides">
		<xsl:variable name="from" select="@from"/>
		<xsl:variable name="to" select="@to"/>
		<xsl:variable name="next" select="following-sibling::*[1]"/>
		<xsl:choose>
		<!--
				Now we try to remove sequence guides, if possible.
				At present this is met by the condition - IF a link X is immediately followed by a sequenceGuide Y, AND X is a path to Y, AND X is the only path to the sequence guide AND all of Ys conditions only depend on X, then replace Y with the required number of links, otherwise keep X and Y as they are.
				We do this recursively, because we may have to jump things.
			-->
		<xsl:when test="	local-name($next) = 'sequenceGuide'
							and	$next/@from = $to
							and	count(//*[@to=$to]) = 1
							and	count($next/skip:condition) = count($next/skip:condition[@question=$to])
			  ">
				<xsl:for-each select="$next/skip:link">
					<xsl:element name="skip:link">
						<xsl:attribute name="from"><xsl:value-of select="$from"/></xsl:attribute>
						<xsl:attribute name="to"><xsl:value-of select="@to"/></xsl:attribute>
						<xsl:attribute name="condition">
							<xsl:choose>
								<xsl:when test="count(skip:condition) > 0"><xsl:value-of select="."/></xsl:when>
								<xsl:otherwise>otherwise</xsl:otherwise>
							</xsl:choose>
						</xsl:attribute>
					</xsl:element>
				</xsl:for-each>
				<xsl:apply-templates select="following-sibling::*[2]" mode="removeSequenceGuides"/>
			</xsl:when>
			<xsl:otherwise>
				<xsl:copy-of select="."/>
				<xsl:apply-templates select="following-sibling::*[1]" mode="removeSequenceGuides"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="skip:loop" mode="removeSequenceGuides">
		<xsl:copy />
		<xsl:apply-templates select="following-sibling::*[1]" mode="removeSequenceGuides"/>
	</xsl:template>
	<xsl:template match="skip:sequenceGuide" mode="removeSequenceGuides">
		<xsl:copy-of select="."/>
		<xsl:apply-templates select="following-sibling::*[1]" mode="removeSequenceGuides"/>
	</xsl:template>
	
	
	<!--	Remove everything that isn't an if,loop or question/response as they are unneccessary for creating skips paths. -->
	<xsl:template match="@*|node()" mode="cleanr">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="cleanr"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="rml:sequence" mode="cleanr">
		<xsl:apply-templates select="node()" mode="cleanr"/>
	</xsl:template>
	<xsl:template match="rml:multipart" mode="cleanr"/>
	
	<xsl:template match="rml:loop" mode="toSequenceGuides">
		<xsl:element name="skip:loop">
			<xsl:attribute name="from">
				<xsl:value-of select="@id"/>
			</xsl:attribute>
			<xsl:attribute name="to">
				<xsl:choose>
					<xsl:when test="count(following-sibling::*) > 0">
						<xsl:value-of select="following-sibling::*[1]/@id"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- get the first next element THAT IS INSIDE THIS LOOP -->
						<xsl:for-each select="ancestor-or-self::*[count(following-sibling::*)>0 and attribute::id][1]">
							<xsl:value-of select="following-sibling::*[1]/@id"/>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
			<xsl:apply-templates select="*" mode="toSequenceGuides"/>		
		</xsl:element>
	</xsl:template>
	<xsl:template match="rml:if" mode="toSequenceGuides">
		<!-- There is always a then, so we always will link to the then "child" -->
		<xsl:element name="skip:sequenceGuide">
			<xsl:attribute name="from">
				<xsl:value-of select="@id"/>
			</xsl:attribute>
			<xsl:element name="skip:link">
				<xsl:attribute name="to">
					<xsl:value-of select="rml:then/*[1]/@id"/>
				</xsl:attribute>
				<xsl:apply-templates select="rml:osc/*" mode="toSequenceGuides"/>
			</xsl:element>
			<!-- If there are elseifs, process them to, just like above -->
			<xsl:for-each select="rml:elseif">
				<xsl:element name="skip:link">
					<xsl:attribute name="to">
						<xsl:value-of select="rml:then/*[1]/@id"/>
					</xsl:attribute>
					<xsl:apply-templates select="rml:osc/*" mode="toSequenceGuides"/>
				</xsl:element>
			</xsl:for-each>
			<!-- The tricky bit - is there an else or not? -->
			<xsl:choose>
				<xsl:when test="count(rml:else) > 0">
					<xsl:element name="skip:link">
						<xsl:attribute name="to">
							<xsl:value-of select="rml:else/*[1]/@id"/>
						</xsl:attribute>
						<xsl:attribute name="condition">otherwise</xsl:attribute>
					</xsl:element>
				</xsl:when>
				<xsl:otherwise>
					<!-- If there is no else, we just point to the next item -->
					<xsl:apply-templates select="." mode="makeLink"/>
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
		<xsl:apply-templates select="rml:then|rml:elseif|rml:else" mode="toSequenceGuides"/>
	</xsl:template>
	<xsl:template match="rml:response" mode="toSequenceGuides">
		<xsl:apply-templates select="." mode="makeLink"/>
	</xsl:template>
	<xsl:template match="rml:condition" mode="toSequenceGuides">
		<skip:condition question="{@question}">
			<xsl:value-of select="."/>
		</skip:condition>
	</xsl:template>
	<xsl:template match="*" mode="makeLink">
		<xsl:element name="skip:link">
			<xsl:attribute name="from">
				<xsl:value-of select="@id"/>
			</xsl:attribute>
			<xsl:attribute name="to">
				<xsl:choose>
					<xsl:when test="count(following-sibling::*) > 0">
						<xsl:value-of select="following-sibling::*[1]/@id"/>
					</xsl:when>
					<xsl:otherwise>
						<!-- get the first next element -->
						<xsl:for-each select="ancestor-or-self::*[local-name() = 'loop' or count(following-sibling::*)>0 and attribute::id][1]">
							<xsl:choose>
								<xsl:when test="local-name(.) = 'loop'">
									<!-- this is how we catch paths that might jump out of loops, and later we force them to a 'dummy' path -->
									<xsl:value-of select="./@id"/><xsl:text>_end</xsl:text>
								</xsl:when>
								<xsl:otherwise>
									<xsl:value-of select="following-sibling::*[1]/@id"/>
								</xsl:otherwise>
							</xsl:choose>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
