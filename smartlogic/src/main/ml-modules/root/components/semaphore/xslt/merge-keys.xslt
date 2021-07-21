<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:xdmp="http://marklogic.com/xdmp"
    exclude-result-prefixes="xs xdmp"
    version="2.0">
    
    <!-- merge sequential KEY elements where the keys are identical -->
    <xsl:template match="*[count(KEY) gt 1]">
        <xsl:copy>
            <xsl:apply-templates select="@*"/>
            <xsl:for-each-group select="node()[not(self::text()[not(normalize-space())])]"
                group-adjacent="if (@ID) then @ID else 'something-else'">
                <xsl:choose>
                    <xsl:when test="self::KEY">
                        <!-- NB - this needs to stay in the empty namespace -->
                        <KEY xmlns="" ID="{@ID}">
                            <xsl:sequence
                                select="for $node in current-group()
                                    return
                                        if ($node/self::text()) 
                                            then $node
                                            else $node/node()"/>
                        </KEY>
                    </xsl:when>
                    <xsl:otherwise>
                        <xsl:apply-templates select="current-group()"/>
                    </xsl:otherwise>
                </xsl:choose>
            </xsl:for-each-group>
        </xsl:copy>
    </xsl:template>
    
    <!-- identity transform for any other elements in any mode -->
    <xsl:template match="@* | node()" mode="#all">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()" mode="#current"/>
        </xsl:copy>
    </xsl:template>
    
    
</xsl:stylesheet>