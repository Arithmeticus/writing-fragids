<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:akita="tag:kalvesmaki.com,2020:ns">
   <sch:ns uri="http://www.tei-c.org/ns/1.0" prefix="tei"/>
   <sch:ns uri="tag:kalvesmaki.com,2020:ns" prefix="akita"/>
   <sch:ns uri="http://www.w3.org/2005/xpath-functions" prefix="fn"/>
   <sch:ns uri="http://www.w3.org/2005/xpath-functions/map" prefix="map"/>

   <xsl:include href="../functions/akita-core.xsl"/>
   
   <sch:let name="akita-vocabulary" value="akita:resolve-vocabulary(/)"/>
   <sch:let name="akita-vocabulary-validated" value="akita:validate-vocabulary($akita-vocabulary)"/>
   <sch:let name="tei-file-mapped" value="
         if (exists(/tei:*)) then
            akita:build-tei-wf-map(/)
         else
            ()"/>
   
   
   <sch:pattern>
      <sch:rule context="processing-instruction() | *">
         <sch:let name="nid" value="generate-id(.)"/>
         <sch:let name="vocab-entry" value="$akita-vocabulary-validated/*/*[@nid = $nid]"/>
         <sch:let name="vocab-errors" value="$vocab-entry/akita:error"/>
         <sch:let name="included-vocab-errors" value="$vocab-entry/self::akita:include//akita:error"/>
         <sch:report test="exists($vocab-errors)">
            <sch:value-of select="
                  if (count($vocab-errors) eq 1) then
                     '1 ERROR: '
                  else
                     string(count($vocab-errors)) || ' ERRORS: '"/>
            <sch:value-of select="
                  for $i in $vocab-errors
                  return
                     ($i/akita:message || ' [' || $i/akita:code || ': ' || $i/akita:rule || ']&#xd;&#xa;')"
            />
         </sch:report>
         <sch:report test="exists($included-vocab-errors)">
            <sch:value-of select="
                  for $i in $included-vocab-errors
                  return
                     ('(' || $i/ancestor::akita:vocab[1]/@src || ') ' || $i/akita:message || ' [' || $i/akita:code || ': ' || $i/akita:rule || ']&#xd;&#xa;')"
            />
         </sch:report>
      </sch:rule>
   </sch:pattern>
   
   <sch:pattern>
      <sch:rule context="processing-instruction('akita-mark-subtree-by-hierarchy')">
         <sch:let name="this-count"
            value="count(preceding::processing-instruction('akita-mark-subtree-by-hierarchy')) + 1"/>
         <sch:let name="this-key" value="'h' || string($this-count)"/>
         <sch:let name="this-map" value="$tei-file-mapped($this-key)"/>
         <sch:let name="these-errors" value="$this-map/*/akita:error"/>
         <sch:report test="exists($these-errors)"><sch:value-of select="
                  if (count($these-errors) eq 1) then
                     '1 ERROR: '
                  else
                     string(count($these-errors)) || ' ERRORS: '"/>
            <sch:value-of select="
                  for $i in $these-errors
                  return
                     ($i/akita:message || ' [' || $i/akita:code || ': ' || $i/akita:rule || ']&#xd;&#xa;')"
            /></sch:report>
      </sch:rule>
      <sch:rule context="processing-instruction('akita-mark-subtree-by-anchors')">
         <sch:let name="this-count"
            value="count(preceding::processing-instruction('akita-mark-subtree-by-anchors')) + 1"/>
         <sch:let name="this-key" value="'a' || string($this-count)"/>
         <sch:let name="this-map" value="$tei-file-mapped($this-key)"/>
         <sch:let name="these-errors" value="$this-map/*/akita:error"/>
         <sch:report test="exists($these-errors)"><sch:value-of select="
                  if (count($these-errors) eq 1) then
                     '1 ERROR: '
                  else
                     string(count($these-errors)) || ' ERRORS: '"/>
            <sch:value-of select="
                  for $i in $these-errors
                  return
                     ($i/akita:message || ' [' || $i/akita:code || ': ' || $i/akita:rule || ']&#xd;&#xa;')"
            /></sch:report>
      </sch:rule>
   </sch:pattern>
   
   
   
</sch:schema>