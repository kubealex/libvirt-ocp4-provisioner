<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform">
  <xsl:output omit-xml-declaration="yes" indent="yes"/>

  <!-- Identity transform to copy everything as is -->
  <xsl:template match="node()|@*">
    <xsl:copy>
      <xsl:apply-templates select="node()|@*"/>
    </xsl:copy>
  </xsl:template>

  <!-- Use SATA CD-ROM for Linux setup for UEFI compatibility -->
  <xsl:template match="disk[target/@bus='ide']">
    <xsl:copy>
      <xsl:apply-templates select="@*"/>
      <target dev="sdb" bus="sata"/>
      <xsl:apply-templates select="node()[not(self::target)]"/>
    </xsl:copy>
  </xsl:template>

</xsl:stylesheet>