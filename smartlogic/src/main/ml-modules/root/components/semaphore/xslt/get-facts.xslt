<?xml version="1.0" encoding="UTF-8"?>
<xsl:stylesheet xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
    xmlns:xs="http://www.w3.org/2001/XMLSchema"
    xmlns:map="http://marklogic.com/xdmp/map"
    xmlns:sem="http://noslogan.org/components/semaphore"
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    exclude-result-prefixes="xs sem"
    version="2.0">

    <!-- convert the facts stored in the SmartLogic output to a map of maps whilst removing the facts that won't be used in output generation -->

    <xsl:output indent="yes"/>

    <xsl:template match="/">
        <map:map>
            <xsl:apply-templates select="response/STRUCTUREDDOCUMENT/META"/>
        </map:map>
    </xsl:template>

    <!-- The META elements of interest are children of other META elements -->
    <xsl:template match="META[META]">
            <xsl:apply-templates select="META"/>
    </xsl:template>

    <!-- None of these provide useful keys for output generation -->
    <xsl:template match="META[not(META)][ends-with(@name, 'sentence')]" priority="1"/>
    <xsl:template match="META[not(META)][ends-with(@name, 'evidence')]" priority="1"/>
    <xsl:template match="META[not(@CandidateKey)]" priority="1"/>

    <!-- Each META of interest becomes a map entry containing a map. Later this gives us efficient
         lookup when we find the FIELDs to redact -->
    <xsl:template match="META">
        <map:entry  key="{@CandidateKey}">
            <map:value>
                <map:map>
                    <map:entry key="name">
                          <map:value  xsi:type="xs:string"><xsl:value-of select="@name"/></map:value>
                    </map:entry>
                    <map:entry key="value">
                          <map:value  xsi:type="xs:string"><xsl:value-of select="if (lower-case(@name) = 'date of birth')
                            then sem:find-year(@value) else @value"/></map:value>
                    </map:entry>
                    <map:entry key="title">
                        <map:value xsi:type="xs:string"><xsl:value-of select="string-join((parent::META/@name, @name), '::')"/></map:value>
                    </map:entry>
                </map:map>
            </map:value>
        </map:entry>
    </xsl:template>

    <!-- ******************************************************************

    Try to identify the year portion of a date of birth, Return the "xx/xx/YYYY"
    string for output if found. Otherwise just return "xx/xx/xxxx".

    ******************************************************************* -->
    <xsl:function name="sem:find-year" as="xs:string">
        <xsl:param name="source" as="xs:string"/>
        <xsl:choose>
            <xsl:when test="matches($source, '\d\d\d\d[. \-]\d\d[. \-]\d\d')">
                <xsl:sequence select="concat('xx/xx/', tokenize($source, '[. \-]')[1])"/>
            </xsl:when>
            <xsl:when test="matches($source, '\d\d[. \-]\d\d[. \-]\d\d\d\d')">
                <xsl:sequence select="concat('xx/xx/', tokenize($source, '[. \-]')[3])"/>
            </xsl:when>
            <xsl:otherwise>
                <xsl:sequence select="'xx/xx/xxxx'"/>
            </xsl:otherwise>
        </xsl:choose>
    </xsl:function>


</xsl:stylesheet>
