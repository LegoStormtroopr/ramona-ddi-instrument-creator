<?xml version="1.0" encoding="UTF-8"?>
<!-- edited with XMLSpy v2011 rel. 3 (http://www.altova.com) by .PCSoft (Australian Bureau of Statistics) -->
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:rml="http://legostormtoopr/response" xmlns:skip="http://legostormtoopr/skips" xmlns:exslt="http://exslt.org/common">
	<xsl:output method="xml" version="1.0" encoding="UTF-8" indent="yes"/>
	<!-- The main template of this file is this section which begins the transformation of the hierarchical ResponseML into a skip based graph.
		 This graph then assists with the creation of the 'Go To' isntructions seen on web and paper forms.
	-->
	<xsl:template name="makeSkips">
		<xsl:param name="doc"/>
		<xsl:variable name="first">
			<xsl:apply-templates select="exslt:node-set($doc)//rml:instrument/*"/>
		</xsl:variable>
		<xsl:variable name="second">
			<xsl:apply-templates select="exslt:node-set($first)//*" mode="second"/>
		</xsl:variable>
		<xsl:copy-of select="$second"/>
	</xsl:template>
	<!-- Under normal circumstances, this file will be imported and the "makeSkips" template called to create a skips pattern XML fragemnt.
		However, when an XSL transform is called on another XML file, it will attempt to process a root level match.
		This match does that, and outputs both the first and seconds steps of the transform, for debug purposes only.
	 -->
	<!--xsl:template match="/">
		<skips>
			<Two>
				<xsl:copy-of select="$second"/>
			</Two>
			<One>
				<xsl:copy-of select="$first"/>
			</One>
		</skips>
	</xsl:template -->
	<xsl:template match="rml:sequence">
		<!--
			Sequences can be compressed out and the elements with a sequence B contained within sequence A can all be considered within sequence A.
			For example:
				Sequence A
					Question 1
					Sequence B
						Question 2
			Can be rewritten as:
				Sequence A'
					Question 1
					Question 2
			With the ordering being preserved.
			We do this, as when graphing as a directed graph, we only care about the paths between questions and their possible branches and loops.
		-->
		<xsl:apply-templates select="*"/>
	</xsl:template>
	<xsl:template match="rml:response">
		<!--
			Here we create a link from the previous response element id to the current response id. This helps us build the default state that all questions are linked to their previous question.
			Superfluous links, when branching means a question doesn't link to its previous question, such as when branching, are removed in the second stage.
			In ResponseML a response is an XML element for data storage, that is contained within sequences, loops or conditional if blocks
				- they have a one-to-one relationship with questions in DDI, and in this document questions and responses are equivalent.
		-->
		<xsl:variable name="id" select="@id"/>
		<xsl:element name="skip:link">
			<xsl:attribute name="from">
				<xsl:value-of select="preceding::rml:response[position()=1]/@id"/>
			</xsl:attribute>
			<xsl:attribute name="to">
				<xsl:value-of select="@id"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<xsl:template match="rml:if">
		<!-- To process an if block, we just process the then and else blocks it contains -->
		<xsl:apply-templates select="rml:then | rml:else"/>
	</xsl:template>
	<xsl:template match="rml:then">
		<!--
			In preparation for deleting and moving links in the second stage we insert dummy objects that contains
			the number of responses/questions in the then block, and the condition that is needed to process this then block.
			These go before and after all contained objects, to make finding where to jump to easier.
		-->
		<xsl:element name="thenStart">
			<xsl:attribute name="count">
				<xsl:value-of select="count(.//rml:response)"/>
			</xsl:attribute>
			<xsl:attribute name="ifID">
				<xsl:value-of select="../@id"/>
			</xsl:attribute>
			<xsl:copy-of select="../rml:osc"/>
		</xsl:element>
		<xsl:apply-templates select="*"/>
		<thenEnd/>
	</xsl:template>
	<xsl:template match="rml:else">
		<!--
			In preparation for deleting and moving links in the second stage we insert a dummy object that contains the number of responses/questions in the else block.
			We only add an else iff there it contains any questions, otherwise we ignore it.
			These go before and after all contained objects, to make finding where to jump to easier.
		-->
		<xsl:if test="count(.//rml:response) > 0">
			<xsl:element name="elseStart">
				<xsl:attribute name="count">
					<xsl:value-of select="count(.//rml:response)"/>
				</xsl:attribute>
				<xsl:attribute name="ifID">
					<xsl:value-of select="../@id"/>
				</xsl:attribute>
			</xsl:element>
			<xsl:apply-templates select="*"/>
			<elseEnd/>
		</xsl:if>
	</xsl:template>
	<!-- On the second pass through, if this is the first response inside a then or else block we delete it as the link is invalid and will be recreated correctly later. -->
	<xsl:template match="skip:link" mode="second">
		<xsl:if test="local-name(preceding::*[position()=1]) != 'elseStart' and local-name(preceding::*[position()=1]) != 'thenStart'">
			<xsl:copy-of select="."/>
		</xsl:if>
	</xsl:template>
	<!-- This template cleans up the "thenStart" placeholders from the first step, and replaces them with the appropriate skips -->
	<xsl:template match="thenStart" mode="second">
		<xsl:variable name="count">
			<xsl:value-of select="@count"/>
		</xsl:variable>
		<!-- remake the sequential/conditional skip that was deleted -->
		<xsl:element name="skip:link">
			<!-- The From ID is needed when making some conditionals below. So we capture it as a variable - not cause its quicker, but cause I'm still having issues with boolean conditionals in XPath and this is easier-->
			<xsl:variable name="from">
				<xsl:value-of select="preceding::skip:link[position()=1]/@to"/>
			</xsl:variable>
			<xsl:attribute name="from">
				<xsl:value-of select="$from"/>
			</xsl:attribute>
			<xsl:attribute name="to">
				<xsl:value-of select="following::skip:link[position()=1]/@to"/>
			</xsl:attribute>
			<xsl:choose>
				<!-- Here we populate the conditions this link is based on -->
				<xsl:when test="count(rml:osc/rml:condition)=0"/>
				<xsl:when test="count(rml:osc/rml:condition)=1 and rml:osc/rml:condition[@question = $from]">
					<!--
						If there is a single condition and it is based on the immediately preceeding question, we can do some funky stuff to help automate the skip links.
					-->
					<xsl:attribute name="condition">
						<xsl:value-of select="rml:osc/rml:condition"/>
					</xsl:attribute>
					<xsl:attribute name="ifID">
						<xsl:value-of select="@ifID"/>
					</xsl:attribute>
				</xsl:when>
				<xsl:otherwise>
					<!--
						When there are more than one conditional question OR the condition is not based on the immediately preceeding question.
						These should be rare.
					-->
				</xsl:otherwise>
			</xsl:choose>
		</xsl:element>
		<xsl:element name="skip:link">
			<xsl:attribute name="from">
				<xsl:value-of select="preceding::skip:link[position()=1]/@to"/>
			</xsl:attribute>
			<xsl:attribute name="to">
				<xsl:value-of select="following::skip:link[position()=($count + 1)]/@to"/>
			</xsl:attribute>
			<xsl:attribute name="condition">otherwise</xsl:attribute>
			<xsl:attribute name="ifID">
				<xsl:value-of select="@ifID"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- This template cleans up the "elseStart" placeholders from the first step, and replaces them with the appropriate skips -->
	<xsl:template match="elseStart" mode="second">
		<xsl:variable name="count">
			<xsl:value-of select="@count"/>
		</xsl:variable>
		<xsl:element name="skip:link">
			<xsl:attribute name="from">
				<xsl:value-of select="preceding::skip:link[position()=1]/@to"/>
			</xsl:attribute>
			<xsl:attribute name="to">
				<xsl:value-of select="following::skip:link[position()=($count + 1)]/@to"/>
			</xsl:attribute>
			<xsl:attribute name="default">
				<xsl:value-of select="true()"/>
			</xsl:attribute>
			<xsl:attribute name="ifID">
				<xsl:value-of select="@ifID"/>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- As a base case, when matching anything not explicitly contained above - output nothing. -->
	<xsl:template match="*" mode="second"/>
	<xsl:template name="makeSkips2">
		<xsl:param name="doc"/>
		<xsl:variable name="cleand">
			<!-- Firstly we clean up the rml:instrument, leaving only ifs,loops,responses and conditions - everything else isn't needed for computing the skips -->
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
			<!--
				Now we try to remove sequence guides, if possible.
				At present this is met by the condition - IF a link X is immediately followed by a sequenceGuide Y, AND X is a path to Y, AND X is the only path to the sequence guide AND all of Ys conditions only depend on X, then replace Y with the required number of links, otherwise keep X and Y as they are.
				We do this recursively, because we may have to jump things.
			-->
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
	<xsl:template match="skip:sequenceGuide" mode="removeSequenceGuides">
		<xsl:copy-of select="."/>
		<xsl:apply-templates select="following-sibling::*[1]" mode="removeSequenceGuides"/>
	</xsl:template>
	<!--	Remove everything that isn't an if,loop or question/response -->
	<xsl:template match="@*|node()" mode="cleanr">
		<xsl:copy>
			<xsl:apply-templates select="@*|node()" mode="cleanr"/>
		</xsl:copy>
	</xsl:template>
	<xsl:template match="rml:sequence" mode="cleanr">
		<xsl:apply-templates select="node()" mode="cleanr"/>
	</xsl:template>
	<xsl:template match="rml:multipart" mode="cleanr"/>
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
						<xsl:for-each select="ancestor-or-self::*[count(following-sibling::*)>0 and attribute::id][1]">
							<xsl:value-of select="following-sibling::*[1]/@id"/>
						</xsl:for-each>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:attribute>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
