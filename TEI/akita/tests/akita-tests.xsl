<xsl:stylesheet  xmlns:akita="tag:kalvesmaki.com,2020:ns" 
   xmlns:xsl="http://www.w3.org/1999/XSL/Transform" 
   xmlns:xs="http://www.w3.org/2001/XMLSchema"
   xmlns:tei="http://www.tei-c.org/ns/1.0"
   version="3.0">
   <!-- Tests for Akita functions -->
   <!-- Catalyzing input: any XML document, including this one -->
   <!-- Secondary input: perhaps invoked explicitly by some of the tests -->
   <!-- Primary output: diagnostics -->
   <!-- Secondary output: none -->
   
   <xsl:include href="../functions/akita-core.xsl"/>
   
   <xsl:output indent="yes"/>
   
   <xsl:variable name="doc-1-uri" select="'../examples/tei%20akita%20example.xml'" as="xs:string"/>
   <xsl:variable name="doc-1-vocab" as="document-node()?" select="akita:resolve-vocabulary(doc($doc-1-uri))"/>
   <xsl:variable name="doc-1-vocab-validated" as="document-node()?" select="akita:validate-vocabulary($doc-1-vocab)"/>
   <xsl:variable name="pi-1-value" as="xs:string">
      idrefs="#d1" 
      work="art-of-war" 
      scriptum="suntzu-2002"
      reference-scriptum="suntzu-2002"
      reference-system-type="logical"</xsl:variable>
   <xsl:variable name="attr-parsed" select="akita:parse-attributes($pi-1-value)"/>
   
   <xsl:variable name="doc-1-wf-map" as="map(*)" select="akita:build-tei-wf-map(doc($doc-1-uri))"/>
   
   <xsl:template match="/">
      <diagnostics>
         <doc-1-vocab><xsl:copy-of select="$doc-1-vocab"/></doc-1-vocab>
         <!--<doc-1-vocab-validated><xsl:copy-of select="$doc-1-vocab-validated"/></doc-1-vocab-validated>-->
         <!--<attr-parsed><xsl:copy-of select="$attr-parsed"/></attr-parsed>-->
         <doc-1-wf-map><xsl:copy-of select="akita:map-to-xml($doc-1-wf-map)"/></doc-1-wf-map>
      </diagnostics>
   </xsl:template>
   
</xsl:stylesheet>