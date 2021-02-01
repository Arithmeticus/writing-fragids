<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:wf="tag:kalvesmaki.com,2020:ns"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   queryBinding="xslt2"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process">
   <sch:ns prefix="wf" uri="tag:kalvesmaki.com,2020:ns"/>
   <sch:ns uri="http://www.w3.org/2005/xpath-functions/map" prefix="map"/>
   <xsl:include href="../wf-functions.xsl"/>
   <sch:pattern>
      <sch:rule context="wf-uri">
         <sch:let name="wf-uri-parsed" value="wf:parse-wf-uri(.)"/>
         <sch:let name="wf-uri-errors" value="$wf-uri-parsed('errors')"/>
         <sch:report test="exists($wf-uri-errors)">
            <sch:value-of select="
                  for $i in $wf-uri-errors
                  return
                     string-join($i/wf:message || ' [' || $i/wf:code || ': ' || $i/wf:definition || ']', ' | ')"
            />
         </sch:report>
         <sch:report test="false() and contains(., 'HSS')">
            <!--<sch:value-of select="map:keys($wf-uri-parsed)"/>-->
            <sch:value-of select="wf:map-to-string($wf-uri-parsed)"/>
         </sch:report>
      </sch:rule>
      
      <sch:rule context="scriptum-types/scriptum-type | work-types/work-type">
         <sch:let name="this-xml-id" value="@xml:id"/>
         <sch:let name="wf-support" value="wf-support"/>
         <sch:let name="this-element-name" value="local-name(.)"/>
         <sch:let name="examples"
            value="/wf-examples/wf-example[*[local-name(.) eq $this-element-name][. = $this-xml-id]]"
         />
         <sch:let name="example-count" value="count($examples)"/>
         <sch:report test="not($wf-support eq 'none') and $example-count lt 4" role="warning">
            <sch:value-of select="
                  $this-element-name || ' ' || $this-xml-id || ' has ' ||
                  (
                  if ($example-count eq 0) then
                     'no examples.'
                  else
                     if ($example-count eq 1) then
                        'only 1 example.'
                     else
                        ('only ' || string($example-count) || ' examples.')
                  )"/>
         </sch:report>
      </sch:rule>
      
      <!--<sch:rule context="work-type/scriptum-type">
         <sch:let name="work-type" value="../@xml:id"/>
         <sch:let name="scriptum-type" value="."/>
         <sch:let name="matching-examples"
            value="/wf-examples/wf-example[work-type = $work-type][scriptum-type = $scriptum-type]"
         />
         <sch:let name="matching-example-count" value="count($matching-examples)"/>
         <sch:report test="$matching-example-count eq 0">No examples have yet been supplied for a
               <sch:value-of select="$work-type"/> on <sch:value-of select="$scriptum-type"
            />.</sch:report>
      </sch:rule>-->
      
      <sch:rule context="wf-example/work-type">
         <sch:let name="this-type" value="."/>
         <sch:let name="matching-definition" value="/*/work-types/work-type[@xml:id = $this-type]"/>
         <sch:report test="not(exists($matching-definition))">Work type not defined.</sch:report>
      </sch:rule>
      <sch:rule context="wf-example/scriptum-type">
         <sch:let name="this-type" value="."/>
         <sch:let name="matching-definition" value="/*/scriptum-types/scriptum-type[@xml:id = $this-type]"/>
         <sch:report test="not(exists($matching-definition))">Scriptum type not defined.</sch:report>
      </sch:rule>
      
   </sch:pattern>
</sch:schema>