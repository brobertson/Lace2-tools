<?xml version="1.0"?>
<xsl:stylesheet xmlns:lace="http://heml.mta.ca/2019/lace" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml"/>
  <xsl:param name="identifier"></xsl:param>
  <xsl:param name="scale"/>
  <xsl:template match="/">
          <xsl:apply-templates select="/texts/archivetext[archive_number/text() = $identifier] | metadata[identifier/text() = $identifier]"/>
  </xsl:template>
  <xsl:template match="*">
    <lace:imagecollection>
      <dc:identifier>
        <xsl:value-of select="$identifier"/>
      </dc:identifier>
      <dc:creator>
        <xsl:value-of select="creator"/>
      </dc:creator>
      <dc:publisher>
        <xsl:value-of select="publisher"/>
      </dc:publisher>
      <dc:date>
        <xsl:value-of select="date"/>
      </dc:date>
      <dc:title>
        <xsl:value-of select="title"/>
        <xsl:apply-templates select="volume"/>
      </dc:title>
      <lace:scale>
        <xsl:value-of select="$scale"/>
      </lace:scale>
    </lace:imagecollection>
  </xsl:template>
  <xsl:template match="volume">
          <xsl:if test="text()">
                  <xsl:text> Vol. </xsl:text>
                  <xsl:value-of select="."/>
          </xsl:if>
  </xsl:template>
</xsl:stylesheet>
