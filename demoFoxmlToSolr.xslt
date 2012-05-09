<?xml version="1.0" encoding="UTF-8"?> 
<!-- $Id: demoFoxmlToLucene.xslt 5734 2006-11-28 11:20:15Z gertsp $ -->
<xsl:stylesheet version="1.0"
	        xmlns:xsl="http://www.w3.org/1999/XSL/Transform"   
    	        xmlns:exts="xalan://dk.defxws.fedoragsearch.server.GenericOperationsImpl"
    	        xmlns:islandora-exts="xalan://ca.upei.roblib.DataStreamForXSLT"
    		exclude-result-prefixes="exts islandora-exts"
		xmlns:zs="http://www.loc.gov/zing/srw/"
		xmlns:foxml="info:fedora/fedora-system:def/foxml#"
		xmlns:dc="http://purl.org/dc/elements/1.1/"
		xmlns:oai_dc="http://www.openarchives.org/OAI/2.0/oai_dc/"
		xmlns:mods="http://www.loc.gov/mods/v3"
		xmlns:rdf="http://www.w3.org/1999/02/22-rdf-syntax-ns#"
		xmlns:rdfs="http://www.w3.org/2000/01/rdf-schema#"
		xmlns:rel="info:fedora/fedora-system:def/relations-external#"
		xmlns:macrepo="http://repository.mcmaster.ca/schema/index.html"
		xmlns:fedora-model="info:fedora/fedora-system:def/model#"
		xmlns:fedora="info:fedora/fedora-system:def/relations-external#"
                xmlns:uvalibdesc="http://dl.lib.virginia.edu/bin/dtd/descmeta/descmeta.dtd"
		xmlns:uvalibadmin="http://dl.lib.virginia.edu/bin/admin/admin.dtd/">
	<xsl:output method="xml" indent="yes" encoding="UTF-8"/>

<!--
	 This xslt stylesheet generates the Solr doc element consisting of field elements
     from a FOXML record. The PID field is mandatory.
     Options for tailoring:
       - generation of fields from other XML metadata streams than DC
       - generation of fields from other datastream types than XML
         - from datastream by ID, text fetched, if mimetype can be handled
             currently the mimetypes text/plain, text/xml, text/html, application/pdf can be handled.
