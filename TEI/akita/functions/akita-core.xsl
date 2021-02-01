<xsl:stylesheet xmlns:akita="tag:kalvesmaki.com,2020:ns" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   version="3.0">
   <!-- Core function library for TEI Akita. This library is intended to be
      included or imported by other stylesheets. It will not do anything on its
      own as a starting master stylesheet in an XSLT transformation.
   -->
   
   <xsl:variable name="akita:akita-namespace" select="'tag:kalvesmaki.com,2020:ns'"/>
   
   <xsl:variable name="akita:akita-pi-content-map" as="map(*)">
      <!-- Items in the map either have a regular expression against which the normalized space
      value of the PI should match, or a have a make of key-value pairs specifying an attribute-
      style content. -->
      <!-- Regular expressions are assumed to be bound to the entire beginning and end of the string.
      That is, a regular expression should be wrapped by ^ and $ before evaluation. -->
      <xsl:map>
         <!-- Include has one value, an href, which can be just about anything except space. -->
         <xsl:map-entry key="'akita-include'" select="'\S+'"/>
         <xsl:map-entry key="'akita-work'" select="$akita:ncname-regex || '( \S+)+'"/>
         <xsl:map-entry key="'akita-scriptum'" select="$akita:ncname-regex || '( \S+)+'"/>
         <xsl:map-entry key="'akita-mark-tree-by-hierarchy'">
            <xsl:map>
               <!-- TEI users are accustomed to a # as prefacing a target, so it is accommodated here. -->
               <xsl:map-entry key="'idrefs'"
                  select="'#?' || $akita:ncname-regex || '( #?' || $akita:ncname-regex || ')*'"/>
               <xsl:map-entry key="'work'" select="$akita:ncname-regex"/>
               <xsl:map-entry key="'scriptum'" select="$akita:ncname-regex"/>
               <xsl:map-entry key="'reference-scriptum'" select="$akita:ncname-regex"/>
               <xsl:map-entry key="'reference-system-type'" select="'(logical|material)'"/>
            </xsl:map>
         </xsl:map-entry>
         <xsl:map-entry key="'akita-mark-tree-by-anchors'">
            <xsl:map>
               <xsl:map-entry key="'level-1-type'" select="$akita:ncname-regex"/>
               <xsl:map-entry key="'work'" select="$akita:ncname-regex"/>
               <xsl:map-entry key="'scriptum'" select="$akita:ncname-regex"/>
               <xsl:map-entry key="'reference-scriptum'" select="$akita:ncname-regex"/>
               <xsl:map-entry key="'reference-system-type'" select="'(logical|material)'"/>
            </xsl:map>
         </xsl:map-entry>
      </xsl:map>
   </xsl:variable>
   <xsl:variable name="akita:akita-processing-instruction-names" as="xs:string+"
      select="map:keys($akita:akita-pi-content-map)"/>
   <xsl:variable name="akita:akita-pi-mark-tree-by-hierarchy-rules"
      select="$akita:akita-pi-content-map('akita-mark-tree-by-hierarchy')"
      as="map(*)"/>
   <xsl:variable name="akita:akita-pi-mark-tree-by-anchors-rules"
      select="$akita:akita-pi-content-map('akita-mark-tree-by-anchors')"
      as="map(*)"/>
   
   <xsl:variable name="akita:error-map" as="map(*)">
      <xsl:map>
         <xsl:map-entry key="'ak001'">PI akita-include should consist of exactly one value, namely a relative or absolute URI to an Akita file.</xsl:map-entry>
         <xsl:map-entry key="'ak002'">Akita inclusion hrefs must point to a well-formed XML document that is available.</xsl:map-entry>
         <xsl:map-entry key="'ak003'">No akita href should point to the host document.</xsl:map-entry>
         <xsl:map-entry key="'ak004'">An akita inclusion must point to an akita document.</xsl:map-entry>
         <xsl:map-entry key="'ak005'">Every work or scriptum must have an id.</xsl:map-entry>
         <xsl:map-entry key="'ak006'">All ids must be unique.</xsl:map-entry>
         <xsl:map-entry key="'ak007'">Every work or scriptum must have at least one IRI.</xsl:map-entry>
         <xsl:map-entry key="'ak008'">Among works, or among scripta, IRIs must be unique.</xsl:map-entry>
         <xsl:map-entry key="'ak009'">
            <xsl:value-of
               select="'Akita processing instruction names must be one of the following: ' || string-join($akita:akita-processing-instruction-names, ', ')"
            />
         </xsl:map-entry>
         <xsl:map-entry key="'ak010'">Every idref must have a matching target.</xsl:map-entry>
         <xsl:map-entry key="'ak011'">Every level type must have a matching target.</xsl:map-entry>
         <xsl:map-entry key="'ak012'">No material reference system should be tethered to elements representing logical units.</xsl:map-entry>
         <xsl:map-entry key="'ak013'">No logical reference system should be tethered to elements representing material units.</xsl:map-entry>
         <xsl:map-entry key="'ak014'">
            <xsl:value-of select="'Attribute names in an akita PI marking a tree by hierarchy must be one of the following: ' || string-join(map:keys($akita:akita-pi-mark-tree-by-hierarchy-rules), ', ')"/>
         </xsl:map-entry>
         <xsl:map-entry key="'ak015'">
            <xsl:value-of select="'Attribute names in an akita PI marking a tree by anchors must be one of the following: ' || string-join(map:keys($akita:akita-pi-mark-tree-by-anchors-rules), ', ')"/>
         </xsl:map-entry>
         <xsl:map-entry key="'ak016'">Every akita PI value must match its defined pattern.</xsl:map-entry>
         <xsl:map-entry key="'ak017'">In an akita PI marking a tree by anchors, @level-1-type must be succeeded by @level-2-type and so on, without duplication.</xsl:map-entry>
         
      </xsl:map>
   </xsl:variable>
   
   <xsl:function name="akita:resolve-vocabulary" as="document-node()">
      <!-- Input: a TEI file or an akita file -->
      <!-- Output: the Akita vocabulary in a single document -->
      <xsl:param name="input" as="document-node()"/>
      <xsl:document>
         <xsl:apply-templates select="$input" mode="akita:resolve-vocabulary"/>
      </xsl:document>
   </xsl:function>
   
   <xsl:mode name="akita:resolve-vocabulary" on-no-match="shallow-skip"/>
   
   <xsl:template match="processing-instruction('akita-include') | akita:include" mode="akita:resolve-vocabulary">
      <xsl:param name="uris-already-visited" as="xs:string*" tunnel="yes"/>
      <xsl:variable name="this-href-val" select="(@href, .)[1]"/>
      <xsl:variable name="these-vals" select="tokenize(normalize-space($this-href-val), ' ')"/>
      <xsl:variable name="this-base-uri" select="base-uri(.)"/>
      <xsl:variable name="this-href" select="resolve-uri($these-vals[1], $this-base-uri)"/>
      <xsl:element name="include" namespace="{$akita:akita-namespace}">
         <xsl:attribute name="nid" select="generate-id(.)"/>
         <xsl:choose>
            <xsl:when test="count($these-vals) ne 1">
               <xsl:sequence select="akita:log-error('ak001', ())"/>
            </xsl:when>
            <xsl:when test="$this-href eq $this-base-uri">
               <xsl:sequence
                  select="akita:log-error('ak003', $this-href || ' is self-referential. ')"/>
            </xsl:when>
            <xsl:when test="not(doc-available($this-href))">
               <xsl:sequence
                  select="akita:log-error('ak002', 'No doc available at ' || $this-href)"/>
            </xsl:when>
            <xsl:otherwise>
               <xsl:apply-templates select="doc($this-href)" mode="#current">
                  <xsl:with-param name="uris-already-visited" tunnel="yes"
                     select="$uris-already-visited, $this-base-uri"/>
               </xsl:apply-templates>
            </xsl:otherwise>
         </xsl:choose>
      </xsl:element>
   </xsl:template>
   
   <xsl:template match="document-node()" mode="akita:resolve-vocabulary">
      <xsl:choose>
         <xsl:when test="exists(tei:*) or exists(akita:vocab)">
            <xsl:element namespace="{$akita:akita-namespace}" name="vocab">
               <xsl:attribute name="src" select="base-uri(.)"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:element>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence
               select="akita:log-error('ak004', base-uri(.) || ' has as its root element ' || local-name(.) || ', namespace ' || namespace-uri(.))"
            />
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="akita:*/text()" mode="akita:resolve-vocabulary">
      <xsl:value-of select="."/>
   </xsl:template>
   <xsl:template match="akita:work | akita:scriptum | akita:iri | akita:desc" mode="akita:resolve-vocabulary">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <!-- We generate node id, to facilitate lookup in, e.g., a Schematron process looking for errors. -->
         <xsl:attribute name="nid" select="generate-id(.)"/>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
   </xsl:template>
   <xsl:template
      match="processing-instruction('akita-work') | processing-instruction('akita-scriptum')"
      mode="akita:resolve-vocabulary">
      <xsl:variable name="this-pi-name" select="name(.)" as="xs:string"/>
      <xsl:variable name="this-element-name" select="tokenize($this-pi-name, '-')[2]" as="xs:string"/>
      <xsl:variable name="these-values" select="tokenize(normalize-space(.), ' ')" as="xs:string*"/>
      <xsl:variable name="this-expected-regex" select="$akita:akita-pi-content-map($this-pi-name)" as="xs:string"/>
      <xsl:variable name="value-is-well-formed" select="matches(normalize-space(.), '^' || $this-expected-regex || '$')" as="xs:boolean"/>
      <xsl:element namespace="{$akita:akita-namespace}" name="{$this-element-name}">
         <xsl:attribute name="xml:id" select="$these-values[1]"/>
         <xsl:attribute name="nid" select="generate-id(.)"/>
         <xsl:if test="not($value-is-well-formed)">
            <xsl:sequence
               select="akita:log-error('ak015', 'Value should match the following regular expression: ' || $this-expected-regex)"
            />
         </xsl:if>
         <xsl:for-each select="tail($these-values)">
            <xsl:element name="iri" namespace="{$akita:akita-namespace}">
               <xsl:value-of select="."/>
            </xsl:element>
         </xsl:for-each>
      </xsl:element>
   </xsl:template>
   <xsl:template match="processing-instruction()" mode="akita:resolve-vocabulary" priority="-1">
      <xsl:variable name="this-name" select="name(.)" as="xs:string"/>
      <xsl:if test="starts-with($this-name, 'akita-') and not($this-name = $akita:akita-processing-instruction-names)">
         <xsl:element namespace="{$akita:akita-namespace}" name="vocab">
            <xsl:attribute name="nid" select="generate-id(.)"/>
            <xsl:sequence select="akita:log-error('ak009', $this-name)"/>
         </xsl:element>
      </xsl:if>
   </xsl:template>
   
   
   <xsl:function name="akita:validate-vocabulary" as="document-node()">
      <!-- Input: a resolved akita vocabulary -->
      <!-- Output: the same, but with error messages reported -->
      <xsl:param name="resolved-vocabulary" as="document-node()"/>
      <xsl:apply-templates select="$resolved-vocabulary" mode="akita:validate-vocabulary"/>
   </xsl:function>
   
   <xsl:mode name="akita:validate-vocabulary" on-no-match="shallow-copy"/>
   
   <xsl:template match="/*" mode="akita:validate-vocabulary">
      <xsl:variable name="all-work-iris" select=".//akita:work/akita:iri" as="element()*"/>
      <xsl:variable name="duplicate-work-iris" as="element()*">
         <xsl:for-each-group select="$all-work-iris" group-by=".">
            <xsl:if test="count(current-group()) gt 1">
               <xsl:sequence select="current-group()"/>
            </xsl:if>
         </xsl:for-each-group> 
      </xsl:variable>
      
      <xsl:variable name="all-scriptum-iris" select=".//akita:scriptum/akita:iri" as="element()*"/>
      <xsl:variable name="duplicate-scriptum-iris" as="element()*">
         <xsl:for-each-group select="$all-scriptum-iris" group-by=".">
            <xsl:if test="count(current-group()) gt 1">
               <xsl:sequence select="current-group()"/>
            </xsl:if>
         </xsl:for-each-group> 
      </xsl:variable>
      
      <xsl:variable name="all-ids" select=".//@xml:id" as="attribute()*"/>
      <xsl:variable name="duplicate-ids" as="xs:string*">
         <xsl:for-each-group select="$all-ids" group-by=".">
            <xsl:if test="count(current-group()) gt 1">
               <xsl:sequence select="current-grouping-key()"/>
            </xsl:if>
         </xsl:for-each-group> 
      </xsl:variable>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:apply-templates mode="#current">
            <xsl:with-param name="duplicate-work-iris" tunnel="yes" select="$duplicate-work-iris"/>
            <xsl:with-param name="duplicate-scriptum-iris" tunnel="yes" select="$duplicate-scriptum-iris"/>
            <xsl:with-param name="duplicate-ids" tunnel="yes" select="$duplicate-ids"/>
         </xsl:apply-templates>
      </xsl:copy>
      
   </xsl:template>
   
   <xsl:template match="akita:work | akita:scriptum" mode="akita:validate-vocabulary">
      <xsl:param name="duplicate-work-iris" tunnel="yes" as="element()*"/>
      <xsl:param name="duplicate-scriptum-iris" tunnel="yes" as="element()*"/>
      <xsl:param name="duplicate-ids" tunnel="yes" as="xs:string*"/>
      
      <xsl:variable name="these-duplicate-work-iris"
         select="self::akita:work/akita:iri[. = $duplicate-work-iris]" as="element()*"/>
      <xsl:variable name="these-duplicate-scriptum-iris"
         select="self::akita:scriptum/akita:iri[. = $duplicate-scriptum-iris]" as="element()*"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:if test="not(exists(@xml:id))">
            <xsl:sequence select="akita:log-error('ak005', ())"/>
         </xsl:if>
         <xsl:if test="@xml:id = $duplicate-ids">
            <xsl:sequence select="akita:log-error('ak006', ())"/>
         </xsl:if>
         <xsl:if test="not(exists(akita:iri))">
            <xsl:sequence select="akita:log-error('ak007', ())"/>
         </xsl:if>
         <xsl:if test="exists($these-duplicate-work-iris)">
            <xsl:sequence select="akita:log-error('ak008', string-join(distinct-values($these-duplicate-work-iris), ', '))"/>
         </xsl:if>
         <xsl:if test="exists($these-duplicate-scriptum-iris)">
            <xsl:sequence select="akita:log-error('ak008', string-join(distinct-values($these-duplicate-scriptum-iris), ', '))"/>
         </xsl:if>
         <xsl:apply-templates mode="#current"/>
      </xsl:copy>
      
   </xsl:template>
   
   
   <xsl:function name="akita:log-error" as="element()?" visibility="private">
      <!-- Input: a string corresponding to an error code; a string; a boolean -->
      <!-- Output: an element that wraps the error code, its standard message, and any contextual 
      comments (the 2nd parameter). If the third parameter is true, then the same message is returned
      as a message error. -->
      <xsl:param name="error-code" as="xs:string"/>
      <xsl:param name="message" as="xs:string?"/>
      
      <xsl:variable name="this-error-definition" select="$akita:error-map($error-code)"/>
      <xsl:if test="exists($this-error-definition)">
         <error xmlns="tag:kalvesmaki.com,2020:ns">
            <code>
               <xsl:value-of select="$error-code"/>
            </code>
            <rule>
               <xsl:value-of select="$this-error-definition"/>
            </rule>
            <message>
               <xsl:value-of select="$message"/>
            </message>
         </error>
      </xsl:if>
      
   </xsl:function>
   
   <xsl:variable name="akita:ncname-regex" select="'[\i-[:]][\c-[:]]*'" as="xs:string"/>
   <xsl:variable name="akita:apo-regex" as="xs:string">'([^']*)'</xsl:variable>
   <xsl:variable name="akita:quo-regex" as="xs:string">"([^"]*)"</xsl:variable>
   <xsl:variable name="akita:attribute-regex" as="xs:string">
      <xsl:value-of
         select="'(' || $akita:ncname-regex || '(:' || $akita:ncname-regex || ')?) ?= ?(' 
         || $akita:apo-regex || '|' || $akita:quo-regex || ')'"
      />
   </xsl:variable>
   <xsl:function name="akita:parse-attributes" visibility="private" as="element()">
      <!-- Input: a string -->
      <!-- Output: map with key-value pairs representing the string parsed as if attribute name + values -->
      <!-- Format should by like XML attributes, name="value" or name='value' -->
      <xsl:param name="input" as="xs:string"/>
      <xsl:variable name="input-normalized" select="normalize-space($input)" as="xs:string"/>
      <input xmlns="tag:kalvesmaki.com,2020:ns">
         <xsl:analyze-string select="$input-normalized" regex="{$akita:attribute-regex}">
            <xsl:matching-substring>
               <xsl:variable name="first-digits" as="xs:string?">
                  <xsl:analyze-string select="regex-group(1)" regex="^\D+(\d+)">
                     <xsl:matching-substring>
                        <xsl:value-of select="regex-group(1)"/>
                     </xsl:matching-substring>
                  </xsl:analyze-string>
               </xsl:variable>
               <attribute name="{regex-group(1)}">
                  <xsl:if test="string-length($first-digits) gt 0">
                     <xsl:attribute name="n" select="$first-digits"/>
                  </xsl:if>
                  <xsl:value-of select="regex-group(4) || regex-group(5)"/>
               </attribute>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:if test="matches(., '\S+')">
                  <unparsed-text>
                     <xsl:value-of select="."/>
                  </unparsed-text>
               </xsl:if>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </input>
      
   </xsl:function>
   
   
   
   
   
   <xsl:function name="akita:build-tei-wf-map" as="map(*)?" visibility="public">
      <!-- Input: a TEI file with Akita markers -->
      <!-- Output: a map, with one map entry per Akita marker, with value consisting
      of the TEI file arranged exclusive to the particular reference system. Error messages
      will be logged in the results when encountered. -->
      <xsl:param name="tei-akita-file" as="document-node()?"/>

      <xsl:variable name="akita-markers-by-hierarchy"
         select="$tei-akita-file//processing-instruction('akita-mark-tree-by-hierarchy')"/>
      <xsl:variable name="akita-markers-by-anchors"
         select="$tei-akita-file//processing-instruction('akita-mark-tree-by-anchors')"/>
      
      <xsl:variable name="akita-markers-by-hierarchy-parsed" as="element()*" select="
            for $i in $akita-markers-by-hierarchy
            return
               akita:parse-attributes($i)"/>
      <xsl:variable name="akita-markers-by-anchors-parsed" as="element()*" select="
            for $i in $akita-markers-by-anchors
            return
               akita:parse-attributes($i)"/>
      
      <xsl:choose>
         <xsl:when test="not(exists($tei-akita-file/tei:*))">
            <xsl:message select="'akita:build-tei-wf-map() must be applied to a TEI document'"/>
         </xsl:when>
         <xsl:when test="not(exists($akita-markers-by-anchors)) and not(exists($akita-markers-by-hierarchy))">
            <xsl:message select="'akita:build-tei-wf-map() must be applied to a TEI document with Akita markers'"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:map>
               <!-- First build by hierarchy -->
               <xsl:for-each select="$akita-markers-by-hierarchy-parsed">
                  <xsl:variable name="these-specs" select="." as="element()"/>
                  <xsl:variable name="allowed-attribute-names" select="map:keys($akita:akita-pi-mark-tree-by-hierarchy-rules)"
                     as="xs:string+"/>
                  <xsl:variable name="tree-errors" as="element()*">
                     <xsl:for-each select="$these-specs/akita:attribute">
                        <xsl:variable name="this-attr" select="@name"/>
                        <xsl:variable name="this-attr-adjusted" select="replace($this-attr, '\d+', '1')" as="xs:string"/>
                        <xsl:variable name="this-attr-is-expected" select="$this-attr-adjusted = $allowed-attribute-names" as="xs:boolean"/>
                        <xsl:variable name="this-attr-val" as="xs:string" select="string(.)"/>
                        <xsl:variable name="this-expected-val-regex" as="xs:string?" select="$akita:akita-pi-mark-tree-by-hierarchy-rules($this-attr-adjusted)"/>
                        <xsl:choose>
                           <xsl:when test="not($this-attr-is-expected)">
                              <xsl:sequence
                                 select="akita:log-error('ak014', ($this-attr || ' unexpected; try: ' || string-join($allowed-attribute-names, ', ')))"
                              />
                              
                           </xsl:when>
                           <xsl:when test="not(matches($this-attr-val, '^' || $this-expected-val-regex || '$'))">
                              <xsl:sequence
                                 select="akita:log-error('ak016', ($this-attr || ' must entirely match the following regular expression: ' || $this-expected-val-regex))"
                              />
                              
                           </xsl:when>
                        </xsl:choose>
                     </xsl:for-each>
                  </xsl:variable>


                  <xsl:map-entry key="'h' || string(position())">
                     <xsl:apply-templates select="$tei-akita-file"
                        mode="akita:build-tei-wf-map-by-hierarchy">
                        <xsl:with-param name="tree-specs" as="element()" tunnel="yes" select="."/>
                        <xsl:with-param name="errors" as="element()*" tunnel="yes" select="$tree-errors"/>
                     </xsl:apply-templates>
                  </xsl:map-entry>
                  
               </xsl:for-each>
               
               <!-- Second, build by anchors -->
               <xsl:for-each select="$akita-markers-by-anchors-parsed">
                  <xsl:variable name="these-specs" select="." as="element()"/>
                  <xsl:variable name="allowed-attribute-names"
                     select="map:keys($akita:akita-pi-mark-tree-by-anchors-rules)" as="xs:string+"/>
                  
                  <xsl:variable name="tree-errors" as="element()*">
                     <xsl:for-each select="$these-specs/akita:attribute">
                        <xsl:variable name="this-attr" select="@name"/>
                        <xsl:variable name="this-attr-adjusted" select="replace($this-attr, '\d+', '1')" as="xs:string"/>
                        <xsl:variable name="this-attr-is-expected"
                           select="$this-attr-adjusted = $allowed-attribute-names" as="xs:boolean"/>
                        <xsl:variable name="this-attr-val" as="xs:string" select="string(.)"/>
                        <xsl:variable name="this-expected-val-regex" as="xs:string?"
                           select="$akita:akita-pi-mark-tree-by-anchors-rules($this-attr-adjusted)"/>
                        <xsl:choose>
                           <xsl:when test="not($this-attr-is-expected)">
                              <xsl:sequence
                                 select="akita:log-error('ak015', ($this-attr || ' unexpected; try: ' || string-join($allowed-attribute-names, ', ')))"/>

                           </xsl:when>
                           <xsl:when
                              test="not(matches($this-attr-val, '^' || $this-expected-val-regex || '$'))">
                              <xsl:sequence
                                 select="akita:log-error('ak016', ($this-attr || ' must entirely match the following regular expression: ' || $this-expected-val-regex))"/>

                           </xsl:when>
                        </xsl:choose>
                     </xsl:for-each>
                     
                     <xsl:for-each-group select="$these-specs/akita:attribute/@name[matches(., '\d+')]" group-by="replace(., '\d+', '1')">
                        <xsl:variable name="enumerated-sequence" select="
                              sort(for $i in current-group()
                              return
                                 xs:integer(replace($i, '\D+', '')))" as="xs:integer+"/>
                        <xsl:variable name="bad-items" select="
                              for $i in (1 to count($enumerated-sequence))
                              return
                                 if ($i eq $enumerated-sequence[$i]) then
                                    ()
                                 else
                                    $i" as="xs:integer*"/>
                        <xsl:if test="exists($bad-items)">
                           <xsl:sequence select="
                                 akita:log-error('ak017', 'Expected: ' || string-join(for $i in $bad-items
                                 return
                                    replace(current-grouping-key(), '1', string($i)), ', '))"
                           />
                        </xsl:if>
                     </xsl:for-each-group>
                  </xsl:variable>

                  <xsl:map-entry key="'a' || string(position())">
                     <xsl:apply-templates select="$tei-akita-file"
                        mode="akita:build-tei-wf-map-by-anchors">
                        <xsl:with-param name="tree-specs" as="element()" tunnel="yes" select="."/>
                        <xsl:with-param name="errors" as="element()*" tunnel="yes"
                           select="$tree-errors"/>
                     </xsl:apply-templates>
                  </xsl:map-entry>

               </xsl:for-each>
            </xsl:map>
         </xsl:otherwise>
      </xsl:choose>
      
   </xsl:function>
   
   <xsl:mode name="akita:build-tei-wf-map-by-hierarchy" on-no-match="shallow-copy"/>
   <xsl:mode name="akita:build-tei-wf-map-by-anchors" on-no-match="shallow-copy"/>
   
   <xsl:template match="/node()"
      mode="akita:build-tei-wf-map-by-hierarchy akita:build-tei-wf-map-by-anchors" priority="-1"/>
   
   <xsl:template match="/*" mode="akita:build-tei-wf-map-by-hierarchy">
      <xsl:param name="tree-specs" as="element()" tunnel="yes"/>
      <xsl:param name="errors" as="element()*" tunnel="yes"/>
      <xsl:variable name="idrefs" select="
            distinct-values(for $i in tokenize(normalize-space($tree-specs/akita:attribute[@name = 'idrefs']), ' ')
            return
               replace($i, '^#', ''))" as="xs:string*"/>
      <xsl:variable name="matching-targets" select=".//*[@xml:id = $idrefs]" as="element()*"/>
      <xsl:variable name="missing-idrefs" select="$idrefs[not(. = $matching-targets/@xml:id)]"/>
      
      <xsl:variable name="target-revised" as="element()*">
         <xsl:apply-templates select="$matching-targets" mode="#current"/>
      </xsl:variable>
      
      <xsl:variable name="all-text-unit-elements" select="$target-revised/descendant-or-self::*[@akita:ref]" as="element()*"/>
      
      <xsl:variable name="ref-sys-type" select="($tree-specs/*[@name = 'reference-system-type'])[1]" as="xs:string?"/>
      <xsl:variable name="logical-text-unit-elements" select="$all-text-unit-elements/(self::tei:p | self::tei:w)" as="element()*"/>
      <xsl:variable name="material-text-unit-elements" select="$all-text-unit-elements/(self::tei:lb | self::tei:pb | self::tei:cb)" as="element()*"/>
      
      
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$errors"/>
         <xsl:for-each select="$missing-idrefs">
            <xsl:sequence select="akita:log-error('ak010', .)"/>
         </xsl:for-each>
         <xsl:if test="$ref-sys-type = 'material' and exists($logical-text-unit-elements)">
            <xsl:sequence select="
                  akita:log-error('ak012', string-join(distinct-values(for $i in $logical-text-unit-elements
                  return
                     name($i)), ', ') || ' are logical units, not material.')"/>
         </xsl:if>
         <xsl:if test="$ref-sys-type = 'logical' and exists($material-text-unit-elements)">
            <xsl:sequence select="
                  akita:log-error('ak013', string-join(distinct-values(for $i in $material-text-unit-elements
                  return
                     name($i)), ', ') || ' are material units, not logical.')"/>
         </xsl:if>
         <xsl:element name="tree-specs" namespace="{$akita:akita-namespace}">
            <xsl:copy-of select="$tree-specs/*"/>
         </xsl:element>
         <xsl:element name="tree" namespace="{$akita:akita-namespace}">
            <xsl:copy-of select="$target-revised"/>
         </xsl:element>
      </xsl:copy>
   </xsl:template>
   
   <xsl:template match="*[@n]" mode="akita:build-tei-wf-map-by-hierarchy">
      <xsl:param name="inherited-ref" tunnel="yes" as="xs:string?"/>
      <xsl:variable name="n-norm" select="normalize-space(@n)"/>
      <xsl:variable name="is-anchor" select="not(matches(., '\S'))" as="xs:boolean"/>
      <xsl:variable name="is-unique-numbered-n" select="matches($n-norm, '^[1-9]\d*(\.\d+)?$')" as="xs:boolean"/>
      <xsl:choose>
         <xsl:when test="$is-anchor">
            <xsl:copy-of select="."/>
         </xsl:when>
         <xsl:when test="$is-unique-numbered-n">
            <xsl:variable name="new-ref" select="string-join(($inherited-ref, $n-norm), ':')"/>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="akita:ref" select="$new-ref"/>
               <xsl:apply-templates mode="#current">
                  <xsl:with-param name="inherited-ref" tunnel="yes" select="$new-ref"/>
               </xsl:apply-templates>
            </xsl:copy>
         </xsl:when>
      </xsl:choose>
   </xsl:template>
   
   
   
   <xsl:template match="/*" mode="akita:build-tei-wf-map-by-anchors">
      <xsl:param name="tree-specs" as="element()" tunnel="yes"/>
      <xsl:param name="errors" as="element()*" tunnel="yes"/>
      
      <xsl:variable name="level-attributes" select="$tree-specs/akita:attribute[starts-with(@name, 'level-')]" as="element()*"/>
      <xsl:variable name="unique-level-attributes" as="element()*">
         <xsl:for-each-group select="$level-attributes" group-by=".">
            <xsl:if test="count(current-group()) eq 1">
               <xsl:sequence select="current-group()"/>
            </xsl:if>
         </xsl:for-each-group> 
      </xsl:variable>
      
      <xsl:variable name="level-map" as="map(*)">
         <!-- This map is two-way, providing map entries to and from depth and anchor type -->
         <xsl:map>
            <xsl:if test="count($level-attributes) gt 0">
               <xsl:for-each select="1 to count($level-attributes)">
                  <xsl:variable name="this-pos" select="."/>
                  <xsl:variable name="this-spec" select="$unique-level-attributes[@name eq 'level-' || string($this-pos) || '-type']"/>
                  <xsl:map-entry key="position()" select="string($this-spec)"/>
                  <xsl:map-entry key="string($this-spec)" select="position()"/>
               </xsl:for-each>
            </xsl:if>
         </xsl:map>
      </xsl:variable>
      
      <xsl:variable name="level-anchors" select="
            distinct-values(for $i in $level-attributes
            return
               replace($i, '^#', ''))" as="xs:string*"/>
      <!-- Strangely, a TEI anchor may wrap a comment or white space or a pi, so the test has to check for no enclosing element or non-space text node -->
      <!-- We don't do the prepackaged TEI anchor nodes, in case someone has defined their own. -->
      <xsl:variable name="matching-targets"
         select=".//*[@type = $level-anchors][not(*) and not(text()[matches(., '\S')])]"
         as="element()*"/>
      <xsl:variable name="missing-anchors" select="$level-anchors[not(. = $matching-targets/@type)]"/>
      
      <xsl:variable name="tei-tree-to-sequence" as="element()">
         <!-- The strategy here is to flatten the entire tree into a sequence, paying special attention to the anchors, to make sure they
         are followed by memo elements that can be used to rebuild the hierarchies. -->
         <sequence>
            <xsl:apply-templates mode="akita:tei-tree-to-sequence">
               <xsl:with-param name="level-map" tunnel="yes" select="$level-map"/>
            </xsl:apply-templates>
         </sequence>
      </xsl:variable>
      
      <xsl:variable name="tei-new-tree-1" as="element()?">
         <xsl:iterate select="1 to count($level-attributes)">
            <xsl:param name="results-so-far" select="$tei-tree-to-sequence" as="element()"/>
            <xsl:on-completion>
               <xsl:sequence select="$results-so-far"/>
            </xsl:on-completion>
            <xsl:variable name="new-results" as="element()">
               <xsl:apply-templates select="$results-so-far" mode="akita:build-new-tree-1">
                  <xsl:with-param name="depth" select="string(.)" as="xs:string" tunnel="yes"/>
               </xsl:apply-templates>
            </xsl:variable>
            <xsl:next-iteration>
               <xsl:with-param name="results-so-far" as="element()" select="$new-results"/>
            </xsl:next-iteration>
         </xsl:iterate>
      </xsl:variable>
      
      <xsl:variable name="tei-new-tree-2" as="element()?">
         <xsl:apply-templates select="$tei-new-tree-1" mode="akita:build-new-tree-2"/>
      </xsl:variable>
      
      
      <xsl:variable name="all-text-unit-elements" select="$tei-new-tree-2//*[@akita:ref]"/>
      
      <xsl:variable name="ref-sys-type" select="($tree-specs/*[@name = 'reference-system-type'])[1]" as="xs:string?"/>
      <xsl:variable name="material-text-unit-elements" select="$all-text-unit-elements/(self::tei:lb | self::tei:pb | self::tei:cb)"/>
      
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:copy-of select="$errors"/>
         <xsl:for-each select="$missing-anchors">
            <xsl:sequence select="akita:log-error('ak011', .)"/>
         </xsl:for-each>
         <xsl:if test="$ref-sys-type = 'logical' and exists($material-text-unit-elements)">
            <xsl:sequence select="
                  akita:log-error('ak013', string-join(distinct-values(for $i in $material-text-unit-elements
                  return
                     name($i)), ', ') || ' are material units, not logical.')"/>
         </xsl:if>
         <xsl:element name="tree-specs" namespace="{$akita:akita-namespace}">
            <xsl:copy-of select="$tree-specs/*"/>
         </xsl:element>
         <xsl:element name="tree" namespace="{$akita:akita-namespace}">
            <!--<sequence><xsl:copy-of select="$tei-tree-to-sequence"/></sequence>-->
            <!--<tree-1><xsl:copy-of select="$tei-new-tree-1"/></tree-1>-->
            <!--<tree-2><xsl:copy-of select="$tei-new-tree-2"/></tree-2>-->
            <xsl:copy-of select="$tei-new-tree-2/*[@akita:ref]"/>
         </xsl:element>
      </xsl:copy>
   </xsl:template>
   
   
   
   <xsl:template match="text() | processing-instruction() | comment()" mode="akita:tei-tree-to-sequence">
      <xsl:copy-of select="."/>
   </xsl:template>
   <xsl:template match="*" mode="akita:tei-tree-to-sequence">
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:attribute name="_level" select="count(ancestor::*) + 1"/>
      </xsl:copy>
      <xsl:apply-templates mode="#current"/>
   </xsl:template>
   <xsl:template match="*[@type][not(*)]" mode="akita:tei-tree-to-sequence" priority="1">
      <xsl:param name="level-map" tunnel="yes" as="map(*)"/>
      <xsl:variable name="this-type" select="@type"/>
      <xsl:variable name="this-depth" select="$level-map($this-type)" as="xs:integer?"/>
      <xsl:choose>
         <xsl:when test="$this-depth gt 0">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="_level" select="count(ancestor::*) + 1"/>
               <xsl:attribute name="_level_up" select="$this-depth"/>
            </xsl:copy>
            <xsl:for-each select="ancestor::*">
               <xsl:copy>
                  <xsl:copy-of select="@*"/>
                  <xsl:attribute name="_level" select="count(ancestor::*) + 1"/>
                  <xsl:attribute name="_rebuilt"/>
               </xsl:copy>
            </xsl:for-each>
            <xsl:apply-templates mode="#current"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:attribute name="_level" select="count(ancestor::*) + 1"/>
            </xsl:copy>
            <xsl:apply-templates mode="#current"/>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   
   
   <xsl:mode name="akita:build-new-tree-1" on-no-match="shallow-copy"/>
   <xsl:mode name="akita:build-new-tree-2" on-no-match="shallow-copy"/>
   <xsl:mode name="akita:build-new-tree-2b" on-no-match="shallow-copy"/>
   
   <xsl:template match="*" mode="akita:build-new-tree-1">
      <xsl:param name="depth" tunnel="yes" as="xs:string"/>
      <xsl:variable name="children-to-process" select="*[@_level_up eq $depth]" as="element()*"/>
      <xsl:choose>
         <xsl:when test="exists($children-to-process)">
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:for-each-group select="node()" group-starting-with="*[@_level_up eq $depth]">
                  <xsl:variable name="matching-head" select="current-group()[1][@_level_up eq $depth]" as="element()?"/>
                  <xsl:for-each select="$matching-head">
                     <xsl:copy>
                        <xsl:copy-of select="@* except @_level"/>
                        <xsl:copy-of select="tail(current-group())"/>
                     </xsl:copy>
                  </xsl:for-each>
                  <xsl:if test="not(exists($matching-head))">
                     <xsl:copy-of select="current-group()"/>
                  </xsl:if>
               </xsl:for-each-group> 
            </xsl:copy>
            
         </xsl:when>
         <xsl:otherwise>
            <xsl:copy>
               <xsl:copy-of select="@*"/>
               <xsl:apply-templates mode="#current"/>
            </xsl:copy>
         </xsl:otherwise>
      </xsl:choose>
   </xsl:template>
   
   <xsl:template match="*[@_level_up]" mode="akita:build-new-tree-2">
      <xsl:param name="inherited-ref" tunnel="yes" as="xs:string?"/>
      <xsl:variable name="n-norm" select="normalize-space(@n)" as="xs:string"/>
      <xsl:variable name="is-unique-numbered-n" select="matches($n-norm, '^[1-9]\d*(\.\d+)?$')" as="xs:boolean"/>
      <xsl:variable name="new-ref" select="string-join(($inherited-ref, $n-norm), ':')"/>
      
      <!-- retain the material only if @n is an integer or an integer-modified integer -->
      <xsl:if test="$is-unique-numbered-n">
         
         <xsl:copy>
            <xsl:copy-of select="@* except @_level_up"/>
            <xsl:attribute name="akita:ref" select="$new-ref"/>
            
            <xsl:for-each-group select="node()" group-starting-with="*[@_level_up]">
               <xsl:variable name="converted-anchor" select="current-group()[@_level_up]" as="element()?"/>
               <xsl:variable name="anchor-content" as="item()*"
                  select="current-group() except $converted-anchor"/>
               <xsl:variable name="non-rebuilt-nodes" select="$anchor-content[not(@_rebuilt)]" as="item()*"/>
               
               <xsl:apply-templates select="$converted-anchor" mode="#current">
                  <xsl:with-param name="inherited-ref" tunnel="yes" select="$new-ref"/>
               </xsl:apply-templates>
               
               <xsl:if test="exists($non-rebuilt-nodes)">
                  <xsl:variable name="these-levels" select="
                        for $i in $anchor-content/@_level
                        return
                           xs:integer($i)" as="xs:integer*"/>
                  <xsl:variable name="max-level" as="xs:integer?" select="max($these-levels)"/>
                  
                  <xsl:choose>
                     <xsl:when test="exists($max-level)">
                        
                        <xsl:variable name="wrapped-anchor-content" as="element()">
                           <content>
                              <xsl:copy-of select="$anchor-content"/>
                           </content>
                        </xsl:variable>
                        
                        <xsl:iterate select="1 to $max-level">
                           <xsl:param name="results-so-far" as="element()" select="$wrapped-anchor-content"/>
                           <xsl:on-completion>
                              <xsl:sequence select="$results-so-far/node()"/>
                           </xsl:on-completion>
                           <xsl:variable name="new-results" as="element()">
                              <xsl:apply-templates select="$results-so-far" mode="akita:build-new-tree-2b">
                                 <xsl:with-param name="level" tunnel="yes" select="xs:string(.)"/>
                              </xsl:apply-templates>
                           </xsl:variable>
                           <xsl:next-iteration>
                              <xsl:with-param name="results-so-far" select="$new-results"/>
                           </xsl:next-iteration>
                        </xsl:iterate>
                        
                     </xsl:when>
                     <xsl:otherwise>
                        <xsl:copy-of select="$non-rebuilt-nodes"/>
                     </xsl:otherwise>
                  </xsl:choose>
                  
               </xsl:if>
               
            </xsl:for-each-group> 
            
         </xsl:copy>
         
      </xsl:if>
   </xsl:template>
   
   <xsl:template match="*[*[@_level]]" mode="akita:build-new-tree-2b">
      <xsl:param name="level" tunnel="yes" as="xs:string"/>
      <xsl:copy>
         <xsl:copy-of select="@*"/>
         <xsl:for-each-group select="node()" group-starting-with="*[@_level = $level]">
            <xsl:variable name="group-head" select="current-group()[1][@_level = $level]" as="element()?"/>
            <xsl:for-each select="$group-head">
               <xsl:copy>
                  <xsl:copy-of select="@* except (@_level | @_rebuilt)"/>
                  <xsl:copy-of select="tail(current-group())"/>
               </xsl:copy>
            </xsl:for-each>
            <xsl:if test="not(exists($group-head))">
               <xsl:copy-of select="current-group()"/>
            </xsl:if>
         </xsl:for-each-group> 
      </xsl:copy>
   </xsl:template>
   
   
   <xsl:function name="akita:map-to-string" as="xs:string?" visibility="private">
      <!-- Input: a map -->
      <!-- Output: a string representation of the map -->
      <!-- This process is not reversible. It was written to get maps into a string for reporting in an error message. -->
      <xsl:param name="input-map" as="map(*)"/>
      <xsl:variable name="map-keys" select="map:keys($input-map)"/>
      <xsl:variable name="output-parts" as="xs:string+">
         <xsl:text>[map </xsl:text>
         <xsl:for-each select="$map-keys">
            <xsl:sort select="."/>
            <xsl:variable name="this-key" select="."/>
            <xsl:variable name="this-entry" select="$input-map($this-key)"/>
            <xsl:value-of select="'[' || $this-key || ' '"/>
            <xsl:choose>
               <xsl:when test="not($this-entry instance of map(*))">
                  <xsl:sequence select="serialize($this-entry)"></xsl:sequence>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="akita:map-to-string($this-entry)"/>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:text>]</xsl:text>
         </xsl:for-each>
         <xsl:text>]</xsl:text>
      </xsl:variable>
      <xsl:sequence select="string-join($output-parts)"/>
   </xsl:function>
   <xsl:function name="akita:map-to-xml" as="item()*" visibility="private">
      <!-- Input: a map -->
      <!-- Output: a string representation of the map -->
      <!-- This process is not reversible. It was written to get maps into a string for reporting in an error message. -->
      <xsl:param name="input-map" as="map(*)"/>
      <xsl:variable name="map-keys" select="map:keys($input-map)"/>
      <map>
         <xsl:for-each select="$map-keys">
            <xsl:sort select="."/>
            <xsl:variable name="this-key" select="."/>
            <xsl:variable name="this-entry" select="$input-map($this-key)"/>
            <entry key="{$this-key}">
               <xsl:choose>
                  <xsl:when test="not($this-entry instance of map(*))">
                     <xsl:sequence select="$this-entry"/>
                  </xsl:when>
                  <xsl:otherwise>
                     <xsl:sequence select="akita:map-to-string($this-entry)"/>
                  </xsl:otherwise>
               </xsl:choose>
            </entry>
         </xsl:for-each>
      </map>
      
   </xsl:function>
   
</xsl:stylesheet>