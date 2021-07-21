<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:redact="http://noslogan.org/semaphore/redact"
    xmlns:map="http://marklogic.com/xdmp/map"
    xmlns:xdmp="http://marklogic.com/xdmp"
    xmlns:mps="http://medicalprotection.org/ns/mps"
    xmlns:html="http://www.w3.org/1999/xhtml"
    xmlns="http://www.w3.org/1999/xhtml"
    xdmp:dialect="1.0-ml"
    exclude-result-prefixes="xs redact xdmp map mps"
    version="2.0">

    <!-- Redaction processor. This should always be called from the wrapper
    XQuery function so that they parameters below are set up correctly.
    -->

    <xsl:output method="xml"/>

    <!-- MarkLogic map of the facts to use as the redaction data -->
    <xsl:param name="redact:facts" as="map:map"/>

    <!-- Function which takes a KEY elements as a parameter and returns a boolean.
    If the result is true they content is retained -->
    <xsl:param name="redact:keeper" as="function(element(KEY)) as xs:boolean"/>

    <!--  we *never* want these redacted -->
    <xsl:template match="KEY[$redact:keeper(.)]" priority="2">
        <xsl:copy>
            <xsl:apply-templates select=".//text()[normalize-space(.)]"/>
        </xsl:copy>
    </xsl:template>

    <!-- process KEY elements to redact the content -->
    <xsl:template match="KEY[exists(map:get($redact:facts, @ID))]">

        <xsl:variable name="fact" select="map:get($redact:facts, @ID)[1]" as="map:map?"/>
        <redact:redacted
            class="redacted" 
            title="{map:get($fact, 'title')}" 
            data-key="{@ID}">[<xsl:value-of select="map:get($fact, 'name')"/>]</redact:redacted>

    </xsl:template>

    <!-- If a key does not exist in the facts we don't want to redact it -->
    <xsl:template match="KEY[not(exists(map:get($redact:facts, @ID)))]">
        <xsl:apply-templates/>
    </xsl:template>

    <!-- Everything else is redacted as normal -->
    <xsl:template match="@*|node()">
      <xsl:copy copy-namespaces="no">
        <xsl:apply-templates select="@*|node()"/>
      </xsl:copy>
    </xsl:template>
    
    
    
</xsl:stylesheet>
