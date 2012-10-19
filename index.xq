xquery version "1.0";
declare namespace s="ddi:studyunit:3_1"; 
declare namespace r="ddi:reusable:3_1"; 
declare namespace g = "ddi:group:3_1";
declare namespace ddi="ddi:instance:3_1"; 
declare namespace cfg="rml:RamonaConfig_v1";

import module namespace request="http://exist-db.org/xquery/request";
import module namespace transform="http://exist-db.org/xquery/transform";

declare option exist:serialize "method=xhtml media-type=text/html indent=yes"; 

let $form-id := request:get-parameter("form-id", ())

let $config := doc('./config.xml')/cfg:config

let $collection := collection(concat($config/cfg:existBase, '/forms'))

let $params := <parameters></parameters>

return
    if (empty($form-id)) 
    then
        <html>
            <head>
                <title>List of ramona DDI-forms</title>
            </head>
            <body>
            <h3>DDI-files in ramona {concat($config/existBase, '/forms')}</h3>
            <ul>
            {
                for $instance in $collection/ddi:DDIInstance
                    return
                        <li>
                            <strong><a href="?form-id={$instance/@id}">{$instance//r:Citation/r:Title/text()}</a></strong>
                            <p>
                                {$instance//g:Abstract/r:Content}
                            </p>
                        </li>
            }
            </ul>
            </body>
        </html>
    else
         transform:transform($collection/ddi:DDIInstance[@id=$form-id]/.., xs:anyURI(concat("xmldb:exist://", $config/cfg:existBase,"/DDI-Instrument_to_XForms.xsl")), $params)