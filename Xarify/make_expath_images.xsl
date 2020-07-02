<?xml version="1.0"?>
<xsl:stylesheet xmlns:pkg="http://expath.org/ns/pkg" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml"/>
  <xsl:param name="identifier"/>
  <xsl:template match="/">
          <xsl:apply-templates select="/texts/archivetext[archive_number/text() = $identifier] | metadata[identifier/text() = $identifier]"/>
  </xsl:template>
  <xsl:template match="*">
    <pkg:package version="1" spec="1.0">
	    <xsl:attribute name="name">http://heml.mta.ca/Lace/Images/<xsl:value-of select="$identifier"/></xsl:attribute>
      <xsl:attribute name="abbrev">
	      <xsl:value-of select="$identifier"/>
      </xsl:attribute>
      <pkg:title><xsl:value-of select="$identifier"/>: OCR Images</pkg:title>
      <pkg:dependency package="http://heml.mta.ca/Lace/application" semver-min="0.5.7">
      </pkg:dependency>
    </pkg:package>
  </xsl:template>
</xsl:stylesheet>
