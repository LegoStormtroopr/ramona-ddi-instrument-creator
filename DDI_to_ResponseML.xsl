<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="1.0" xmlns:exslt="http://exslt.org/common" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ns1="ddi:instance:3_1" xmlns:a="ddi:archive:3_1" xmlns:r="ddi:reusable:3_1" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:dc="ddi:dcelements:3_1" xmlns:ns7="http://purl.org/dc/elements/1.1/" xmlns:cm="ddi:comparative:3_1" xmlns:d="ddi:datacollection:3_1" xmlns:l="ddi:logicalproduct:3_1" xmlns:c="ddi:conceptualcomponent:3_1" xmlns:ds="ddi:dataset:3_1" xmlns:p="ddi:physicaldataproduct:3_1" xmlns:pr="ddi:ddiprofile:3_1" xmlns:s="ddi:studyunit:3_1" xmlns:g="ddi:group:3_1" xmlns:pi="ddi:physicalinstance:3_1" xmlns:m3="ddi:physicaldataproduct_ncube_inline:3_1" xmlns:m1="ddi:physicaldataproduct_ncube_normal:3_1" xmlns:m2="ddi:physicaldataproduct_ncube_tabular:3_1" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:rml="http://legostormtoopr/response" xmlns:skip="http://legostormtoopr/skips" exclude-result-prefixes="ns1 a r dc ns7 cm d l c ds p pr s g pi m3 m1 m2 exslt skip">
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
		<xsl:import href="./stringFunctions.xsl"/>
	<!--
		The default transform for this style sheet will find all DDI Instruments and create the appropriate ResponseML data model from them.
	-->
	<xsl:template match="/">
		<xsl:apply-templates select="//d:Instrument" mode="dataBuilder"/>
	</xsl:template>
	<xsl:template name="dataModelBuilder">
		<rml:respondent>
			<xsl:apply-templates select="//c:UniverseScheme" mode="dataBuilder"/>
			<xsl:apply-templates select="//d:Instrument" mode="dataBuilder"/>
			<xsl:call-template name="wordSubs"/>
		</rml:respondent>	
	</xsl:template>
	<xsl:template match="d:Instrument" mode="dataBuilder">
		<xsl:variable name="construct">
			<xsl:value-of select="d:ControlConstructReference/r:ID"/>
		</xsl:variable>
		<rml:instrument>
			<xsl:apply-templates select="//d:Sequence[@id=$construct]" mode="dataBuilder"/>
		</rml:instrument>
	</xsl:template>
	<xsl:template match="d:Sequence" mode="dataBuilder">
		<xsl:element name="rml:sequence">
			<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
			<xsl:for-each select="d:ControlConstructReference">
				<xsl:variable name="id">
					<xsl:value-of select="r:ID"/>
				</xsl:variable>
				<xsl:apply-templates select="//*[@id=$id]" mode="dataBuilder"/>
			</xsl:for-each>
		</xsl:element>
	</xsl:template>
	<xsl:template match="d:IfThenElse" mode="dataBuilder">
		<xsl:element name="rml:if">
			<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
			<xsl:apply-templates select="d:IfCondition"/>
			<rml:then>
				<xsl:apply-templates select="./d:ThenConstructReference" mode="dataBuilder"/>
			</rml:then>
			<rml:else>
				<xsl:apply-templates select="./d:ElseConstructReference" mode="dataBuilder"/>
			</rml:else>
		</xsl:element>
	</xsl:template>
	<xsl:template match="d:IfCondition">
		<xsl:choose>
			<!-- If we can use an orderedSQRConditional we will, as this allows for more automatic processing and skips in questions -->
			<xsl:when test="./r:Code[@programmingLanguage='orderedSQRConditionaldfjlkgjlkjlkjlkg']">
				<rml:osc>
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
							</xsl:variable>//rml:response[@id='<xsl:value-of select="r:ID"/>'] = <xsl:value-of select="exslt:node-set($SQRvalues)[position() = $pos]"/>
						</xsl:for-each>
					</xsl:variable>
					<xsl:for-each select="r:SourceQuestionReference">
						<xsl:variable name="pos">
							<xsl:value-of select="position()"/>
						</xsl:variable>
						<xsl:element name="rml:condition">
							<!--
									/!\ WARNING WARNING WARNING /!\
									===============================
									This is a horrible hack based on a very flimsy assumption!!!!!!
									The IfCondition has a reference to the QUESTIONITEM not the QUESTIONCONSTRUCT.
									However, all of the logic (in Ramona) is based on QuestionConstructs.
									Thus we need to convert this question reference to get the QuestionConstruct that also references it.
									THIS WILL FALL DOWN IF A QUESTION IS REFERENCED BY TWO DIFFERENT QUESTIONCONSTRUCTS - which is legal, but presumably rare, in DDI.
									
									To resolve this issue, if there is more than one QuestionConstruct no condition value is output to prevent any further logic from being created.
								-->
							<xsl:variable name="QID">
								<xsl:value-of select="r:ID"/>
							</xsl:variable>
							<xsl:if test="count(//d:QuestionConstruct[d:QuestionReference/r:ID/text() = $QID]) = 1">
								<xsl:attribute name="question"><xsl:value-of select="//d:QuestionConstruct[d:QuestionReference/r:ID/text() = $QID]/@id"/></xsl:attribute>
							</xsl:if>
							<xsl:value-of select="exslt:node-set($SQRvalues)[position() = $pos]"/>
						</xsl:element>
					</xsl:for-each>
					<xsl:call-template name="string-join">
						<xsl:with-param name="node-set">
							<xsl:copy-of select="$vals"/>
						</xsl:with-param>
						<xsl:with-param name="token"> and </xsl:with-param>
					</xsl:call-template>
				</rml:osc>
			</xsl:when>
			<!-- If there is no orderedSQRConditional we use the Xpath/RML syntax, so we can have some automatic enabling/disabling of questions... BUT WITHOUT SKIPS -->
			<xsl:when test="r:Code[@programmingLanguage='responseML_xpath1.0']">
				<xsl:value-of select="d:IfCondition/r:Code[@programmingLanguage='responseML_xpath1.0']/text()"/>
			</xsl:when>
			<xsl:otherwise>
				<!-- No automated conditional available, don't spit out code. -->
			</xsl:otherwise>
		</xsl:choose>
	</xsl:template>
	<xsl:template match="d:ThenConstructReference" mode="dataBuilder">
		<xsl:variable name="id">
			<xsl:value-of select="r:ID"/>
		</xsl:variable>
		<xsl:apply-templates select="//*[@id=$id]" mode="dataBuilder"/>
	</xsl:template>
	<xsl:template match="d:ElseConstructReference" mode="dataBuilder">
		<xsl:variable name="id">
			<xsl:value-of select="r:ID"/>
		</xsl:variable>
		<xsl:apply-templates select="//*[@id=$id]" mode="dataBuilder"/>
	</xsl:template>
	<!--
		Processing the QuestionItem is not needed for creating the ResponseML construct as the QuestionConstruct can be treated as a proxy for the question when dealing with the structure.
		Iff QuestionConstruct refers to a MultipleQuestionItem, then we will resolve the reference and created subresponses.
	-->
	<xsl:template match="d:QuestionConstruct" mode="dataBuilder">
		<xsl:variable name="question">
			<xsl:value-of select="d:QuestionReference/r:ID"/>
		</xsl:variable>
		<xsl:element name="rml:response">
			<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
			<xsl:attribute name="questionItemID"><xsl:value-of select="$question"/></xsl:attribute>
			<xsl:apply-templates select="//d:MultipleQuestionItem[@id=$question]" mode="dataBuilder"/>
		</xsl:element>
	</xsl:template>
	<!--
		We need to examine the MultipleQuestionItems to get all sub questions so they each have their own data node in the model.
	-->
	<xsl:template match="d:MultipleQuestionItem" mode="dataBuilder">
		<xsl:element name="rml:multipart">
			<xsl:apply-templates select="d:SubQuestions/*" mode="dataBuilder"/>
		</xsl:element>
	</xsl:template>
	<!-- QuestionItem are only processed in this code only as children of MultiQuestionItems, so we can reliably output them as subresponses.
		 If the QuestionConstruct code is changed to also process the referenced QuestionItems, then this will have to change. -->
	<xsl:template match="d:QuestionItem" mode="dataBuilder">
		<xsl:element name="rml:subresponse">
			<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
		</xsl:element>
	</xsl:template>
	<xsl:template match="c:UniverseScheme" mode="dataBuilder">
		<rml:populations>
			<xsl:apply-templates select="c:Universe" mode="dataBuilder"/>
		</rml:populations>
	</xsl:template>
	<xsl:template match="c:Universe" mode="dataBuilder">
		<xsl:element name="rml:population">
			<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
			<xsl:apply-templates select="c:SubUniverse" mode="dataBuilder"/>
		</xsl:element>
	</xsl:template>
	<xsl:template match="c:SubUniverse" mode="dataBuilder">
		<xsl:element name="rml:subpopulation">
			<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
			<xsl:apply-templates select="c:SubUniverse"/>
			<!-- xsl:attribute name="membership"><xsl:value-of select="$config/defaultMembership"/></xsl:attribute -->
		</xsl:element>
	</xsl:template>
	<xsl:template match="d:ComputationItem" mode="dataBuilder">
		<xsl:element name="rml:computation">
			<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- As a base case, when matching anything not explicitly contained above - output nothing. -->
	<xsl:template match="*" mode="dataBuilder"/>

	<!-- 
		
		========================
		WORDSUBS BUILDING MODES
		========================
		
		This section creates the data structures that makes the word substitutions possible.
		
	 -->
	<xsl:template name="wordSubs">
		<xsl:apply-templates select="//l:CodeScheme" mode="wordSub"/>
	</xsl:template>
	<!--	Iff a QuestionItem exists that uses this CodeScheme, we will create a wordsub element for Ramona
			This could be a little more conservative and creation one IFF the codescheme is used in the current instrument, but we can fix that later.
	-->
	<xsl:template match="l:CodeScheme" mode="wordSub">
		<xsl:if test="//d:QuestionItem/d:CodeDomain/r:CodeSchemeReference/r:ID = ./@id">
			<xsl:element name="rml:wordsubs">
				<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
				<xsl:apply-templates select="l:Code" mode="wordSub"/>
			</xsl:element>
		</xsl:if>
	</xsl:template>
	<xsl:template match="l:Code" mode="wordSub">
		<xsl:variable name="categoryID">
			<xsl:value-of select="l:CategoryReference/r:ID"/>
		</xsl:variable>
		<xsl:element name="rml:wordsub">
			<xsl:attribute name="value"><xsl:value-of select="./l:Value"/></xsl:attribute>
			<xsl:attribute name="subtext"><xsl:apply-templates select="//l:Category[@id=$categoryID]/r:Label[@type = 'Ramona-Wordsub']"/></xsl:attribute>
			<xsl:apply-templates select="l:Code" mode="wordSub"/>
		</xsl:element>
	</xsl:template>
</xsl:stylesheet>
