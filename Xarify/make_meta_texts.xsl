<?xml version="1.0"?>
<xsl:stylesheet xmlns:lace="http://heml.mta.ca/2019/lace" xmlns:dc="http://purl.org/dc/elements/1.1/" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml"/>
  <xsl:param name="identifier"></xsl:param>
  <xsl:param name="classifier"/>
  <xsl:param name="rundate"/>
   <xsl:template match="/">
          <xsl:apply-templates select="/texts/archivetext[archive_number/text() = $identifier] | metadata[identifier/text() = $identifier]"/>
  </xsl:template>
  <xsl:template match="*">
    <lace:run>
      <dc:identifier>
        <xsl:value-of select="$identifier"/>
      </dc:identifier>
      <lace:classifier>
        <xsl:value-of select="$classifier"/>
      </lace:classifier>
      <dc:date>
        <xsl:value-of select="$rundate"/>
</dc:date>
      <lace:ocrengine>Ocropus</lace:ocrengine>
      <lace:ocroutputtype>selected</lace:ocroutputtype>
    </lace:run>
  </xsl:template>
</xsl:stylesheet>
