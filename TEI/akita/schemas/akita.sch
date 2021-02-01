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
      <sch:rule context="processing-instruction('akita-mark-tree-by-hierarchy')">
         <sch:let name="this-count"
            value="count(preceding::processing-instruction('akita-mark-tree-by-hierarchy')) + 1"/>
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
      <sch:rule context="processing-instruction('akita-mark-tree-by-anchors')">
         <sch:let name="this-count"
            value="count(preceding::processing-instruction('akita-mark-tree-by-anchors')) + 1"/>
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
   
   <!--<sch:pattern>
      <sch:rule context="processing-instruction()">
         <sch:let name="this-name" value="name(.)"/>
         <sch:let name="is-akita-pi" value="$this-name = $akita:akita-processing-instruction-names"
         />
         <sch:let name="content-norm" value="normalize-space(.)"/>
         <sch:let name="pi-rules" value="$akita:akita-pi-content-map($this-name)"/>
         <sch:let name="content-should-be-simple" value="$pi-rules instance of xs:string"/>
         <sch:let name="simple-content-matches" value="
               if ($content-should-be-simple) then
                  matches($content-norm, '^' || $pi-rules || '$')
               else
                  true()"/>
         <sch:let name="content-parsed" value="
               if ($content-should-be-simple) then
                  ()
               else
                  akita:parse-attributes($content-norm)"/>
         <sch:let name="allowed-attribute-names" value="
               if ($content-should-be-simple or not(exists($pi-rules))) then
                  ()
               else
                  map:keys($pi-rules)"/>
         <sch:let name="actual-attribute-names" value="$content-parsed/akita:attribute/@name"/>
         <sch:let name="good-attribute-names" value="
               for $i in
               $actual-attribute-names,
                  $j in replace($i, '\d+', '1')
               return
                  if ($j = $allowed-attribute-names) then
                     $i
                  else
                     ()"/>
         <sch:let name="bad-attribute-names"
            value="$actual-attribute-names[not(. = $good-attribute-names)]"/>
         <sch:let name="unused-attribute-names"
            value="$allowed-attribute-names[not(. = $actual-attribute-names)]"/>
         <sch:let name="type-levels" value="
               sort(for $i in $good-attribute-names[matches(., 'level-\d+')]
               return
                  xs:integer(replace($i, '\D+', '')))"/>
         <sch:let name="incorrect-levels" value="
               if (count($type-levels) gt 0)
               then
                  (for $i in (1 to count($type-levels))
                  return
                     
                     (if ($i eq $type-levels[$i]) then
                        ()
                     else
                        $i))
               else
                  ()"/>
         <sch:let name="attributes-with-bad-values" value="
               for $i in $good-attribute-names,
                  $j in $pi-rules(replace($i, '\d+', '1')),
                  $k in $content-parsed/akita:attribute[@name = $i]
               return
                  (
                  if (matches($k, '^' || $j || '$')) then
                     ()
                  else
                     $i
                  )"/>
           
         
         
         
         <sch:report test="$is-akita-pi and $content-should-be-simple and not($simple-content-matches)">
            <sch:value-of select="$this-name || 'should match the following regular expression: ' || $pi-rules"
            />
         </sch:report>
         <sch:report test="$is-akita-pi and exists($bad-attribute-names)">
            <sch:value-of
               select="string-join($bad-attribute-names, ', ') || ' not allowed; try: ' || string-join($unused-attribute-names, ', ')"
            />
         </sch:report>
         <sch:report test="$is-akita-pi and exists($incorrect-levels)">Incorrect declarations for
            level(s) <sch:value-of select="
                  string-join(
                  for $i in $incorrect-levels
                  return
                     string($i), ', ')"/></sch:report>
         <sch:report test="$is-akita-pi and exists($attributes-with-bad-values)">
            <sch:value-of select="
                  for $i in $attributes-with-bad-values
                  return
                     ($i || ' should match the following regular expression: ' || $pi-rules(replace($i, '\d+', '1')) || ' ')"
            />
         </sch:report>
      </sch:rule>
   </sch:pattern>-->
   
   
</sch:schema>