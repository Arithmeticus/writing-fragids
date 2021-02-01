<?xml version="1.0" encoding="UTF-8"?>
<sch:schema xmlns:sch="http://purl.oclc.org/dsdl/schematron" queryBinding="xslt3"
   xmlns:sqf="http://www.schematron-quickfix.com/validator/process"
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:akita="tag:kalvesmaki.com,2020:ns">
   <sch:ns uri="http://www.tei-c.org/ns/1.0" prefix="tei"/>
   <sch:ns uri="tag:kalvesmaki.com,2020:ns" prefix="akita"/>
   <sch:ns uri="http://www.w3.org/2005/xpath-functions" prefix="fn"/>
   <xsl:variable name="akita:regex1" as="xs:string">("([^"]*)"|'([^']*)')</xsl:variable>
   <xsl:include href="../functions/akita-core.xsl"/>
   
   <sch:let name="akita-declarations" value="/*/processing-instruction(akita)"/>
   <sch:let name="akita-declaration-names" value="
         for $i in $akita-declarations
         return
            analyze-string($i, '(^|\s)name=' || $akita:regex1)/fn:match/fn:group/fn:group"/>
   <sch:pattern>
      <sch:rule context="/tei:*">
         <sch:let name="duplicate-akita-declaration-names"
            value="$akita-declaration-names[index-of($akita-declaration-names, .)[2]]"/>
         <sch:report test="count($akita-declarations) eq 0" sqf:fix="add-akita-pi">A TEI
            Akita file must have at least one akita processing instruction.</sch:report>
         <sch:report test="exists($duplicate-akita-declaration-names)">Duplicate declaration
         names exist: 
            <sch:value-of select="string-join($duplicate-akita-declaration-names, ', ')"/></sch:report>
         <sqf:fix id="add-akita-pi">
            <sqf:description>
               <sqf:title>Add empty Akita processing instruction</sqf:title>
            </sqf:description>
            <sqf:add position="first-child">
               <xsl:processing-instruction name="akita">name="a" work="tag:example.com,2014:work:test" scriptum="tag:example.com,2014:scriptum:test" reference-scriptum="tag:example.com,2014:scriptum:test"</xsl:processing-instruction>
            </sqf:add>
         </sqf:fix>
      </sch:rule>
      <sch:rule context="processing-instruction(akita)">
         <sch:let name="akita-name"
            value="analyze-string(., '(^|\s)name=' || $akita:regex1)/fn:match/fn:group/fn:group"/>
         <sch:let name="akita-work"
            value="analyze-string(., '(^|\s)work=' || $akita:regex1)/fn:match/fn:group/fn:group"/>
         <sch:let name="akita-scriptum"
            value="analyze-string(., '(^|\s)scriptum=' || $akita:regex1)/fn:match/fn:group/fn:group"/>
         <sch:let name="akita-reference-scriptum"
            value="analyze-string(., '(^|\s)reference-scriptum=' || $akita:regex1)/fn:match/fn:group/fn:group"/>
         
         <sch:report test="string-length($akita-name) lt 1">An Akita PI must have a name.</sch:report>
         <sch:report test="string-length($akita-work) lt 1">An Akita PI must have a work.</sch:report>
         <sch:report test="string-length($akita-scriptum) lt 1">An Akita PI must have a scriptum.</sch:report>
         <sch:report test="string-length($akita-reference-scriptum) lt 1">An Akita PI must have a reference scriptum.</sch:report>
      </sch:rule>
   </sch:pattern>
   
   <sch:pattern>
      <sch:rule context="*[@n]">
         <sch:let name="this-n" value="@n"/>
         <sch:let name="is-integer-castable" value="@n castable as xs:integer"/>
         <sch:let name="dupe-siblings" value="../*[@n eq $this-n] except ."/>
         <sch:let name="inherited-akita"
            value="ancestor::*[processing-instruction('akita')][1]/processing-instruction('akita')"
         />
         <sch:report test="exists($dupe-siblings)" role="warning">Most values of @n are unique.</sch:report>
      </sch:rule>
      <sch:rule context="/*/tei:text">
         <sch:let name="these-types" value="tokenize(normalize-space(@type), ' ')"/>
         <sch:let name="these-akita-types" value="$these-types[starts-with(., 'akita:')]"/>
         <sch:let name="these-akita-names" value="
               for $i in $these-akita-types
               return
                  replace($i, '^akita:', '')"/>
         <sch:let name="unique-akita-names" value="distinct-values($these-akita-names)"/>
         <sch:let name="akita-declaration-positions" value="
               for $i in $unique-akita-names
               return
                  (index-of($akita-declaration-names, $i), 0)[1]"/>
         <sch:let name="unique-akita-names-undefined-by-pos"
            value="index-of($akita-declaration-positions, 0)"/>
         <sch:let name="unique-akita-names-undefined"
            value="$unique-akita-names[position() = $unique-akita-names-undefined-by-pos]"/>
         
         <sch:report test="count($these-akita-names) ne count($unique-akita-names)">Akita names
            should not be repeated.</sch:report>
         <sch:report test="exists($unique-akita-names-undefined)">Undefined Akita names: 
            <sch:value-of select="$unique-akita-names-undefined"/></sch:report>
      </sch:rule>
   </sch:pattern>
</sch:schema>