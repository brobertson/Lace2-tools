<?xml version="1.0"?>
<xsl:stylesheet xmlns:repo="http://exist-db.org/xquery/repo"  xmlns:dc="http://purl.org/dc/elements/1.1/"  xmlns:xsl="http://www.w3.org/1999/XSL/Transform" version="1.0">
  <xsl:output method="xml"/>
  <xsl:param name="identifier"/>
    <xsl:template match="/">
	  <xsl:apply-templates select="/texts/archivetext[archive_number/text() = $identifier] | metadata[identifier/text() = $identifier]"/>
  </xsl:template>
  <xsl:template match="*">
    <repo:meta>
	    <repo:description>Base images for <xsl:value-of select="creator[1]"/> (<xsl:value-of select="date"/>)  <xsl:value-of select="title"/> <xsl:apply-templates select="volume"/></repo:description>
      <repo:author>Bruce Robertson brobertson@mta.ca</repo:author>
      <repo:website>http://heml.mta.ca/Lace</repo:website>
      <repo:status>beta</repo:status>
      <repo:copyright>true</repo:copyright>
      <repo:license>GNU-LGPL</repo:license>
      <!-- "library" is a better repo:type, but in that case, one can't
	   see the package in the package manager -->
      <repo:type>library</repo:type>
      <repo:target>
        <xsl:value-of select="$identifier"/>
      </repo:target>
      <repo:prepare>pre-install.xql</repo:prepare>
      <repo:finish/>
    </repo:meta>
  </xsl:template>
  <xsl:template match="volume">
	  <xsl:if test="text()">
		  <xsl:text> Vol. </xsl:text>
		  <xsl:value-of select="."/>
          </xsl:if>
  </xsl:template>
</xsl:stylesheet>
