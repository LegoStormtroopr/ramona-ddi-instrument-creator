#!/bin/bash
EXIST_IP="$1" 
theme="$2" 

curl $EXIST_IP/exist/rest/Ramona/themes/$theme.xml -T ./themes/$theme/theme.xml