-->

	<xsl:param name="REPOSITORYNAME" select="repositoryName"/>
	<xsl:param name="FEDORASOAP" select="repositoryName"/>
	<xsl:param name="FEDORAUSER" select="repositoryName"/>
	<xsl:param name="FEDORAPASS" select="repositoryName"/>
	<xsl:param name="TRUSTSTOREPATH" select="repositoryName"/>
	<xsl:param name="TRUSTSTOREPASS" select="repositoryName"/>
	<xsl:variable name="PID" select="/foxml:digitalObject/@PID"/>
	<xsl:variable name="docBoost" select="1.4*2.5"/> <!-- or any other calculation, default boost is 1.0 -->
	
	<xsl:template match="/">
		<add> 
		<doc> 
			<xsl:attribute name="boost">
				<xsl:value-of select="$docBoost"/>
			</xsl:attribute>
		<!-- The following allows only active demo FedoraObjects to be indexed. -->
		<xsl:if test="foxml:digitalObject/foxml:objectProperties/foxml:property[@NAME='info:fedora/fedora-system:def/model#state' and @VALUE='Active']">
			<xsl:if test="not(foxml:digitalObject/foxml:datastream[@ID='METHODMAP'] or foxml:digitalObject/foxml:datastream[@ID='DS-COMPOSITE-MODEL'])">
				<xsl:apply-templates mode="activeDemoFedoraObject"/>
			</xsl:if>
		</xsl:if>
		</doc>
		</add>
	</xsl:template>

	<xsl:template match="/foxml:digitalObject" mode="activeDemoFedoraObject">
			<field name="PID" boost="2.5">
				<xsl:value-of select="$PID"/>
			</field>
			<xsl:for-each select="foxml:objectProperties/foxml:property">
				<field >
					<xsl:attribute name="name"> 
						<xsl:value-of select="concat('fgs.', substring-after(@NAME,'#'))"/>
					</xsl:attribute>
					<xsl:value-of select="@VALUE"/>
				</field>
			</xsl:for-each>
			<xsl:for-each select="foxml:datastream/foxml:datastreamVersion[last()]/foxml:xmlContent/oai_dc:dc/*">
				<field >
					<xsl:attribute name="name">
						<xsl:value-of select="concat('dc.', substring-after(name(),':'))"/>
					</xsl:attribute>
					<xsl:value-of select="text()"/>
				</field>
			</xsl:for-each>
			
		<!-- Full Text - OCR -->
		<xsl:for-each select="foxml:datastream[@ID='OCR']/foxml:datastreamVersion[last()]">
                  <field>
                    <xsl:attribute name="name">
                      <xsl:value-of select="concat('OCR.', 'OCR')"/>
                    </xsl:attribute>
                    <xsl:value-of select="islandora-exts:getDatastreamTextRaw($PID, $REPOSITORYNAME, 'OCR', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)" />
                  </field>
                </xsl:for-each>
		
                <!-- field added for indexing only  -->
        
		<field>
            	<xsl:attribute name="name">
                	<xsl:value-of select="concat('mods.', 'indexTitle')"/>
            	</xsl:attribute>
            	<xsl:value-of select="//mods:title"/>
       	 	</field>

        	<xsl:variable name="pageCModel">
            		<xsl:text>info:fedora/ilives:pageCModel</xsl:text>
        	</xsl:variable>

        	<xsl:variable name="thisCModel">
            		<xsl:value-of select="//fedora-model:hasModel/@rdf:resource"/>
        	</xsl:variable>
        	<xsl:value-of select="$thisCModel"/>
        
			<!-- MODS Indexing -->
	        </xsl:template>	
		<xsl:template name="mods">
        		<xsl:variable name="MODS_STREAM" select="islandora-exts:getXMLDatastreamASNodeList($PID, $REPOSITORYNAME, 'MODS', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
            
		<xsl:for-each select="foxml:datastream[@ID='MODS']/foxml:datastreamVersion[last()]">
            	<xsl:call-template name="mods"/>
            	<!--only call this if the mods stream exists-->
        	</xsl:for-each>
        
			<xsl:for-each select="$MODS_STREAM//mods:title">
            <xsl:if test="text() [normalize-space(.) ]">
                <!--don't bother with empty space-->
                <field>
                    <xsl:attribute name="name">
                        <xsl:value-of select="concat('mods.', 'title')"/>
                    </xsl:attribute>
                    <xsl:value-of select="../mods:nonSort/text()"/>
                    <xsl:text> </xsl:text>
                    <xsl:value-of select="text()"/>
                </field>
            </xsl:if>

			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:subTitle">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'subTitle')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:abstract">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="text()"/>
					</field>
				</xsl:if>
	
	
			</xsl:for-each>
			<!--test of optimized version don't call normalize-space twice in this one-->
			<xsl:for-each select="$MODS_STREAM//mods:genre">
				<xsl:variable name="textValue" select="normalize-space(text())"/>
				<xsl:if test="$textValue != ''">
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="$textValue"/>
					</field>
				</xsl:if>
	
	
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:form">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
	
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:roleTerm">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', text())"/>
						</xsl:attribute>
						<xsl:value-of select="../../mods:namePart/text()"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:note[@type='statement of responsibility']">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'sor')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:note">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'note')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:topic">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'topic')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:geographic">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'geographic')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:caption">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'caption')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
	
			<xsl:for-each select="$MODS_STREAM//mods:subject/*">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<!--changed names to have each child element uniquely indexed-->
							<xsl:value-of select="concat('mods.', 'subject')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:extent">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'extent')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:accessCondition">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'accessCondition')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:country">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'country')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:province">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'province')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:county">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'county')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:region">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'region')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:city">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'city')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:citySection">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'citySection')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:subject/mods:name/mods:namePart/*">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'subject')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
	
			<xsl:for-each select="$MODS_STREAM//mods:physicalDescription/*">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:originInfo//mods:placeTerm[@type='text']">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'place_of_publication')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:originInfo/mods:publisher">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:originInfo/mods:edition">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:originInfo/mods:dateIssued">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
	
			<xsl:for-each select="//mods:originInfo/mods:dateCreated">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:originInfo/mods:issuance">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
	
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:physicalLocation">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			<xsl:for-each select="$MODS_STREAM//mods:identifier">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', name())"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
	
			<xsl:for-each select="$MODS_STREAM//mods:detail[@type='page number']/mods:number">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('mods.', 'pageNum')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			</xsl:template>
			<!-- END MODS -->
			
			<!-- MACREPO -->
			<xsl:template name="macrepo">
        	<xsl:variable name="MACREPO_STREAM" select="islandora-exts:getXMLDatastreamASNodeList($PID, $REPOSITORYNAME, 'MACREPO', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>

			<xsl:for-each select="foxml:datastream[@ID='MACREPO']/foxml:datastreamVersion[last()]">
            	<xsl:call-template name="macrepo"/>
            	<!--only call this if the mods stream exists-->
        	</xsl:for-each>
        	
        	<xsl:for-each select="$MACREPO_STREAM//macrepo:baseMapProducer">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'baseMapProducer')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>            
            
            <xsl:for-each select="$MACREPO_STREAM//macrepo:dateOverPrint">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'dateOverPrint')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each> 
            
            <xsl:for-each select="$MACREPO_STREAM//macrepo:dateBaseMap">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'dateBaseMap')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each> 
			
            <xsl:for-each select="$MACREPO_STREAM//macrepo:translation">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'translation')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			
            <xsl:for-each select="$MACREPO_STREAM//macrepo:transcript">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'transcript')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			
            <xsl:for-each select="$MACREPO_STREAM//macrepo:summary">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'summary')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
            <xsl:for-each select="$MACREPO_STREAM//macrepo:caseStudy">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'caseStudy')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
            <xsl:for-each select="$MACREPO_STREAM//macrepo:recipient">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'recipient')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>		
			
            <xsl:for-each select="$MACREPO_STREAM//macrepo:sender">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'sender')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>		
			
            <xsl:for-each select="$MACREPO_STREAM//macrepo:postmark">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'postmark')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>            
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:specialCodes">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'specialCodes')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>		
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:specialLabels">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'specialLabels')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:internmentCamp">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'internmentCamp')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>		
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:gestapoCamp">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'gestapoCamp')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:powCamp">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'powCamp')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:concentrationCamp">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'concentrationCamp')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:taxonomyTerms">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'taxonomyTerms')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:subCamp">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'subCamp')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:prisonBlock">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'prisonBlock')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:prisonerName">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'prisonerName')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:annotation">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'annotation')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:sheetTitle">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'sheetTitle')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:distanceVertical">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'distanceVertical')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:distanceHorizontal">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'distanceHorizontal')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:mapID">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'mapID')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:sheetNumber">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'sheetNumber')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:seriesNumber">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'seriesNumber')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:seriesName">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'seriesName')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:prisonerNumber">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'prisonerNumber')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:biographicalNote">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'biographicalNote')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:unit">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'unit')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:location">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'location')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:bertrandRussellNumber">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'bertrandRussellNumber')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			

			<xsl:for-each select="$MACREPO_STREAM//macrepo:photoReference">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'photoReference')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:subSeries">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'subSeries')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:oblique">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'oblique')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:mapSheetReference">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'mapSheetReference')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:editionNumber">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'editionNumber')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:envelopeNumber">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'envelopeNumber')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>		
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:era">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'era')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>			
			
			<xsl:for-each select="$MACREPO_STREAM//macrepo:theme">
				<xsl:if test="text() [normalize-space(.) ]">
					<!--don't bother with empty space-->
					<field>
						<xsl:attribute name="name">
							<xsl:value-of select="concat('macrepo.', 'theme')"/>
						</xsl:attribute>
						<xsl:value-of select="normalize-space(text())"/>
					</field>
				</xsl:if>
			</xsl:for-each>	
			<!-- END MACREPO -->
			
			<!-- a managed datastream is fetched, if its mimetype 
			     can be handled, the text becomes the value of the field. -->
			<xsl:for-each select="foxml:datastream[@CONTROL_GROUP='M']">
				<field index="TOKENIZED" store="YES" termVector="NO">
					<xsl:attribute name="name">
						<xsl:value-of select="concat('dsm.', @ID)"/>
					</xsl:attribute>
					<xsl:value-of select="exts:getDatastreamText($PID, $REPOSITORYNAME, @ID, $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)"/>
				</field>
			</xsl:for-each>
			
	</xsl:template>
	<!--
	<xsl:template match="*" mode="simple_set">
		<xsl:param name="prefix">mods</xsl:param>
		<xsl:param name="suffix"></xsl:param>
		<field>
			<xsl:attribute name="name">
				<xsl:value-of select="contact($prefix, local-name(), $suffix)"/>
			</xsl:attribute>
			<xsl:value-of select="text()"/>
		</field>
	</xsl:template>
	-->
</xsl:stylesheet>	
