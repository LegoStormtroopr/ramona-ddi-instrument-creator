<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0"
	xmlns:exslt="http://exslt.org/common"
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:ev="http://www.w3.org/2001/xml-events"
	xmlns:ddi="ddi:instance:3_1" xmlns:a="ddi:archive:3_1" xmlns:r="ddi:reusable:3_1" xmlns:dc="ddi:dcelements:3_1" xmlns:ns7="http://purl.org/dc/elements/1.1/" xmlns:cm="ddi:comparative:3_1" xmlns:d="ddi:datacollection:3_1" xmlns:l="ddi:logicalproduct:3_1" xmlns:c="ddi:conceptualcomponent:3_1" xmlns:ds="ddi:dataset:3_1" xmlns:p="ddi:physicaldataproduct:3_1" xmlns:pr="ddi:ddiprofile:3_1" xmlns:s="ddi:studyunit:3_1" xmlns:g="ddi:group:3_1" xmlns:pi="ddi:physicalinstance:3_1" xmlns:m3="ddi:physicaldataproduct_ncube_inline:3_1" xmlns:m1="ddi:physicaldataproduct_ncube_normal:3_1" xmlns:m2="ddi:physicaldataproduct_ncube_tabular:3_1"
	xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema"
	xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:xf="http://www.w3.org/2002/xforms"
	xmlns="http://www.w3.org/1999/xhtml" xmlns:xhtml="http://www.w3.org/1999/xhtml"
	xmlns:rml="http://legostormtoopr/response" xmlns:skip="http://legostormtoopr/skips"
	exclude-result-prefixes="ddi a r dc ns7 cm d l c ds p pr s g pi m3 m1 m2 exslt skip fo xs">
	<!--
		
		=========================
		DATA MODEL BUILDING MODES 
		=========================
		
		This section helps construct the ResponseML data model used to capture responses.
		
		Starting from the instrument dataBuilder template, which works on a DDI instrument, it iteratively builds a explict tree based on the implicit DDI hierarchy for a questionnaire.
		For more information on the ResponseML format view the doccumentation for ResponseML.
		
		The algorithm for this transform works as so:
		1. Find a DDI instrument
			a. From the instrument get the reference to the ControlConstruct (Sequence, IfThenElse, Loop, QuestionConstruct)
		2. Find the reference ControlConstruct
		3. For the given ControlConstruct in step 2, and if it is a...
			a. QuestionConstruct, output a <rml:response> element.
			b. Sequence, output a <rml:sequence>, then get all references to child ControlConstructs and process them, preserving document order, from step 2 as children of the new element.
			c. IfThenElse, get the Then and option Else references, and create a <rml:then> or <rml:else> element, process them, preserving document order, from step 2 as children of the appropriate then or else element.

	-->
	<xsl:import href="./DDI_to_Graphviz.xsl"/>
	<xsl:output method="xml" indent="yes" 
		doctype-system="http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd"
		doctype-public="-//W3C//DTD XHTML 1.0 Transitional//EN" />
	<!--
		The default transform for this style sheet will find all DDI Instruments and create the appropriate ResponseML data model from them.
	-->

	<xsl:template match="/">
		<html>
			<head>
				<title>Flow Diagram of '<xsl:value-of select="//d:Instrument/d:InstrumentName"/>'</title>
				<script type="text/javascript" src="http://ajax.googleapis.com/ajax/libs/jquery/1.4.2/jquery.min.js">var x;</script>
				<script type="text/javascript">
					$(document).ready(function(){
						$("a.showDetail").text("[-]");
						$("a.HBD").text("[+]");
						$("a.showDetail").click(function(event){
						    $(this).next(".detail").slideToggle()
						}).toggle( function() {
								$(this).text("[+]");
							}, function() {
						    	$(this).text("[-]");
						});
						$("a.HBD").toggle( function() {
						$(this).text("[-]");
						}, function() {
						$(this).text("[+]");
						});
						
					});
				</script>
				<link rel="stylesheet" type="text/css" href="flowdiagram.css" />
			</head>
			<body>
					<xsl:apply-templates select="//d:Instrument" />
			</body>
		</html>
	</xsl:template>
	<xsl:template match="d:Instrument" >
		<h2><xsl:value-of select="d:InstrumentName"/></h2>
		<div id="instrumentInfo" >
			Description: <a href="#" class="showDetail HBD">Toggle Detail</a>
			<div class="detail boxed">
				<xsl:copy-of select="r:Description/*"/>
			</div>
		</div>
		<xsl:variable name="construct">
			<xsl:value-of select="d:ControlConstructReference/r:ID"/>
		</xsl:variable>
		<div id="flowchart">
			<xsl:element name="img">
				<xsl:attribute name="src">https://chart.googleapis.com/chart?chl=<xsl:apply-templates select="//d:Instrument" mode="graphBuilder"/>&amp;cht=gv</xsl:attribute>
			</xsl:element>
		</div>
		<div id="mainWindow">
			<xsl:apply-templates select="//d:Sequence[@id=$construct]" />
		</div>
	</xsl:template>
	<xsl:template match="d:Loop" >
		<span title="{@id}"><span class="loopBox">L</span> <xsl:value-of select="d:LoopWhile/r:Description"/> <small> (Loop)</small></span>
		<a href="#" class="showDetail">+/-</a>
		<div class="detail">
			<ul class="loop">
			<xsl:for-each select="d:ControlConstructReference">
				<li>
					<xsl:variable name="id">
						<xsl:value-of select="r:ID"/>
					</xsl:variable>
					<xsl:apply-templates select="//*[@id=$id]" />
				</li>
			</xsl:for-each>
			</ul>
		</div>
	</xsl:template>
	<xsl:template match="d:Sequence" >
		<span title="{@id}"><span class="sequenceBox">S</span> <xsl:value-of select="r:Label"/> <small> (Sequence)</small></span>
		<a href="#" class="showDetail">+/-</a>
		<div class="detail">
			<ul class="sequence">
			<xsl:for-each select="d:ControlConstructReference">
				<li>
					<xsl:variable name="id">
						<xsl:value-of select="r:ID"/>
					</xsl:variable>
					<xsl:apply-templates select="//*[@id=$id]" />
				</li>
			</xsl:for-each>
			</ul>
		</div>
	</xsl:template>
	<xsl:template match="d:IfThenElse" >
		
			<span title="{@id}"><span class="ifbox">If</span><xsl:value-of select="d:IfCondition/r:Description"/></span>
			<a href="#" class="showDetail HBD">+/-</a>
			<div class="condition detail "><small>(<xsl:value-of select="@id"/>)</small>:
			<xsl:apply-templates select="d:IfCondition/r:SourceQuestionReference"/>
				Condition: <xsl:apply-templates select="d:IfCondition"/></div>
			<ul class="if">
				<xsl:apply-templates select="./d:ThenConstructReference" />
				<xsl:apply-templates select="./d:ElseConstructReference" />
			</ul>
		
	</xsl:template>
	<xsl:template match="r:SourceQuestionReference">
		<xsl:variable name="id"><xsl:value-of select="r:ID"/></xsl:variable>
		Based on Question <strong><a href="#{$id}"><xsl:value-of select="$id"/></a></strong><br/>
	</xsl:template>
	<xsl:template match="d:IfCondition">
		<span style="font-family:monospace;font-size:90%">
		<xsl:choose>
			<!-- If we can use an orderedSQRConditional we will, as this allows for more automatic processing and skips in questions -->
			<xsl:when test="./r:Code[@programmingLanguage='orderedSQRConditional']">	
					<xsl:variable name="SQRvalues">
						<xsl:call-template name="tokenize">
							<xsl:with-param name="string">
								<xsl:value-of select="./r:Code[@programmingLanguage='orderedSQRConditional']/text()"/>
							</xsl:with-param>
							<xsl:with-param name="token">,</xsl:with-param>
						</xsl:call-template>
					</xsl:variable>
					<xsl:variable name="vals">
						<xsl:for-each select="r:SourceQuestionReference">
							<xsl:variable name="pos">
								<xsl:value-of select="position()"/>
							</xsl:variable>Question <xsl:value-of select="r:ID"/>= <xsl:value-of select="exslt:node-set($SQRvalues)[position() = $pos]"/>
						</xsl:for-each>
					</xsl:variable>
					<xsl:for-each select="r:SourceQuestionReference">
						<xsl:variable name="pos">
							<xsl:value-of select="position()"/>
						</xsl:variable>
						<xsl:variable name="QID">
							<xsl:value-of select="r:ID"/>
						</xsl:variable>
						<xsl:if test="count(//d:QuestionConstruct[d:QuestionReference/r:ID/text() = $QID]) = 1">
							<xsl:value-of select="//d:QuestionConstruct[d:QuestionReference/r:ID/text() = $QID]/@id"/>
						</xsl:if>
						<xsl:value-of select="$SQRvalues[position() = $pos]"/>
					</xsl:for-each>
					<xsl:call-template name="string-join">
						<xsl:with-param name="node-set">
							<xsl:copy-of select="$vals"/>
						</xsl:with-param>
						<xsl:with-param name="token"> and </xsl:with-param>
					</xsl:call-template>
			</xsl:when>
			<!-- If there is no orderedSQRConditional we use the Xpath/RML syntax, so we can have some automatic enabling/disabling of questions... BUT WITHOUT SKIPS -->
			<xsl:when test="r:Code[@programmingLanguage='responseML_xpath1.0']">
				<xsl:value-of select="r:Code[@programmingLanguage='responseML_xpath1.0']/text()"/>
			</xsl:when>
			<xsl:otherwise><span style="color:red">No Condition detected</span>
				<!-- No automated conditional available, don't spit out code. -->
			</xsl:otherwise>
		</xsl:choose>
		</span>
	</xsl:template>
	<xsl:template match="d:ThenConstructReference" >
		<xsl:variable name="id">
			<xsl:value-of select="r:ID"/>
		</xsl:variable>
		<li><strong>Then:</strong>
			<a href="#" class="showDetail">+/-</a>
			<div class="detail">
				<xsl:apply-templates select="//*[@id=$id]" />
			</div>
		</li>
	</xsl:template>
	<xsl:template match="d:ElseConstructReference" >
		<xsl:variable name="id">
			<xsl:value-of select="r:ID"/>
		</xsl:variable>
		<li><strong>Else:</strong>
			<a href="#" class="showDetail">+/-</a>
			<div class="detail">
				<xsl:apply-templates select="//*[@id=$id]" />
			</div>
		</li>
	</xsl:template>
	<!--
		Processing the QuestionItem is not needed for creating the ResponseML construct as the QuestionConstruct can be treated as a proxy for the question when dealing with the structure.
		Iff QuestionConstruct refers to a MultipleQuestionItem, then we will resolve the reference and created subresponses.
	-->
	<xsl:template match="d:QuestionConstruct" >
		
		<xsl:variable name="question">
			<xsl:value-of select="d:QuestionReference/r:ID"/>
		</xsl:variable>
		<span>
			<span class="questionNumber" title="{$question}"><xsl:value-of select="exslt:node-set($numbers)/question[@id=$question]"/></span>
			<span class="questionDetails">
				<xsl:apply-templates select="//d:MultipleQuestionItem[@id=$question] | //d:QuestionItem[@id=$question]">
					<xsl:with-param name="qcID">
						<xsl:value-of select="@id"/>
					</xsl:with-param>
				</xsl:apply-templates>
			</span>
		</span>
	</xsl:template>
	<!--
		We need to examine the MultipleQuestionItems to get all sub questions so they each have their own data node in the model.
	-->
	<xsl:template match="d:MultipleQuestionItem" >
		<xsl:apply-templates select="d:QuestionText"/>
		<ul>
		<xsl:for-each select="d:SubQuestions/*">
			<li>
			<xsl:apply-templates select="." />
			</li>
		</xsl:for-each>
		</ul>
	</xsl:template>
	<!-- QuestionItem are only processed in this code only as children of MultiQuestionItems, so we can reliably output them as subresponses.
		 If the QuestionConstruct code is changed to also process the referenced QuestionItems, then this will have to change. -->
	<xsl:template match="d:QuestionItem" >
		<xsl:apply-templates select="d:QuestionText"/>
	</xsl:template>
	<xsl:template match="d:StatementItem">
		<div>
		<em>Statement: </em><xsl:value-of select="substring(d:DisplayText,1,100)"/>...
		</div>
	</xsl:template>
	<xsl:template match="d:QuestionText">
		<xsl:apply-templates select="*"/>
	</xsl:template>
	<xsl:template match="d:LiteralText">
		<xsl:copy-of select="*"/>
	</xsl:template>
	<xsl:template match="d:ConditionalText">
		<xsl:variable name="description"><xsl:value-of select="r:Description"/></xsl:variable>
		<span style="font-family:monospace;font-size:80%"> wordsub <a href="#" title="{$description}" class="showDetail HBD">+/-</a>
			<div class="detail boxed">
				<xsl:apply-templates select="d:Expression"/>
			</div></span>
	</xsl:template>
	<!-- As a base case, when matching anything not explicitly contained above - output nothing. -->
</xsl:stylesheet>
