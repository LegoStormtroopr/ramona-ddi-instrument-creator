<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet version="2.0" xmlns:exslt="http://exslt.org/common" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:fo="http://www.w3.org/1999/XSL/Format" xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:fn="http://www.w3.org/2005/xpath-functions" xmlns:ns1="ddi:instance:3_1" xmlns:a="ddi:archive:3_1" xmlns:r="ddi:reusable:3_1" xmlns:xhtml="http://www.w3.org/1999/xhtml" xmlns:dc="ddi:dcelements:3_1" xmlns:ns7="http://purl.org/dc/elements/1.1/" xmlns:cm="ddi:comparative:3_1" xmlns:d="ddi:datacollection:3_1" xmlns:l="ddi:logicalproduct:3_1" xmlns:c="ddi:conceptualcomponent:3_1" xmlns:ds="ddi:dataset:3_1" xmlns:p="ddi:physicaldataproduct:3_1" xmlns:pr="ddi:ddiprofile:3_1" xmlns:s="ddi:studyunit:3_1" xmlns:g="ddi:group:3_1" xmlns:pi="ddi:physicalinstance:3_1" xmlns:m3="ddi:physicaldataproduct_ncube_inline:3_1" xmlns:m1="ddi:physicaldataproduct_ncube_normal:3_1" xmlns:m2="ddi:physicaldataproduct_ncube_tabular:3_1" xmlns:xf="http://www.w3.org/2002/xforms" xmlns:ev="http://www.w3.org/2001/xml-events" xmlns:rml="http://legostormtoopr/response" xmlns:skip="http://legostormtoopr/skips" xmlns:cfg="rml:RamonaConfig_v1" xmlns:msxsl="urn:schemas-microsoft-com:xslt" exclude-result-prefixes="ns1 a r dc ns7 cm d l c ds p pr s g pi m3 m1 m2 exslt msxsl skip cfg" extension-element-prefixes="exslt">
	<!-- Import the XSLT for turning a responseML document into the skip patterns needed for conditional questions. -->
	<xsl:import href="./responseML_to_Skips.xsl"/>
	<xsl:import href="./DDI_to_ResponseML.xsl"/>
	<xsl:import href="./DDIReferenceResolver.xsl"/>
	<xsl:import href="./configTransformations.xsl"/>
	
	<!-- We are outputing XHTML so the output method will be XML, not HTML -->
	<xsl:output method="xml"/>

	<!-- Simulating EXSLT for XSLT2.0 -->
	<xsl:function name="exslt:node-set">
		<xsl:param name="rtf"/>
		<xsl:sequence select="$rtf"/>
	</xsl:function> 
	
	<!-- Simulating EXSLT node-set for the MS XML XSLT Engine -->
	<msxsl:script language="JScript" implements-prefix="exslt">
	 this['node-set'] =  function (x) {
	  return x;
	  }
	</msxsl:script>
	
	<!-- Read in the configuration file. This contains information about how the XForm is to be created and displayed. Including CSS file locations and language information. -->
	<xsl:variable name="config" select="document('./config.xml')/cfg:config"/>

	<!-- Based on the deployer Environment, determine the correct path to the theme specific configuration file --> 
	<xsl:variable name="theme_file">
		<xsl:choose>
			<!-- If we are deployed on an eXist-db install construct the correct path to the theme config --> 
			<xsl:when test="$config/cfg:environment = 'exist-db'">
				<xsl:copy-of select="concat('/Ramona/themes/',$config/cfg:themeName,'.xml')"/>
			</xsl:when>
			<!-- If we don't know the deployed environment assume the theme is in the default distribution directory --> 
			<xsl:otherwise>
				<xsl:copy-of select="concat('./themes/',$config/cfg:themeName,'/theme.xml')"/>
			</xsl:otherwise>
		</xsl:choose>
	</xsl:variable>
	<!-- The concat below is a work around to pull the correct theme file. If you just try and use this:
			<xsl:variable name="theme" select="document($theme_file)/theme"/>
			It will fail, for some as of yet undetermined reason.
	-->
	<xsl:variable name="theme" select="document(concat('',$theme_file,''))/cfg:theme"/>
	<!-- 
		Create the instrument for the XForms Model. This is represntation of the "true XML hierarchy" of the questionnaire (as opposed to the referential hiearchy of the DDI Document
		This is created as a global variable as it is needed in several different places for processing.
		The generated XML model of the questionnaire is needed for the data model of the final XForm, and exists as a ResponseML document.
	-->
	<xsl:variable name="instrumentModel">
		<xsl:apply-templates select="//d:Instrument" mode="dataBuilder"/>
	</xsl:variable>
	<!--
	This is used to convert numbers to letters for SubQuestions 
	Based on solution here: http://bytes.com/topic/net/answers/85730-xslt-converting-number-into-character
	-->
	<xsl:variable name="ascii">abcdefghijklmnopqrstuvwxyz</xsl:variable>
	<!-- Who needs more than 20 sub-sub-questions anyway? -->
	<xsl:variable name="roman">i ii iii iv v vi vii viii ix x xi xii xiii xiv xv xvi xvii xviii xix xx</xsl:variable>
	<!-- 
		This is the area where the question and section numbers are generated. This is generated from the document order of responses in the instrumentModel above.
	-->
	<xsl:variable name="numbers">
		<xsl:for-each select="exslt:node-set($instrumentModel)//rml:response">
			<xsl:element name="question">
				<xsl:attribute name="id"><xsl:value-of select="@questionItemID"/></xsl:attribute>
				<xsl:value-of select="position()"/>
			</xsl:element>
		</xsl:for-each>
		<xsl:for-each select="exslt:node-set($instrumentModel)/rml:sequence/*">
			<xsl:element name="section">
				<xsl:attribute name="id"><xsl:value-of select="@id"/></xsl:attribute>
				<xsl:value-of select="position()"/>
			</xsl:element>
		</xsl:for-each>
	</xsl:variable>
	<!-- 
		This is the area where the question and section numbers are generated. This is generated from the document order of responses in the instrumentModel above.
		This code is contained within the ResponseML_to_skips.xsl file.
	-->
	<xsl:variable name="skips">
		<xsl:call-template name="makeSkips">
			<xsl:with-param name="doc">
				<xsl:copy-of select="$instrumentModel"/>
			</xsl:with-param>
		</xsl:call-template>
	</xsl:variable>
	<!-- 
		==============================
		MAIN ENTRY POINT FOR TRANSFORM
		==============================
		
		This matches on the root element of the DDI Document so everything is done once. At present it searches for the instrument with a software tag of "XForms-Ramona"
		In future, this may search for ALL instruments and create one XForms for each instrument or alternatively, accept a list of instrument ids in config.xml and only process those.
	-->

	<xsl:template match="/">
		<xsl:processing-instruction name="xml-stylesheet">href="<xsl:if test="$config/cfg:xsltformsLocation/@relative=true()">
				<xsl:value-of select="$config/cfg:rootURN"/>
			</xsl:if>
			<xsl:value-of select="$config/cfg:xsltformsLocation"/>" type="text/xsl"</xsl:processing-instruction>
		<xsl:processing-instruction name="xsltforms-options">debug="no"</xsl:processing-instruction>
		<xsl:apply-templates select="//d:Instrument"/>
	</xsl:template>
	<!-- 
		This template matches for instruments and creates the boiler plate for the final XHTML+XForms Document.
		It creates sections to hold a side menu linking within the page to all the major sections (div.majorsections), and main section for the survey itself (div.survey)
		There is the assumption that whatever calls this process will construct a DDI document with only one instrument.
		This assumption is based on the fact that only one survey instrument would be displayed to a respondent at a time.
		Prints the instrument name and description, and processes the single, valid ControlConstruct contained within the DDI Instrument.
	-->
	<xsl:template match="d:Instrument">
		<html xmlns="http://www.w3.org/1999/xhtml"  xmlns:xhtml="http://www.w3.org/1999/xhtml">
			<head>
				<title>
					<xsl:apply-templates select="d:InstrumentName"/>
				</title>
				<!-- Link to the CSS for rendering the form -->
				<xsl:apply-templates select="$theme/cfg:styles/*"/>
				<!-- Xforms Data model and bindings, including the ResponseML data instance. -->
				<xf:model>
					<xf:instance>
						<xsl:call-template name="dataModelBuilder"/>						
					</xf:instance>
					<xsl:call-template name="makeBindings"/>
					<xf:submission id="saveLocally" method="put" action="file://C:/temp/saved_survey.xml"/>
					<xf:submission id="saveRemotely" method="post" action="{$config/cfg:serverSubmitURI}"/>
				</xf:model>
			</head>
			<body>
				<div id="majorsections">
					<xsl:apply-templates select="$theme/cfg:logo"/>
					<h2>Major Sections</h2>
					<ol>
						<xsl:for-each select="//d:Sequence">
							<xsl:if test="./r:Label">
								<li>
									<xsl:element name="a">
										<xsl:attribute name="href">#<xsl:value-of select="@id"/></xsl:attribute>
										<xsl:apply-templates select="./r:Label" mode="sidebar"/>
									</xsl:element>
								</li>
							</xsl:if>
						</xsl:for-each>
					</ol>
				</div>
				<div id="survey">
					<xsl:variable name="construct">
						<xsl:value-of select="d:ControlConstructReference/r:ID"/>
					</xsl:variable>
					<h1>
						<xsl:apply-templates select="d:InstrumentName"/>
					</h1>
					<div class="instrumentDescription">
						<xsl:apply-templates select="r:Description"/>
					</div>
					<xsl:apply-templates select="//d:Sequence[@id=$construct]" mode="master"/>
					<xf:submit submission="saveLocally">
						<xf:label>Save data locally</xf:label>
					</xf:submit>
					<xf:submit submission="saveRemotely">
						<xf:label>Submit</xf:label>
					</xf:submit>
				</div>
			</body>
		</html>
	</xsl:template>
	<!--
		Process the main sequence for the Instrument. In future this will include section numbering, but for now its just like the regular sequence template
	-->
	<xsl:template match="d:Sequence" mode="master">
		<div class="mainForm">
			<xsl:comment>Start of <xsl:value-of select="@id"/>
			</xsl:comment>
			<xsl:apply-templates select="d:ControlConstructReference" mode="DDIReferenceResolver_3_1"/>
			<xsl:comment>End of <xsl:value-of select="@id"/>
			</xsl:comment>
		</div>
	</xsl:template>
	<!--
		Process a DDI Sequence.
		Finds all referenced ControlConstructs and processes them.
	-->
	<xsl:template match="d:Sequence">
		<!-- xsl:element name="xf:group" -->
		<xsl:if test="r:Label">
			<h2 class="sectionTitle">
				<a name="{@id}">
					<xsl:apply-templates select="r:Label"/>
				</a>
			</h2>
		</xsl:if>
		<xsl:apply-templates select="d:ControlConstructReference" mode="DDIReferenceResolver_3_1"/>
		<xsl:comment>End of <xsl:value-of select="@id"/>
		</xsl:comment>
		<!-- /xsl:element -->
	</xsl:template>
	<!--
		Process IfThenElse Constructs and their child Then and Else elements.
		Both the Then and Else are wrapped in an XForms group. Then and Else get expressed as child XForms groups of this with bindings to allow or disallow response accordingly.
		Referenced ControlConstructs in the Then and Else blocks are then processed.
		At this point ElseIf constructs are ignored.
	-->
	<xsl:template match="d:IfThenElse">
		<!-- xsl:element name="xf:group" -->
		<xsl:comment>Start of <xsl:value-of select="@id"/>
		</xsl:comment>
		<xsl:apply-templates select="./d:ThenConstructReference">
			<xsl:with-param name="ifID">
				<xsl:value-of select="@id"/>
			</xsl:with-param>
		</xsl:apply-templates>
		<xsl:apply-templates select="./d:ElseConstructReference">
			<xsl:with-param name="ifID">
				<xsl:value-of select="@id"/>
			</xsl:with-param>
		</xsl:apply-templates>
		<!-- /xsl:element -->
		<xsl:comment>End of <xsl:value-of select="@id"/>
		</xsl:comment>
	</xsl:template>
	<xsl:template match="d:ThenConstructReference">
		<xsl:param name="ifID"/>
		<xsl:element name="xf:group">
			<xsl:attribute name="bind">bindThen-<xsl:value-of select="$ifID"/></xsl:attribute>
			<xsl:comment>Start of <xsl:value-of select="@id"/></xsl:comment>
			<xsl:apply-templates select="." mode="DDIReferenceResolver_3_1"/>
			<xsl:comment>End of <xsl:value-of select="@id"/></xsl:comment>
		</xsl:element>
	</xsl:template>
	<xsl:template match="d:ElseConstructReference">
		<xsl:param name="ifID"/>
		<xsl:element name="xf:group">
			<xsl:attribute name="bind">bindElse-<xsl:value-of select="$ifID"/></xsl:attribute>
			<xsl:comment>Start of <xsl:value-of select="@id"/></xsl:comment>
			<xsl:apply-templates select="." mode="DDIReferenceResolver_3_1"/>
			<xsl:comment>End of <xsl:value-of select="@id"/></xsl:comment>
		</xsl:element>
	</xsl:template>
	<!--
		Processing instructions for text like objects in DDI.
		Finds the text of the specified languages and prints it out.
	-->
	<xsl:template match="d:Instruction">
		<div class="InterviewerInstruction">
			<xsl:apply-templates select="d:InstructionText"/>
		</div>
	</xsl:template>
	<xsl:template match="r:Description">
		<xsl:if test="ancestor-or-self::*[attribute::xml:lang][1]/@xml:lang=$config/cfg:language">
			<xsl:apply-templates select="* | text()"/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="d:StatementItem">
		<div class="statement">
			<xsl:apply-templates select="./*"/>
		</div>
	</xsl:template>
	<xsl:template match="d:InterviewerInstructionReference">
		<xsl:variable name="instID">
			<xsl:value-of select="r:ID"/>
		</xsl:variable>
		<xsl:apply-templates select="//d:Instruction[@id=$instID]"/>
	</xsl:template>
	<xsl:template match="d:InstrumentName | r:Label">
		<xsl:if test="ancestor-or-self::*[attribute::xml:lang][1]/@xml:lang=$config/cfg:language">
			<xsl:value-of select="."/>
		</xsl:if>
	</xsl:template>
	<xsl:template match="d:InstructionText | d:DisplayText">
		<xsl:if test="ancestor-or-self::*[attribute::xml:lang][1]/@xml:lang=$config/cfg:language">
			<span>
				<xsl:apply-templates select="*"/>
			</span>
		</xsl:if>
	</xsl:template>
	<xsl:template match="d:QuestionText">
		<xsl:if test="ancestor-or-self::*[attribute::xml:lang][1]/@xml:lang=$config/cfg:language">
			<span class="questionText">
				<xsl:apply-templates select="*"/>
			</span>
		</xsl:if>
	</xsl:template>
	<xsl:template match="d:LiteralText">
		<span class="words">
			<xsl:apply-templates select="* | text()"/>
		</span>
	</xsl:template>
	<xsl:template match="d:ConditionalText">
		<span class="wordsub">
			<xsl:element name="xf:output">
				<xsl:attribute name="ref"><xsl:value-of select="./d:Expression/r:Code[@programmingLanguage='responseML_xpath1.0']/text()"/></xsl:attribute>
			</xsl:element>
		</span>
	</xsl:template>
	<!--
		Copy XHTML tags across directly as we are making an XHTML document.
	-->
	<xsl:template match="xhtml:*">
		<xsl:variable name="tagname">
			<xsl:value-of select="local-name()"/>
		</xsl:variable>
		<xsl:element name="{$tagname}">
			<xsl:copy-of select="@*"/>
			<xsl:apply-templates select="* | text()"/>
		</xsl:element>
	</xsl:template>
	<!--
		Transforms for managing Question objects - QuestionConstructs, QuestionItems, MultiQuestionItems.
		These esentially reference, find and call templates to process the ResponseDomains.
	-->
	<xsl:template match="d:QuestionConstruct">
		<xsl:variable name="qcID" select="@id"/>
		<xsl:variable name="question">
			<xsl:value-of select="d:QuestionReference/r:ID"/>
		</xsl:variable>
		<xsl:element name="a">
			<xsl:attribute name="name"><xsl:value-of select="$qcID"/></xsl:attribute>
		</xsl:element>
		<!-- xsl:apply-templates select="d:InterviewerInstructionReference"/  -->
		<xsl:apply-templates select="d:QuestionReference" mode="DDIReferenceResolver_3_1"/>
	</xsl:template>
	<xsl:template name="generateQuestionNumber">
		<xsl:param name="qID"/>
		<span class="questionNumber">
			<xsl:choose>
				<xsl:when test="$instrumentModel//rml:multipart/rml:multipart/*[@id=$qID] and $theme/cfg:subquestion/@visible != false()">
					<xsl:value-of select="$theme/cfg:subquestion/cfg:before"/>
					<xsl:value-of select="substring($roman,$instrumentModel//*[@id=$qID]/position(),1)"/>
					<xsl:value-of select="$theme/cfg:subquestion/cfg:after"/>			
				</xsl:when>
				<xsl:when test="$instrumentModel//rml:multipart/*[@id=$qID] and $theme/cfg:subquestion/@visible != false()">
					<xsl:value-of select="$theme/cfg:subquestion/cfg:before"/>
					<xsl:value-of select="substring($ascii,$instrumentModel//*[@id=$qID]/position(),1)"/>
					<xsl:value-of select="$theme/cfg:subquestion/cfg:after"/>
				</xsl:when>
				<xsl:when test="$theme/cfg:question/@visible != false()">
					<xsl:value-of select="$theme/cfg:question/cfg:before"/>
					<xsl:value-of select="exslt:node-set($numbers)/question[@id=$qID]"/>
					<xsl:value-of select="$theme/cfg:question/cfg:after"/>
				</xsl:when>
			</xsl:choose>
		</span>	
	</xsl:template>
	<xsl:template match="d:MultipleQuestionItem">
		<xsl:variable name="id">
			<xsl:value-of select="@id"/>
		</xsl:variable>
		<xsl:call-template name="generateQuestionNumber">
			<xsl:with-param name="qID" select="@id"/>
		</xsl:call-template>
		<xsl:apply-templates select="d:QuestionText"/>
		<div class="subquestion">
			<xsl:apply-templates select="d:SubQuestions/*"/>			
		</div>
	</xsl:template>
	<xsl:template match="d:QuestionItem">
		<xsl:variable name="id">
			<xsl:value-of select="@id"/>
		</xsl:variable>
		<xsl:comment>Start of question <xsl:value-of select="@id"/>
		</xsl:comment>
		<xsl:call-template name="generateQuestionNumber">
			<xsl:with-param name="qID" select="@id"/>				
		</xsl:call-template>
		<xsl:apply-templates select="./d:NumericDomain | ./d:CodeDomain | ./d:TextDomain | ./d:DateTimeDomain | ./d:StructuredMixedResponseDomain | ./d:CategoryDomain">
			<xsl:with-param name="qcID">
				<xsl:choose>
					<xsl:when test="local-name(parent::node())='SubQuestions'">
						<xsl:value-of select="$id"/>
					</xsl:when>
					<xsl:otherwise>
						<xsl:value-of select="$instrumentModel//*[@questionItemID=$id]/@id"/>
					</xsl:otherwise>
				</xsl:choose>
			</xsl:with-param>
		</xsl:apply-templates>
		<xsl:comment>End of question <xsl:value-of select="@id"/>
		</xsl:comment>
	</xsl:template>
	<!--
		The following chunk of templates take a ResponseDomain (eg. NumericDomain, StringDomain, CodeDomain, etc...) and output the required XForm control.
		At the moment restrictions are not transformed across (eg. minimum or maximums in a range, etc...).
		These restictions would not exist here however, and would be brought across as part of the binding process below, where and xml datatype and restrictions could be added.
	-->
	<xsl:template match="d:NumericDomain">
		<xsl:param name="qcID"/>
		<xsl:element name="xf:input">
			<xsl:attribute name="type">xs:number</xsl:attribute>
			<xsl:attribute name="bind">bindQuestion-<xsl:value-of select="$qcID"/></xsl:attribute>
			<xf:label>
				<xsl:apply-templates select="../d:QuestionText"/>
			</xf:label>
		</xsl:element>
	</xsl:template>
	<xsl:template match="d:StructuredMixedResponseDomain">
		<xsl:param name="qcID"/>
		<span>
			<xsl:apply-templates select="../d:QuestionText"/>
		</span>
		<div style="padding-left:35px;">
			<xsl:apply-templates select="./*">
				<xsl:with-param name="qcID">
					<xsl:value-of select="$qcID"/>
				</xsl:with-param>
			</xsl:apply-templates>
		</div>
	</xsl:template>
	<!-- If the maximum length for a TextDomain is over 500, we can consdier this a text area, rather than just a simple input box -->
	<xsl:template match="d:TextDomain[@maxLength>1000]">
		<xsl:param name="qcID"/>
		<xsl:element name="xf:textarea">
			<xsl:attribute name="bind">bindQuestion-<xsl:value-of select="$qcID"/></xsl:attribute>
			<xsl:attribute name="cols">50</xsl:attribute>
			<xsl:attribute name="rows"><xsl:value-of select="./@maxLength div 500"/></xsl:attribute>
			<xf:label>
				<xsl:apply-templates select="../d:QuestionText"/>
			</xf:label>
		</xsl:element>
		<xsl:apply-templates select="./r:Label"/>
	</xsl:template>	<xsl:template match="d:TextDomain">
		<xsl:param name="qcID"/>
		<xsl:element name="xf:input">
			<xsl:attribute name="bind">bindQuestion-<xsl:value-of select="$qcID"/></xsl:attribute>
			<xf:label>
				<xsl:apply-templates select="../d:QuestionText"/>
			</xf:label>
		</xsl:element>
		<xsl:apply-templates select="./r:Label"/>
	</xsl:template>
	<xsl:template match="d:DateTimeDomain">
		<xsl:param name="qcID"/>
		<xsl:element name="xf:input">
			<xsl:attribute name="bind">bindQuestion-<xsl:value-of select="$qcID"/></xsl:attribute>
			<xf:label>
				<xsl:apply-templates select="../d:QuestionText"/>
			</xf:label>
		</xsl:element>
	</xsl:template>
	<xsl:template match="d:CodeDomain">
		<xsl:param name="qcID"/>
		<xsl:param name="subquestion"/>
		<xsl:variable name="codeSchemeID">
			<xsl:value-of select="r:CodeSchemeReference/r:ID"/>
		</xsl:variable>
		<xsl:element name="xf:select1">
			<xsl:attribute name="bind">bindQuestion-<xsl:value-of select="$qcID"/></xsl:attribute>
			<xsl:attribute name="appearance"><xsl:value-of select="$theme/cfg:codeSchemeDisplay"/></xsl:attribute>
			<xf:label>
				<xsl:apply-templates select="../d:QuestionText"/>
			</xf:label>
			<xsl:for-each select="//l:CodeScheme[@id=$codeSchemeID]/l:Code">
				<xsl:variable name="value"><xsl:value-of select="l:Value"/></xsl:variable>
				<xsl:variable name="categoryID">
					<xsl:value-of select="l:CategoryReference/r:ID"/>
				</xsl:variable>
				<xsl:if test="not($categoryID = 'cat-Admin-Other')">
					<xsl:element name="xf:item">
						<xsl:element name="xf:label">
							<xsl:apply-templates select="//l:Category[@id=$categoryID]/r:Label[not(@type)]"/>
						</xsl:element>
						<xsl:element name="xf:value">
							<xsl:value-of select="$value"/>
						</xsl:element>
					</xsl:element>
				</xsl:if>
			</xsl:for-each>
		</xsl:element>
		<xsl:if test="//l:CodeScheme[@id=$codeSchemeID]/l:Code/l:CategoryReference/r:ID = 'cat-Admin-Other'">
			<xsl:element name="xf:input">
				<xsl:attribute name="bind">bindQuestion-<xsl:value-of select="$qcID"/></xsl:attribute>
				<xf:label>
					<xsl:apply-templates select="//l:Category[@id='cat-Admin-Other']/r:Label"/>
				</xf:label>
			</xsl:element>
		</xsl:if>
	</xsl:template>
	<xsl:template match="d:CategoryDomain">
		<xsl:param name="qcID"/>
		<xsl:param name="subquestion"/>
		<xsl:variable name="categorySchemeID">
			<xsl:value-of select="r:CategorySchemeReference/r:ID"/>
		</xsl:variable>
		<xsl:element name="xf:select">
			<xsl:attribute name="bind">bindQuestion-<xsl:value-of select="$qcID"/></xsl:attribute>
			<xsl:attribute name="appearance">full</xsl:attribute>
			<xf:label>
				<xsl:apply-templates select="../d:QuestionText"/>
			</xf:label>
			<xsl:for-each select="//l:CategoryScheme[@id=$categorySchemeID]/l:Category">
				<xsl:element name="xf:item">
					<xsl:element name="xf:label">
						<xsl:value-of select="r:Label"/>
					</xsl:element>
					<xsl:element name="xf:value">
						<xsl:value-of select="position()"/>
					</xsl:element>
				</xsl:element>
			</xsl:for-each>
		</xsl:element>
	</xsl:template>
	<!--
		At the moment the computation items are used to manage population membership, and only those that have the specific "programmingLanguage" codes are brought across.
		These are turned into xforms outputs, which unfortunately display the membership value (1 or 0) a the very bottom of the form. This can be hidden with CSS, but is still a bit of a hack.
		Once I figure out how XML Events work and how to capture them, I should be able to wrap this in something else.
		
		This works by checking the readonly status of the specificly bound population (which is in turn based on one or more questions which is captured in the binding).
		If this readonly status changes the value of the membership is changed to either a 0 or 1 depending on if the respondant is in or out of the given population, based on 
	-->
	<xsl:template match="d:ComputationItem">
		<xsl:element name="xf:output">
			<xsl:attribute name="bind">bindCI-<xsl:value-of select="@id"/></xsl:attribute>
			<xf:action ev:event="xforms-readonly">
				<xsl:element name="xf:setvalue">
					<xsl:attribute name="bind">bindCI-<xsl:value-of select="@id"/></xsl:attribute>
					<xsl:attribute name="value">0</xsl:attribute>
				</xsl:element>
			</xf:action>
			<xf:action ev:event="xforms-readwrite">
				<xsl:element name="xf:setvalue">
					<xsl:attribute name="bind">bindCI-<xsl:value-of select="@id"/></xsl:attribute>
					<xsl:attribute name="value">1</xsl:attribute>
				</xsl:element>
			</xf:action>
		</xsl:element>
	</xsl:template>
	<xsl:template match="d:Note"/>
	<!-- 
		
		=====================
		BINDING BUILDING MODES
		=====================
		
		This section creates a long list of XForms bindings that give the form it's dynamicness.
		This gathers all QuestionConstructs and make binding, this can be quite expensive on the client end.
		A better solution is to traverse the instrument tree again, and create bindings for only the appropriate constructs.
	 -->
	<xsl:template name="makeBindings">
		<xsl:apply-templates select="//d:QuestionConstruct" mode="bindings"/>
		<xsl:apply-templates select="//d:IfThenElse" mode="bindings"/>
		<xsl:apply-templates select="//d:ComputationItem" mode="bindings"/>
	</xsl:template>
	<!-- 
		This section is a bit of a hack because XSLTForms doesn't dynamically prune not relevant nodes from the tree.
		This means that instead of having tests on the existance of a population, we have to do tests to a value inside it - i.e the membership attribute.
		In the normal ComputationItem template, this is output as an XForms output which using this binding changes the value of the population membership.
	-->
	<xsl:template match="d:ComputationItem" mode="bindings">
		<xsl:variable name="mainpopulation">
			<xsl:value-of select="substring-before(./d:Code/r:Code[@programmingLanguage='xforms1.0-Ramona-Population'],',')"/>
		</xsl:variable>
		<xsl:variable name="subpopulation">
			<xsl:value-of select="substring-after(./d:Code/r:Code[@programmingLanguage='xforms1.0-Ramona-Population'],',')"/>
		</xsl:variable>
		<xsl:variable name="condition">
			<xsl:value-of select="./d:Code/r:Code[@programmingLanguage='xforms1.0-Ramona-Conditional']"/>
		</xsl:variable>
		<xsl:element name="xf:bind">
			<xsl:attribute name="id">bindCI-<xsl:value-of select="@id"/></xsl:attribute>
			<xsl:attribute name="nodeset">//rml:population[@id='<xsl:value-of select="$mainpopulation"/>']//rml:subpopulation[@id='<xsl:value-of select="$subpopulation"/>']/@membership</xsl:attribute>
			<!-- xsl:attribute name="relevant"><xsl:value-of select="$condition"/></xsl:attribute -->
			<xsl:attribute name="readonly"><xsl:value-of select="$condition"/></xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- If we are dealing with a MultipleQuestionItem we need to mine through it to get the sub-responses, but we don't need to create a binding for it.
			This doesn't process ElseIf blocks as those haven't been included yet as a useable conrol mechanism.
	-->
	<xsl:template match="d:QuestionConstruct[not(ancestor::d:ElseIf)]" mode="bindings">
		<xsl:variable name="Qid" select="./d:QuestionReference/r:ID"/>
		<xsl:if test="//d:QuestionItem[@id=$Qid]">
			<xsl:element name="xf:bind">
				<xsl:attribute name="id">bindQuestion-<xsl:value-of select="@id"/></xsl:attribute>
				<xsl:attribute name="nodeset">//rml:response[@id='<xsl:value-of select="@id"/>']</xsl:attribute>
			</xsl:element>
		</xsl:if>
		<xsl:apply-templates select="//d:MultipleQuestionItem[@id=$Qid]/d:SubQuestions//d:QuestionItem" mode="bindings"/>
	</xsl:template>
	<xsl:template match="//d:SubQuestions/d:QuestionItem" mode="bindings">
		<xsl:element name="xf:bind">
			<xsl:attribute name="id">bindQuestion-<xsl:value-of select="@id"/></xsl:attribute>
			<xsl:attribute name="nodeset">//rml:subresponse[@id='<xsl:value-of select="@id"/>']</xsl:attribute>
		</xsl:element>
	</xsl:template>
	<!-- ElseIfs are excluded as their conditions still aren't being added above cause they are hard :( -->
	<xsl:template match="d:IfThenElse[not(ancestor::d:ElseIf)]" mode="bindings">
		<xsl:element name="xf:bind">
			<xsl:attribute name="id">bindThen-<xsl:value-of select="@id"/></xsl:attribute>
			<xsl:attribute name="nodeset">//rml:if[@id='<xsl:value-of select="@id"/>']/rml:then</xsl:attribute>
			<xsl:attribute name="relevant"><xsl:value-of select="d:IfCondition/r:Code[@programmingLanguage='responseML_xpath1.0']/text()"/></xsl:attribute>
			<xsl:attribute name="readonly">not(<xsl:value-of select="d:IfCondition/r:Code[@programmingLanguage='responseML_xpath1.0']/text()"/>)</xsl:attribute>
		</xsl:element>
		<xsl:element name="xf:bind">
			<xsl:attribute name="id">bindElse-<xsl:value-of select="@id"/></xsl:attribute>
			<xsl:attribute name="nodeset">//rml:if[@id='<xsl:value-of select="@id"/>']/rml:else</xsl:attribute>
			<xsl:attribute name="relevant">not(<xsl:value-of select="./d:IfCondition/r:Code[@programmingLanguage='responseML_xpath1.0']/text()"/>)</xsl:attribute>
			<xsl:attribute name="readonly"><xsl:value-of select="./d:IfCondition/r:Code[@programmingLanguage='responseML_xpath1.0']/text()"/></xsl:attribute>
		</xsl:element>
	</xsl:template>

</xsl:stylesheet>

