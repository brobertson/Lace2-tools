<xsl:stylesheet  version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:tei="http://www.tei-c.org/ns/1.0">
    <xsl:template match="@*|node()">
        <xsl:copy>
            <xsl:apply-templates select="@*|node()"/>
        </xsl:copy>
</xsl:template>
<xsl:template match='tei:div[@type="edition"]//tei:div[@type="textpart"]/tei:p/text()'>
	<xsl:value-of select='normalize-space(translate(.,"abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ",""))'/>
</xsl:template>
</xsl:stylesheet>
