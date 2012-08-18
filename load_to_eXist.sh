#!/bin/sh
EXIST_IP="127.0.0.1:8181"

# Upload XSLT

curl $EXIST_IP/exist/rest/Ramona/DDI-Instrument_to_XForms.xsl -T DDI-Instrument_to_XForms.xsl
curl $EXIST_IP/exist/rest/Ramona/DDI_to_FlowDiagram.xsl -T DDI_to_FlowDiagram.xsl
curl $EXIST_IP/exist/rest/Ramona/DDI_to_Graphviz.xsl -T DDI_to_Graphviz.xsl
curl $EXIST_IP/exist/rest/Ramona/DDI_to_ResponseML.xsl -T DDI_to_ResponseML.xsl
curl $EXIST_IP/exist/rest/Ramona/responseML_to_Skips.xsl -T responseML_to_Skips.xsl
curl $EXIST_IP/exist/rest/Ramona/stringFunctions.xsl -T stringFunctions.xsl


# Upload Config
curl $EXIST_IP/exist/rest/Ramona/config.xml -T config.xml

# Upload themes
./load_theme.sh $EXIST_IP koala
./load_theme.sh $EXIST_IP ramona

# Upload example file
curl $EXIST_IP/exist/rest/ddi/dogsurvey.xml -T forms/DogSurvey.xml

