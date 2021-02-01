<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns="tag:kalvesmaki.com,2020:ns" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
   xmlns:xs="http://www.w3.org/2001/XMLSchema" xmlns:wf="tag:kalvesmaki.com,2020:ns"
   xmlns:map="http://www.w3.org/2005/xpath-functions/map"
   xmlns:array="http://www.w3.org/2005/xpath-functions/array"
   exclude-result-prefixes="#all"
   version="3.0">
   
   <!-- This XSLT file is intended solely as a function library to test conformance to the specifications
   for Writing Fragids. Any XSLT application may use the library simply by including or importing it. -->
   
   <!-- This version of the WF functions is an early one, and as a result, all functions and variables are 
      bound to a provisional, temporary namespace, tag:kalvesmaki.com,2020:ns. That namespace will change 
      when WF specifications are officially released. -->
   <xsl:variable name="wf:function-library-version" as="xs:string">0.001</xsl:variable>
   
   <xsl:variable name="wf:wf-namespace-uri" select="'tag:kalvesmaki.com,2020:ns'" as="xs:string"/>
   

   <xsl:function name="wf:is-valid-wf-uri" as="xs:boolean" visibility="public">
      <!-- Input: a string -->
      <!-- Output: a boolean specifying whether the input string is a valid Writing Fragid URI -->

      <xsl:param name="wf-uri" as="xs:string?"/>

      <xsl:variable name="wf-uri-parsed" as="map(*)" select="wf:parse-wf-uri($wf-uri)"/>
      <xsl:variable name="wf-uri-errors" as="element()*" select="$wf-uri-parsed('errors')"/>
      
      <xsl:choose>
         <xsl:when test="string-length($wf-uri) lt 1">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:when test="count($wf-uri-errors) gt 0">
            <xsl:sequence select="false()"/>
         </xsl:when>
         <xsl:otherwise>
            <xsl:sequence select="true()"/>
         </xsl:otherwise>
      </xsl:choose>

   </xsl:function>

   <xsl:variable name="wf:wf-uri-component-sequence" as="xs:string+"
      select="'base-uri', 'fragment-start', 'wf-fragment', 'fragment-end', 'wf-fragment-count',
      'wf-version', 'wf-uri-type', 'wf-work-constraint-uri', 'wf-ref-system-type', 'wf-ref-scriptum-uri', 
      'wf-references', 'errors'"/>

   <xsl:function name="wf:parse-wf-uri" as="map(*)" visibility="public">
      <!-- One-parameter version of compelete one below -->
      <!-- By default, errors are reported in the map, but not by message. Messages can be turned on in the 2-parameter version. -->
      <xsl:param name="wf-uri" as="xs:string?"/>
      <xsl:sequence select="wf:parse-wf-uri($wf-uri, false())"/>
   </xsl:function>
   
   <xsl:function name="wf:parse-wf-uri" as="map(*)" visibility="public">
      <!-- Input: a string -->
      <!-- Output: the parts of the string parsed into WF URI components, returned as a map -->
      <!-- The URI is assumed to have been put in canonical form. That is, if a WF URI appears in a 
         context where embedded whitespace wrapping angle brackets have been introduced for legibility,
         such wrappers or insertions must be removed before applying this function. -->
      <!-- The output includes a map entry for errors, but there is no guarantee that all errors will 
         be detected in this process. -->
      
      <xsl:param name="wf-uri" as="xs:string?"/>
      <xsl:param name="errors-via-message" as="xs:boolean"/>

      <!-- A valid WF URI consists of exactly one #. What precedes is the base URI; what follows
      is the fragment. The WF should be inside the fragment somewhere -->
      <xsl:variable name="wf-uri-parts" as="xs:string*" select="tokenize($wf-uri, '#')"/>

      <xsl:variable name="wf-base-uri" select="$wf-uri-parts[1]" as="xs:string?"/>
      <xsl:variable name="wf-uri-fragments" as="element()">
         <fragment>
            <!-- Reluctant capture applied to the WF, to make sure it terminates with the first unescaped $ -->
            <xsl:analyze-string select="$wf-uri-parts[2]" regex="\$wf\d+:.+?[^^]\$">
               <xsl:matching-substring>
                  <wf>
                     <xsl:value-of select="."/>
                  </wf>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <extra>
                     <xsl:value-of select="."/>
                  </extra>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </fragment>
      </xsl:variable>
      <xsl:variable name="wf-fragment" select="$wf-uri-fragments/wf:wf[1]" as="element()?"/>
      
      <!-- Step 1: analyze the WF for its parameters -->
      <xsl:variable name="wf-fragment-parameters-parsed" as="element()">
         <wf>
            <xsl:analyze-string select="$wf-fragment" regex="^\$wf(\d+):|\$$" flags="i">
               <!-- Trim the opening and closing strings, retaining the WF version number -->
               <xsl:matching-substring>
                  <xsl:if test="string-length(regex-group(1)) gt 0">
                     <version>
                        <xsl:value-of select="regex-group(1)"/>
                     </version>
                  </xsl:if>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:analyze-string select="." regex="^a=([ws]);" flags="i">
                     <xsl:matching-substring>
                        <base-uri-type>
                           <xsl:value-of select="lower-case(regex-group(1))"/>
                        </base-uri-type>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <xsl:analyze-string select="." regex="^w=(.+?[^^]);" flags="i">
                           <xsl:matching-substring>
                              <work-constraint-uri>
                                 <xsl:value-of select="wf:unescape-wf-frag-uri(regex-group(1))"/>
                              </work-constraint-uri>
                           </xsl:matching-substring>
                           <xsl:non-matching-substring>
                              <xsl:analyze-string select="." regex="^t=([ml]);" flags="i">
                                 <xsl:matching-substring>
                                    <ref-system-type>
                                       <xsl:value-of select="lower-case(regex-group(1))"/>
                                    </ref-system-type>
                                 </xsl:matching-substring>
                                 <xsl:non-matching-substring>
                                    <xsl:analyze-string select="." regex="^r=(.*?[^^]);">
                                       <xsl:matching-substring>
                                          <ref-scriptum-uri>
                                             <xsl:value-of
                                                select="wf:unescape-wf-frag-uri(regex-group(1))"/>
                                          </ref-scriptum-uri>
                                       </xsl:matching-substring>
                                       <xsl:non-matching-substring>
                                          <references>
                                             <xsl:analyze-string select="." regex="(.+?[^^])&amp;">
                                                <xsl:matching-substring>
                                                  <reference>
                                                  <xsl:value-of select="regex-group(1)"/>
                                                  </reference>
                                                </xsl:matching-substring>
                                                <xsl:non-matching-substring>
                                                  <reference>
                                                  <xsl:value-of select="."/>
                                                  </reference>
                                                </xsl:non-matching-substring>
                                             </xsl:analyze-string>
                                          </references>
                                       </xsl:non-matching-substring>
                                    </xsl:analyze-string>
                                 </xsl:non-matching-substring>
                              </xsl:analyze-string>
                           </xsl:non-matching-substring>
                        </xsl:analyze-string>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </wf>
      </xsl:variable>
      <xsl:variable name="wf-uri-type" as="xs:string?">
         <xsl:choose>
            <xsl:when
               test="$wf-fragment-parameters-parsed/wf:base-uri-type eq 's' and exists($wf-fragment-parameters-parsed/wf:work-constraint-uri/text())"
               >constrained scriptum</xsl:when>
            <xsl:when test="$wf-fragment-parameters-parsed/wf:base-uri-type eq 's'"
               >scriptum</xsl:when>
            <xsl:when test="$wf-fragment-parameters-parsed/wf:base-uri-type eq 'w'">work</xsl:when>
         </xsl:choose>
      </xsl:variable>
      <xsl:variable name="wf-uri-fragment-count" as="xs:integer" select="count($wf-uri-fragments/wf:wf)"/>
      <xsl:variable name="wf-ref-scriptum-uri" as="xs:string" select="string($wf-fragment-parameters-parsed/wf:ref-scriptum-uri)"/>
      
      <!-- Step 2: parse the references. Unlike the above, which relies upon string analysis, this
         process uses templates. -->
      <xsl:variable name="wf-fragment-references-parsed" as="map(*)">
         <xsl:map>
            <xsl:apply-templates select="$wf-fragment-parameters-parsed" mode="parse-wf-references"
            />
         </xsl:map>
      </xsl:variable>
      
      <xsl:variable name="unparsed-text" select="map:find($wf-fragment-references-parsed, 'unparsed-text')" as="array(*)"/>
      
      
      
      <xsl:variable name="wf-uri-errors" as="element()*">
         <xsl:if test="string-length($wf-base-uri) lt 1">
            <xsl:sequence select="wf:report-error('wf001', 'Base URI is ' || $wf-base-uri)"/>
         </xsl:if>
         <xsl:if test="$wf-uri-fragment-count ne 1">
            <xsl:sequence select="wf:report-error('wf002', 'There are ' || string($wf-uri-fragment-count) || ' WF URI fragments.')"/>
         </xsl:if>
         <xsl:if test="string-length($wf-uri-type) lt 1">
            <xsl:sequence select="wf:report-error('wf003', '')"/>
         </xsl:if>
         <xsl:if test="string-length($wf-fragment-parameters-parsed/wf:ref-system-type) lt 1">
            <xsl:sequence select="wf:report-error('wf004', '')"/>
         </xsl:if>
         <xsl:if test="count($wf-uri-parts) gt 2">
            <xsl:sequence select="wf:report-error('wf005', 'Unexpected # fragment markers should be percent escaped: %23' || string-join($wf-uri-parts[position() gt 2], '%23'))"/>
         </xsl:if>
         <xsl:if test="array:size($unparsed-text) gt 0">
            <xsl:variable name="extra-help" as="xs:string*">
               <xsl:if test="matches($wf-fragment, '\d\.\d+\.')"> Fragment may be using periods
                  instead of colons to separate reference steps.</xsl:if>
               <xsl:if test="matches($wf-fragment, '[^\]]\$')"> A text fragment may be lacking an
                  instance filter. </xsl:if>
            </xsl:variable>
            
            <xsl:sequence
               select="wf:report-error('wf006', 'Unparsed text exists: ' || string-join(array:flatten($unparsed-text), ' ') || ' ' || normalize-space(string-join($extra-help, ' ')))"
            />
         </xsl:if>
         <xsl:for-each select="map:keys($wf-fragment-references-parsed)[. instance of xs:integer]">
            <xsl:variable name="this-key" select="." as="xs:integer"/>
            <xsl:variable name="this-map" select="$wf-fragment-references-parsed($this-key)" as="map(*)?"/>
            <xsl:for-each select="map:keys($this-map)[. instance of xs:integer]">
               <xsl:variable name="this-key2" select="." as="xs:integer"/>
               <xsl:variable name="this-map2" select="$this-map($this-key)" as="map(*)?"/>
               <xsl:variable name="this-map2-keys" select="
                     if (exists($this-map2)) then
                        map:keys($this-map2)
                     else
                        ()" as="xs:string*"/>
               
               <xsl:variable name="this-token" select="
                     if ($this-map2-keys = 'token') then
                        $this-map2('token')
                     else
                        ()" as="xs:string?"/>
               <xsl:variable name="this-token-length" select="string-length($this-token)" as="xs:integer"/>
               <xsl:variable name="this-from-char" select="
                     if ($this-map2-keys = 'from-char') then
                        $this-map2('from-char')
                     else
                        ()" as="xs:integer?"/>
               <xsl:variable name="this-through-char" select="
                     if ($this-map2-keys = 'through-char') then
                        $this-map2('through-char')
                     else
                        ()" as="xs:integer?"/>
               <xsl:if test="$this-from-char gt 0 and $this-through-char gt 0 and $this-through-char le $this-from-char">
                  <xsl:sequence
                     select="wf:report-error('wf007', string($this-through-char) || ' is not greater than ' || string($this-from-char))"
                  />
               </xsl:if>
               <xsl:if test="$this-from-char gt $this-token-length or $this-through-char gt $this-token-length">
                  <xsl:sequence
                     select="wf:report-error('wf008', $this-token || ' has length ' || string($this-token-length))"
                  />
                  
               </xsl:if>
            </xsl:for-each>
         </xsl:for-each>
      </xsl:variable>

      <xsl:map>
         <!-- All URI components -->
         <xsl:map-entry key="'base-uri'" select="$wf-base-uri"/>
         <xsl:map-entry key="'fragment-start'"
            select="string-join($wf-fragment/preceding-sibling::*)"/>
         <!-- The pre-parsed WF itsewf is isolated, in case it needs to be used elsewhere -->
         <xsl:map-entry key="'wf-fragment'" select="string($wf-fragment)"/>
         <xsl:map-entry key="'fragment-end'" select="string-join($wf-fragment/following-sibling::*)"
         />
         <xsl:map-entry key="'wf-fragment-count'" select="$wf-uri-fragment-count"/>
         
         <!-- WF components: parameters -->
         <!--  -->
         <xsl:map-entry key="'wf-version'" select="string($wf-fragment-parameters-parsed/wf:version)"/>
         <xsl:map-entry key="'wf-uri-type'" select="$wf-uri-type"/>
         <xsl:map-entry key="'wf-work-constraint-uri'" select="string($wf-fragment-parameters-parsed/wf:work-constraint-uri)"/>
         <xsl:map-entry key="'wf-ref-system-type'" select="string($wf-fragment-parameters-parsed/wf:ref-system-type)"/>
         <xsl:map-entry key="'wf-ref-scriptum-uri'" select="
               if ($wf-ref-scriptum-uri = '.') then
                  $wf-base-uri
               else
                  $wf-ref-scriptum-uri"/>
         
         <!-- WF components: references -->
         <xsl:map-entry key="'wf-references'" select="$wf-fragment-references-parsed"/>
         
         <!-- WF URI error handling -->
         <xsl:map-entry key="'errors'">
            <!-- Items will be elements, perhaps with messages, if the 2nd parameter so specifies. -->
            <xsl:copy-of select="$wf-uri-errors"/>
         </xsl:map-entry>
      </xsl:map>
      
      <xsl:if test="$errors-via-message">
         <xsl:for-each select="$wf-uri-errors">
            <xsl:sequence
               select="error(QName($wf:wf-namespace-uri, wf:code), wf:definition, wf:message)"/>
         </xsl:for-each>
      </xsl:if>

   </xsl:function>

   <xsl:mode name="parse-wf-references" on-no-match="shallow-skip"/>

   <xsl:template match="wf:reference" mode="parse-wf-references">
      <!-- In a reference, a hyphen signifies a range of two references. -->
      <xsl:variable name="reference-parts" as="element()">
         <parts>
            <!-- Before looking for ranges, we remove the possibility that a hyphen will catch 
            a character filter range. -->
            <xsl:analyze-string select="." regex="\[\d+-\d+\]">
               <xsl:matching-substring>
                  <part>
                     <xsl:value-of select="."/>
                  </part>
               </xsl:matching-substring>
               <xsl:non-matching-substring>
                  <xsl:analyze-string select="." regex="([^^])-|^-">
                     <xsl:matching-substring>
                        <a>
                           <xsl:value-of select="regex-group(1)"/>
                        </a>
                     </xsl:matching-substring>
                     <xsl:non-matching-substring>
                        <part>
                           <xsl:value-of select="."/>
                        </part>
                     </xsl:non-matching-substring>
                  </xsl:analyze-string>
               </xsl:non-matching-substring>
            </xsl:analyze-string>
         </parts>
      </xsl:variable>
      <xsl:variable name="reference-is-range" as="xs:boolean"
         select="exists($reference-parts/wf:a)"/>
      <xsl:variable name="ref-parts" as="xs:string*">
         <xsl:for-each-group select="$reference-parts" group-starting-with="wf:part">
            <xsl:value-of select="string-join(current-group())"/>
         </xsl:for-each-group>
      </xsl:variable>
      <xsl:map-entry key="position()">
         <!-- No reference may have both an unescaped hyphen (a range) and an unescaped + (a fusion). In 
            such cases, the error will be registered because both <range> and <fusion> are present, but
            the tree will be constructed on the basis of the range, not the fusion.
         -->
         <xsl:map>
            <xsl:map-entry key="'is-range'" select="$reference-is-range"/>
            <xsl:for-each select="$ref-parts">
               <xsl:map-entry key="position()">
                  <xsl:map>
                     <xsl:analyze-string select="." regex="^(n?[1-9]\d*(\.[1-9]\d*)?)(:n?[1-9]\d*(\.[1-9]\d*)?)*">
                        <xsl:matching-substring>
                           <xsl:map-entry key="'steps'" select="tokenize(., ':')"/>
                        </xsl:matching-substring>
                        <xsl:non-matching-substring>
                           <!-- Look for two colons, followed by at least one letter, then the sequence firster and perhaps the
                           second, character filter -->
                           <xsl:analyze-string select="." regex="^::(.*?[^^])(\[[1-9]\d*\])(\[[1-9]\d*(-[1-9]\d*)?\])?">
                              <xsl:matching-substring>
                                 <xsl:variable name="character-picks" select="
                                       for $i in tokenize(regex-group(3), '-')
                                       return
                                          xs:integer(replace($i, '\D+', ''))"
                                 />
                                 <xsl:map-entry key="'token'"
                                    select="wf:unescape-wf-frag-text(regex-group(1))"/>
                                 <xsl:map-entry key="'instance'"
                                    select="xs:integer(replace(regex-group(2), '\D+', ''))"/>
                                 <xsl:if test="string-length(regex-group(3)) gt 0">
                                    <xsl:map-entry key="'from-char'" select="$character-picks[1]"/>
                                    <xsl:map-entry key="'through-char'" select="$character-picks[2]"/>
                                 </xsl:if>
                              </xsl:matching-substring>
                              <xsl:non-matching-substring>
                                 <xsl:map-entry key="'unparsed-text'" select="."/>
                              </xsl:non-matching-substring>
                           </xsl:analyze-string>
                        </xsl:non-matching-substring>
                     </xsl:analyze-string>
                  </xsl:map>
   
               </xsl:map-entry>
            </xsl:for-each>
         </xsl:map>
      </xsl:map-entry>
   </xsl:template>

   <xsl:function name="wf:unescape-wf-frag-uri" as="xs:string?" visibility="private">
      <!-- Input: a portion of a WF that corresponds to a URI -->
      <!-- Output: the URI with escaped characters unescaped -->
      <!-- Private function, to support WF URI parsing -->
      <xsl:param name="wf-parameter-value" as="xs:string"/>
      <xsl:variable name="wf-param-parts" as="xs:string+">
         <xsl:analyze-string select="$wf-parameter-value" regex="\^([\$\^;])">
            <xsl:matching-substring>
               <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:analyze-string select="." regex="%23">
                  <xsl:matching-substring>#</xsl:matching-substring>
                  <xsl:non-matching-substring>
                     <xsl:value-of select="."/>
                  </xsl:non-matching-substring>
               </xsl:analyze-string>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:sequence select="string-join($wf-param-parts)"/>
   </xsl:function>

   <xsl:function name="wf:unescape-wf-frag-text" as="xs:string?" visibility="private">
      <!-- Input: a portion of a WF that corresponds to a text fragment -->
      <!-- Output: the fragment with escaped characters unescaped -->
      <!-- Private function, to support WF URI parsing -->
      <xsl:param name="wf-reference-text" as="xs:string"/>
      <xsl:variable name="wf-reference-text-parts" as="xs:string+">
         <xsl:analyze-string select="$wf-reference-text" regex="\^([\$\^\[:\+-])">
            <xsl:matching-substring>
               <xsl:value-of select="regex-group(1)"/>
            </xsl:matching-substring>
            <xsl:non-matching-substring>
               <xsl:value-of select="."/>
            </xsl:non-matching-substring>
         </xsl:analyze-string>
      </xsl:variable>
      <xsl:sequence select="string-join($wf-reference-text-parts)"/>
   </xsl:function>
   
   
   
   <xsl:variable name="wf:error-map" as="map(*)">
      <xsl:map>
         <xsl:map-entry key="'wf001'" select="'A base uri is required.'"/>
         <xsl:map-entry key="'wf002'" select="'A WF URI must have exactly one WF.'"/>
         <xsl:map-entry key="'wf003'" select="'A WF URI type must be work, scriptum, or constrained scriptum.'"/>
         <xsl:map-entry key="'wf004'" select="'A WF URI reference system type must be material or logical.'"/>
         <xsl:map-entry key="'wf005'" select="'The # may be used only once in a WF URI.'"/>
         <xsl:map-entry key="'wf006'" select="'All text in a WF URI must be parsed.'"/>
         <xsl:map-entry key="'wf007'" select="'A character range must terminate in an integer larger than the first.'"/>
         <xsl:map-entry key="'wf008'" select="'A character range must not exceed the length of the token.'"/>
         
      </xsl:map>
   </xsl:variable>
   
   <!-- [map [base-uri http://dbpedia.org/resource/Iliad][fragment-start ]
      [wf-fragment $wf0:a=w;t=l;r=http://www.worldcat.org/oclc/968653045;1:1$]
      [fragment-end ][wf-fragment-count 1][wf-version 0][wf-uri-type work][wf-work-constraint-uri ][wf-ref-system-type l][wf-ref-scriptum-uri http://www.worldcat.org/oclc/968653045][wf-references [map [1 [map [1 [map [steps 1 1]]][is-fusion false][is-range false]]]]][errors ]] -->
   
   <xsl:function name="wf:report-error" as="element()?" visibility="private">
      <!-- Input: a string corresponding to an error code; a string; a boolean -->
      <!-- Output: an element that wraps the error code, its standard message, and any contextual 
      comments (the 2nd parameter). If the third parameter is true, then the same message is returned
      as a message error. -->
      <xsl:param name="error-code" as="xs:string"/>
      <xsl:param name="message" as="xs:string?"/>
      
      <xsl:variable name="this-error-definition" select="$wf:error-map($error-code)"/>
      <xsl:if test="exists($this-error-definition)">
         <error>
            <code>
               <xsl:value-of select="$error-code"/>
            </code>
            <definition>
               <xsl:value-of select="$this-error-definition"/>
            </definition>
            <message>
               <xsl:value-of select="$message"/>
            </message>
         </error>
      </xsl:if>
      
   </xsl:function>
   
   <xsl:function name="wf:map-to-string" as="xs:string?" visibility="private">
      <!-- Input: a map -->
      <!-- Output: a string representation of the map -->
      <!-- This process is not reversible. It was written to get maps into a string for reporting in an error message. -->
      <xsl:param name="input-map" as="map(*)"/>
      <xsl:variable name="map-keys" select="map:keys($input-map)"/>
      <xsl:variable name="output-parts" as="xs:string+">
         <xsl:text>[map </xsl:text>
         <xsl:for-each select="$map-keys">
            <xsl:sort select="(index-of($wf:wf-uri-component-sequence, .), 9999)[1]"/>
            <xsl:variable name="this-key" select="."/>
            <xsl:variable name="this-entry" select="$input-map($this-key)"/>
            <xsl:value-of select="'[' || $this-key || ' '"/>
            <xsl:choose>
               <xsl:when test="not($this-entry instance of map(*))">
                  <xsl:sequence select="serialize($this-entry)"></xsl:sequence>
               </xsl:when>
               <xsl:otherwise>
                  <xsl:sequence select="wf:map-to-string($this-entry)"/>
               </xsl:otherwise>
            </xsl:choose>
            <xsl:text>]</xsl:text>
         </xsl:for-each>
         <xsl:text>]</xsl:text>
      </xsl:variable>
      <xsl:sequence select="string-join($output-parts)"/>
   </xsl:function>
   


</xsl:stylesheet>
