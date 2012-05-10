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
					<xsl:value-of select="exts:getDatastreamTextRaw($PID, $REPOSITORYNAME, 'OCR', $FEDORASOAP, $FEDORAUSER, $FEDORAPASS, $TRUSTSTOREPATH, $TRUSTSTOREPASS)" />
				  </field>
				</xsl:for-each>
		
				<!-- field added for indexing only	-->
		
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexTitle')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:title"/>
			</field>
			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexNote')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:note"/>
			</field>			

			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indextypeOfResource')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:typeOfResource"/>
			</field>

			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexSubject')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:subject"/>
			</field>
			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexphysicalDescription')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:physicalDescription"/>
			</field>
			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indextypeOfResource')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:typeOfResource"/>
			</field>
			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexlanguage')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:language"/>
			</field>
			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexoriginInfo')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:originInfo"/>
			</field>			
			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexabstract')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:abstract"/>
			</field>
						
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexgenre')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:genre"/>
			</field>
						
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexform')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:form"/>
			</field>
						
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexroleTerm')"/>
				</xsl:attribute>
				<xsl:value-of select="../../mods:namePart/text()"/>
			</field>
						
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indextopic')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:topic"/>
			</field>
						
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexgeographic')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:geographic"/>
			</field>
											
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexcountry')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:country"/>
			</field>
										
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexregion')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:region"/>
			</field>
									
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexpublisher')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:indexpublisher"/>
			</field>
									
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexgeographic')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:geographic"/>
			</field>
										
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexrelatedItem')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:relatedItem/titleInfo/title"/>
			</field>		
										
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('mods.', 'indexphysicalLocation')"/>
				</xsl:attribute>
				<xsl:value-of select="//mods:physicalLocation"/>
			</field>
														
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexbaseMapProducer')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:baseMapProducer"/>
			</field>	
																
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexdateOverPrint')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:dateOverPrint"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexdateBaseMap')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:dateBaseMap"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indextranslation')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:translation"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indextranscript')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:transcript"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexcaseStudy')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:caseStudy"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexrecipient')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:recipient"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexsender')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:sender"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexspecialCodes')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:specialCodes"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexspecialLabels')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:specialLabels"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexinternmentCamp')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:internmentCamp"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexgestapoCamp')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:gestapoCamp"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexpowCamp')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:powCamp"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexconcentrationCamp')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:concentrationCamp"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indextaxonomyTerms')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:taxonomyTerms"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexsubCamp')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:baseMapProducer"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexprisonBlock')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:prisonBlock"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexprisonerName')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:prisonerName"/>
			</field>
																			
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexannotation')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:annotation"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexsheetTitle')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:sheetTitle"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexdistanceVertical')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:distanceVertical"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexdistanceHorizontal')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:distanceHorizontal"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexsheetNumber')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:sheetNumber"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexseriesNumber')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:seriesNumber"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexseriesName')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:seriesName"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexprisonerNumber')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:prisonerNumber"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexbiographicalNote')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:biographicalNote"/>
			</field>
																								
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexunit')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:unit"/>
			</field>
																										
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexbertrandRussellNumber')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:bertrandRussellNumber"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexphotoReference')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:photoReference"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexsubSeries')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:subSeries"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexmapSheetReference')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:mapSheetReference"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexoblique')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:oblique"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexeditionNumber')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:editionNumber"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexenvelopeNumber')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:envelopeNumber"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indexera')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:era"/>
			</field>
																													
			<field>
				<xsl:attribute name="name">
					<xsl:value-of select="concat('macrepo.', 'indextheme')"/>
				</xsl:attribute>
				<xsl:value-of select="//macrepo:theme"/>
			</field>
			
			<xsl:variable name="pageCModel">
					<xsl:text>info:fedora/ilives:pageCModel</xsl:text>
			</xsl:variable>

			<xsl:variable name="thisCModel">
					<xsl:value-of select="//fedora-model:hasModel/@rdf:resource"/>
			</xsl:variable>
			<xsl:value-of select="$thisCModel"/>		
	
	</xsl:template>

</xsl:stylesheet>	
