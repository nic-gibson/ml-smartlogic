<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:sem="http://noslogan.org/components/semaphore"
    xmlns:xdmp="http://marklogic.com/xdmp"
    xdmp:dialect="1.0-ml"
    exclude-result-prefixes="xs sem xdmp"
    version="2.0">
    
    <xsl:preserve-space elements="KEY PARAGRAPH"/>

    <xsl:param name="sem:required-keys" as="xs:string*"/>

    <!-- Strip out SYSTEM, URL, META, as we don't need them past this point 
        (all fact data is help in a MarkLogic map at this point)
    -->
    <xsl:template match="URL|SYSTEM|META|FIELD[@NAME='Type']"/>
    
    <!-- Strip out any key that is not in the useful keys list or is in the list but has an ancestor 
        that is a useful key -->
    <xsl:template match="KEY">
        <xsl:choose>
            <xsl:when test="@ID = $sem:required-keys and not(ancestor::KEY[@ID = $sem:required-keys])">
                <xsl:copy>
                    <xsl:apply-templates
                        select="@*|node()"/>
                </xsl:copy>
            </xsl:when>
            <xsl:otherwise>
                <!-- don't output empty children of keys - they will be empty keys -->
                <xsl:apply-templates select="node()"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:template>
    

    
    <!-- lose empty keys -->
    <xsl:template match="KEY[not(normalize-space())]" priority="1"/>
    
    <!-- all other elements are unchanged -->
    <xsl:template match="@* | node()" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
</xsl:stylesheet>