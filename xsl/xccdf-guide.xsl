<?xml version="1.0" encoding="UTF-8" ?>

<!--
  XSLT Stylesheet for XCCDF - xccdf2html-0.12.4
  This stylesheet transforms a resolved XCCDF document into a nice
  XHTML document, with table of contents, cross-links, and section
  numbers.  This stylesheet basically assumes that the document is
  compliant with the XCCDF schema, so validation is probably
  advisable.  Note that this stylesheet completely ignores all
  TestResult elements: they do not appear in the generated
  XHTML document.  

  The XCCDF document MUST be resolved before applying this
  stylesheet.  This stylesheet cannot deal with extension/inheritance 
  at all.

  This stylesheet has been tested and found to work correctly with
  the following XSLT processors: 
      - Java 1.5 (Apache Xalan)
      - MSIE 6.0 (MSXML 3?)
      - Mozilla 1.7 (Transformiix)
      - Firebird 1.0 (Transformiix)

 This stylesheet is known to fail with the following XSLT
 implementations:
      - MSIE 5.0 (MSXML 2?)

 Known issues:
      - This stylesheet does not handle Dublin Core metadata
	in references nor for the document itself.
      - This stylesheet does not handle locale/language issues 
        at all.  It simply treats all item properties alike.
      - The CSS structure is poor.
      - Handling of tailoring Values that appear inside hidden
        Groups is (arguably) faulty.
      - This stylesheet uses the // shortcut a lot, which is
        quite inefficient and inelegant, but appears to be
	unavoidable.
      - XCCDF 0.12.4 employs Dave Waltermire's platform
        specification schema 0.2.3.  This stylesheet has
        a modest amount of code specifically for platform
	text, but it could use more.

  Author: Neal Ziring (nziring@thecouch.ncsc.mil)
  Version: 0.12.4 (for XCCDF schema version 1.0rc4 - 0.12.4)
  Date: 13 Nov 04

 -->

<!-- 
 THIS SOFTWARE WAS CREATED BY THE U.S. GOVERNMENT.

 SOFTWARE IS PROVIDED "AS IS" WITHOUT WARRANTY OF ANY KIND, EITHER
 EXPRESS OR IMPLIED, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
 WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE.
 IN NO EVENT SHALL THE NATIONAL SECURITY AGENCY OR ANY AGENT OR
 REPRESENTATIVE THEREOF BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
 SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
 LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
 DATA OR PROFITS; OR BUSINESS INTERRUPTION), HOWEVER CAUSED, UNDER ANY
 THEORY OF LIABILITY, ARISING IN ANY WAY OUT OF THE USE OF OR INABILITY
 TO MAKE USE OF THIS SOFTWARE.
-->


<xsl:stylesheet version="1.0" 
	xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
	xmlns:htm="http://www.w3.org/1999/xhtml"
	xmlns="http://www.w3.org/1999/xhtml"
	xmlns:cdf="http://checklists.nist.gov/xccdf/1.1"
	>

<xsl:include href="xccdf-common.xsl" />

<!-- Set output style: XHTML using xml output method. -->
<xsl:output method="xml" encoding="UTF-8" indent="yes"/>

<!-- Set up an id key to match on against all Items -->
<xsl:key name="items" match="cdf:Group | cdf:Rule | cdf:Value" 
         use="@id"/>

<!-- Set up an id key to match on Item clusters: Rule and Group, Value -->
<xsl:key name="clusters-rg" match="cdf:Group | cdf:Rule" 
         use="@cluster-id"/>
<xsl:key name="clusters-v" match="cdf:Value" 
         use="@cluster-id"/>

<!-- Set up an id key to match on all Profiles -->
<xsl:key name="profiles" match="cdf:Profile" 
         use="@id"/>

<!-- Additional template for cdf:platform element; 
  -  this has changed to accomodate the CIS platform 
  -  schema 0.2.2.
  -->
<xsl:template match="cdf:platform" mode="idlist">
  <li><xsl:value-of select="@idref"/></li>
</xsl:template>

<!-- Additional templates for a Value element;
  -  For TOC, we present a line with number, for body
  -  we present a numbered section with title, and then
  -  the fields of the Value with a dl list.
  -->
<xsl:template match="cdf:Value" mode="toc">
  <xsl:param name="section-prefix"/>
  <xsl:param name="section-num" select="position()"/>

  <p class="toc2">
     <xsl:value-of select="$section-prefix"/>
     <xsl:value-of select="$section-num"/>
     <xsl:text>. </xsl:text>
     <a class="toc" href="#{@id}"><xsl:value-of select="./cdf:title/text()"/></a>
  </p>
</xsl:template>

<xsl:template match="cdf:Value" mode="body">
  <xsl:param name="section-prefix"/>
  <xsl:param name="section-num" select="position()"/>

  <xsl:comment>Value id = <xsl:value-of select="./@id"/></xsl:comment>
  <div>
  <h3 id="{@id}">
     <xsl:value-of select="$section-prefix"/>
     <xsl:value-of select="$section-num"/>
     <xsl:text>. Value: </xsl:text>
     <i><xsl:value-of select="./cdf:title/text()"/></i>
  </h3>

  <div class="simpleText">
    <xsl:if test="./cdf:status">
      <p>Status: <xsl:value-of select="./cdf:status/text()"/>
        <xsl:if test="./cdf:status/@date">
	   (as of <xsl:value-of select="./cdf:status/@date"/>)
	</xsl:if>
      </p>
    </xsl:if>
    <xsl:if test="./cdf:platform">
      <p>Applies only to:</p><ul>
        <xsl:apply-templates select="./cdf:platform" mode="idlist"/>
      </ul>
    </xsl:if>
    <p><xsl:text>Type: </xsl:text><xsl:value-of select="@type"/></p>
    <xsl:if test="@operator">
      <p><xsl:text>Operator: </xsl:text><xsl:value-of select="@operator"/></p>
    </xsl:if>


    <xsl:if test="/cdf:Benchmark/cdf:Profile">
        <p>Value and value contraints:</p>
          <table class="propertyTable" border="1" cellpadding="1" cellspacing="1">
            <tr>
               <th class="propertyTableHead">Property</th>
               <th class="propertyTableHead">Selector</th>
               <th class="propertyTableHead">Value</th>
            </tr>
            <xsl:for-each select="./cdf:value | ./cdf:default | ./cdf:match | ./cdf:lower-bound | ./cdf:upper-bound">
	        <tr>
                   <td style="width: 27%;"><b><xsl:value-of select="local-name()"/></b></td>
		   <td style="width: 22%; text-align: center;"><xsl:choose>
                        <xsl:when test="not(string-length(./@selector) = 0)"><xsl:value-of select="./@selector"/></xsl:when>
	 	        <xsl:otherwise>*</xsl:otherwise>
	           </xsl:choose></td>
		   <td><xsl:value-of select="./text()"/></td>
		</tr>
	    </xsl:for-each>
            <xsl:for-each select="./cdf:choices">
	        <tr>
                   <td style="width: 27%;"><b><xsl:value-of select="local-name()"/></b>
		   </td>
		   <td style="width: 22%; text-align: center;"><xsl:choose>
                        <xsl:when test="./@selector"><xsl:value-of select="not(string-length(./@selector) = 0)"/></xsl:when>
	 	        <xsl:otherwise>*</xsl:otherwise>
	           </xsl:choose></td>
		   <td>
		      <xsl:if test="boolean(number(./@mustMatch))">
			<i>Exclusive values:</i>
 		      </xsl:if>
		      <xsl:if test="not(number(./@mustMatch))">
			<i>Suggested values:</i>
 		      </xsl:if>
                       <ul class="smallList">
			<xsl:for-each select="./cdf:choice">
			   <li><xsl:value-of select="./text()"/></li>
			</xsl:for-each>
		       </ul>
                   </td>
		</tr>
	    </xsl:for-each>
          </table>
    </xsl:if>

    <xsl:if test="not(/cdf:Benchmark/cdf:Profile)">
	<p><xsl:text>Value: </xsl:text>
             <b><xsl:value-of select="./cdf:value/text()"/></b>
        </p>
	<xsl:if test="./cdf:default">
	  <p><xsl:text>Default value: </xsl:text>
              <xsl:value-of select="./cdf:default/text()"/>
          </p>
	</xsl:if>
	<xsl:if test="./@type = 'number'">
	  <xsl:if test="./cdf:lower-bound">
	    <p><xsl:text>Lower bound: </xsl:text><xsl:value-of select="./cdf:lower-bound/text()"/></p>
	  </xsl:if>
	  <xsl:if test="./cdf:upper-bound">
	    <p><xsl:text>Upper bound: </xsl:text><xsl:value-of select="./cdf:upper-bound/text()"/></p>
	  </xsl:if>
	</xsl:if>
        <xsl:if test="./@type = 'string'">
	  <xsl:if test="./cdf:match">
	    <p><xsl:text>Value pattern: </xsl:text><xsl:value-of select="./cdf:match/text()"/></p>
	  </xsl:if>
	</xsl:if>

	<xsl:if test="./cdf:choices">
	  <p><xsl:text>Choices: </xsl:text>
	    <xsl:if test="./cdf:choices/@mustMatch">
	       <xsl:text> (exclusive)</xsl:text>
	    </xsl:if>
	    <ul>
	       <xsl:for-each select="./cdf:choices/cdf:choice">
		  <li><xsl:value-of select="./text()"/></li>
	       </xsl:for-each>
	    </ul>
	  </p>
	</xsl:if>
    </xsl:if>

  </div>

  <xsl:if test="./cdf:description">
     <h4>Description</h4>
     <xsl:for-each select="./cdf:description">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:warning">
     <h4>Warning</h4>
     <xsl:for-each select="./cdf:warning">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:reference">
      <h4>References</h4>
      <ol>
	<xsl:for-each select="./cdf:reference">
	  <li><xsl:value-of select="text()"/>
	    <xsl:if test="@href">
	      [<a href="{@href}">link</a>]
           </xsl:if>
	  </li>
	</xsl:for-each>
     </ol>
  </xsl:if>
  </div>
</xsl:template>

<!-- Template for toc entries for both rules and groups -->
<xsl:template match="cdf:Group | cdf:Rule" mode="toc">
  <xsl:param name="section-prefix"/>
  <xsl:param name="section-num" select="position()"/>

  <li id="toc-{@id}">
     <xsl:value-of select="$section-prefix"/>
     <xsl:value-of select="$section-num"/>
     <xsl:text>. </xsl:text>
     <a class="toc" href="#{@id}"><xsl:value-of select="./cdf:title/text()"/></a>
  </li>
  <xsl:if test="./cdf:Group">
  <ul>
	<xsl:apply-templates mode="toc"
         select="./cdf:Group[not(number(@hidden)+number(@abstract))]">
	    <xsl:with-param name="section-prefix" select="concat($section-prefix,$section-num,'.')"/>
	</xsl:apply-templates>
  </ul>
  </xsl:if>
</xsl:template>


<!-- Template for toc entries for Profiles -->
<xsl:template match="cdf:Profile" mode="toc">
  <xsl:param name="section-prefix"/>
  <xsl:param name="section-num" select="position()"/>

  <p class="toc2">
     <xsl:value-of select="$section-prefix"/>
     <xsl:value-of select="$section-num"/>
     <xsl:text>. </xsl:text>
     <a class="toc" href="#profile-{@id}"><xsl:value-of select="./cdf:title/text()"/></a>
  </p>

</xsl:template>

<!-- template for body elements for Profiles -->
<xsl:template match="cdf:Profile" mode="body">
  <xsl:param name="section-prefix"/>
  <xsl:param name="section-num" select="position()"/>

  <xsl:comment>Profile id = <xsl:value-of select="./@id"/></xsl:comment>
  <div>
  <h3 id="profile-{@id}">
     <xsl:value-of select="$section-prefix"/>
     <xsl:value-of select="$section-num"/>
     <xsl:text>. Profile: </xsl:text>
     <i><xsl:value-of select="./cdf:title/text()"/></i>
  </h3>

<xsl:if test="@extends|./cdf:status|./cdf:platform">
  <div class="simpleText">
    <xsl:if test="@extends">
      <p>Extends: 
          <xsl:apply-templates select="key('profiles',@extends)" mode="prof-ref"/>
      </p>
    </xsl:if>
    <xsl:if test="./cdf:status">
      <p>Status: <xsl:value-of select="./cdf:status/text()"/>
        <xsl:if test="./cdf:status/@date">
	   (as of <xsl:value-of select="./cdf:status/@date"/>)
	</xsl:if>
      </p>
    </xsl:if>
    <xsl:if test="./cdf:platform">
      <p>Applies only to:</p><ul>
        <xsl:apply-templates select="./cdf:platform" mode="idlist"/>
      </ul>
    </xsl:if>
  </div>
</xsl:if>

  <xsl:if test="./cdf:description">
     <h4>Description</h4>
     <xsl:for-each select="./cdf:description">
       <p class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </p>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:select">
   <h4>Item Selections</h4>
   <div class="propertyText">
    <p>Rules and Groups explicitly selected and deselected for this profile.</p>
       <ul>
         <xsl:apply-templates select="." mode="sel-list"/>
       </ul>
   </div>
  </xsl:if>

  <xsl:if test="./cdf:set-value | ./cdf:refine-value">
   <h4>Value Settings</h4>
   <div class="propertyText">
    <p>Tailoring value adjustments explicitly set for this profile:</p>
       <ul>
         <xsl:apply-templates select="." mode="set-list"/>
       </ul>
   </div>
  </xsl:if>

  <xsl:if test="./cdf:reference">
      <h4>References</h4>
      <ol>
	<xsl:for-each select="./cdf:reference">
	  <li><xsl:value-of select="text()"/>
	    <xsl:if test="@href">
	      [<a href="{@href}">link</a>]
           </xsl:if>
	  </li>
	</xsl:for-each>
     </ol>
  </xsl:if>
  </div>
</xsl:template>

<xsl:template match="cdf:Profile" mode="sel-list">
   <xsl:apply-templates select="./cdf:select" mode="sel-list"/>
</xsl:template>

<xsl:template match="cdf:Profile" mode="set-list">
   <xsl:apply-templates select="./cdf:set-value" mode="set-list"/>
   <xsl:apply-templates select="./cdf:refine-value" mode="set-list"/>
</xsl:template>

<xsl:template match="cdf:select" mode="sel-list">
   <li>
       <xsl:if test="number(./@selected)">Included: </xsl:if>
       <xsl:if test="not(number(./@selected))">Excluded: </xsl:if>
       <xsl:if test="count(key('items',@idref))">
            <a href="#{@idref}">
                <xsl:value-of select="key('items', @idref)/cdf:title/text()"/>
            </a>
       </xsl:if>
       <xsl:if test="not(count(key('items',@idref)))">
            (cluster) 
            <xsl:for-each select="key('clusters-rg',@idref)">
              <a href="#{./@id}">
                <xsl:value-of select="./cdf:title/text()"/>
              </a> 
            </xsl:for-each>
       </xsl:if>
   </li>
</xsl:template>

<xsl:template match="cdf:set-value" mode="set-list">
   <li>
     <a href="#{@idref}"><xsl:value-of select="key('items', @idref)/cdf:title/text()"/></a><br/><xsl:text> set to value: </xsl:text><b><xsl:value-of select="./text()"/></b>
   </li>
</xsl:template>

<xsl:template match="cdf:refine-value" mode="set-list">
   <li>
     <a href="#{@idref}"><xsl:value-of select="key('items', @idref)/cdf:title/text()"/></a><br/><xsl:text> refinement selector: </xsl:text><b><xsl:value-of select="./@selector"/></b>
   </li>
</xsl:template>

<xsl:template match="cdf:Profile" mode="prof-ref">
   <a href="#profile-{@id}"><xsl:value-of select="./cdf:title/text()"/></a>
</xsl:template>


<!-- Additional template for a Group element;
  -  we present a numbered section with title, and then
  -  the fields of the Group with a dl list, then the
  -  enclosed items as subsections.
  -->
<xsl:template match="cdf:Group" mode="body">
  <xsl:param name="section-prefix"/>
  <xsl:param name="section-num" select="position()"/>

  <xsl:comment>Group id = <xsl:value-of select="./@id"/></xsl:comment>
  <div>
  <h3 id="{@id}">
     <xsl:value-of select="$section-prefix"/>
     <xsl:value-of select="$section-num"/>
     <xsl:text>. </xsl:text><xsl:value-of select="./cdf:title/text()"/>
  </h3>

  <xsl:if test="./cdf:status | ./cdf:platform">
  <div class="simpleText">
    <xsl:if test="./cdf:status">
      <p>Status: <xsl:value-of select="./cdf:status/text()"/>
        <xsl:if test="./cdf:status/@date">
	   (as of <xsl:value-of select="./cdf:status/@date"/>)
	</xsl:if>
      </p>
    </xsl:if>
    <xsl:if test="./cdf:platform">
      <p>Applies only to:</p><ul>
        <xsl:apply-templates select="./cdf:platform" mode="idlist"/>
      </ul>
    </xsl:if>
  </div>
  </xsl:if>

  <xsl:if test="./cdf:description">
     <!-- <h4>Description</h4> -->
     <xsl:for-each select="./cdf:description">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:rationale">
     <h4>Rationale</h4>
     <xsl:for-each select="./cdf:rationale">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:warning">
     <h4>Warning</h4>
     <xsl:for-each select="./cdf:warning">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:requires | ./cdf:conflicts">
     <h4>Dependencies</h4>
     <div class="propertyText">
     <ul>
     <xsl:for-each select="./cdf:requires">
          <xsl:variable name="thisid" select="@idref"/>
          <li><xsl:text>Requires: </xsl:text>
          <xsl:value-of select="@idref"/>
          <!--
	     <a href="#{@idref}">
	       <xsl:value-of select="key('items', @idref)/cdf:title/text()"/>
	     </a>
         -->
	  </li>
     </xsl:for-each>
     <xsl:for-each select="./cdf:conflicts">
          <xsl:variable name="thisid" select="@idref"/>
          <li><xsl:text>Conflicts with: </xsl:text>
	     <a href="#{@idref}">
	       <xsl:value-of select="key('items', @idref)/cdf:title/text()"/>
	     </a>
	  </li>
     </xsl:for-each>
     </ul>
     </div>
  </xsl:if>

  <xsl:if test="./cdf:reference">
     <h4>References</h4>
     <ol>
       <xsl:for-each select="./cdf:reference">
	   <li><xsl:value-of select="text()"/>
	     <xsl:if test="@href">
	       [<a href="{@href}">link</a>]
             </xsl:if>
	   </li>
        </xsl:for-each>
      </ol>
  </xsl:if>

  <xsl:apply-templates select="." mode="links" />

  <xsl:if test="./cdf:Rule">
    <div class="group-rules" id="rules-for-{@id}">
      <xsl:apply-templates mode="body" select="./cdf:Rule[not(number(@hidden)+number(@abstract))]">
         <xsl:with-param name="section-prefix" select="concat($section-prefix,$section-num,'.')"/>
      </xsl:apply-templates>
    </div>
  </xsl:if>
  <xsl:if test="./cdf:Group">
      <xsl:apply-templates mode="body" select="./cdf:Group[not(number(@hidden)+number(@abstract))]">
         <xsl:with-param name="section-prefix" select="concat($section-prefix,$section-num,'.')"/>
      </xsl:apply-templates>
  </xsl:if>
  </div>
</xsl:template>

<xsl:template match="cdf:Group|cdf:Rule" mode="links">
  <xsl:variable name='up'>parent group</xsl:variable>
  <xsl:variable name='next'>next</xsl:variable>
  <xsl:variable name='prev'>previous</xsl:variable>
  <p class="link">
      <xsl:if test="self::cdf:Group|parent::cdf:Benchmark">
        <a href="#toc-{@id}" title="Move to position of this item in table of contents.">table of contents</a> |
        <xsl:choose>
          <xsl:when test="preceding-sibling::cdf:Group"><a href="#{preceding-sibling::cdf:Group[1]/@id}" title="{preceding-sibling::cdf:Group[1]/cdf:title[1]}"><xsl:value-of select='$prev'/></a></xsl:when>
          <xsl:otherwise><span class='unknown'><xsl:value-of select='$prev'/></span></xsl:otherwise>
        </xsl:choose> |
        <xsl:choose>
          <xsl:when test="following-sibling::cdf:Group"><a href="#{following-sibling::cdf:Group[1]/@id}" title="{following-sibling::cdf:Group[1]/cdf:title[1]}"><xsl:value-of select='$next'/></a></xsl:when>
          <xsl:otherwise><span class='unknown'><xsl:value-of select='$next'/></span></xsl:otherwise>
        </xsl:choose> |
      </xsl:if>
      <xsl:choose>
        <xsl:when test="parent::cdf:Group"><a href="#{parent::cdf:Group/@id}" title="{parent::cdf:Group/cdf:title[1]}"><xsl:value-of select='$up'/></a></xsl:when>
        <xsl:otherwise><span class='unknown'><xsl:value-of select='$up'/></span></xsl:otherwise>
      </xsl:choose>
      <!--| <a href="#section-rules">home</a>-->
  </p>
</xsl:template>
<!-- Additional template for a Rule element in body;
  -  we present a numbered section with title, and then
  -  the fields of the Rule with a dl list.
  -->
<xsl:template match="cdf:Rule" mode="body">
  <xsl:param name="section-prefix"/>
  <xsl:param name="section-num" select="position()"/>

  <xsl:comment>Rule id = <xsl:value-of select="./@id"/></xsl:comment>
  <div>
  <h3 id="{@id}">
     <xsl:value-of select="$section-prefix"/>
     <xsl:value-of select="$section-num"/>
     <xsl:text>. </xsl:text><xsl:value-of select="./cdf:title/text()"/>
  </h3>

  <xsl:if test="./cdf:status | ./cdf:platform">
    <div class="simpleText">
      <xsl:if test="./cdf:status">
	<p>Status: <xsl:value-of select="./cdf:status/text()"/>
	  <xsl:if test="./cdf:status/@date">
	     (as of <xsl:value-of select="./cdf:status/@date"/>)
	  </xsl:if>
	</p>
      </xsl:if>
      <xsl:if test="./cdf:platform">
	<p>Applies only to:</p><ul>
	  <xsl:apply-templates select="./cdf:platform" mode="idlist"/>
	</ul>
      </xsl:if>
    </div>
  </xsl:if>
  
  <xsl:if test="./cdf:description">
     <!-- <h4>Description</h4> -->
     <xsl:for-each select="./cdf:description">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:rationale">
     <h4>Rationale</h4>
     <xsl:for-each select="./cdf:rationale">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:warning">
     <h4>Warning</h4>
     <xsl:for-each select="./cdf:warning">
       <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
       </div>
     </xsl:for-each>
  </xsl:if>

  <xsl:if test="./cdf:fixtext | ./cdf:fix">
     <h4>Remediation</h4>
     <xsl:for-each select="./cdf:fixtext">
        <div class="propertyText">
          <xsl:apply-templates select="./text() | ./*" mode="text"/>
        </div>
     </xsl:for-each>
     <xsl:if test="./cdf:fix">
        <div class="propertyText">
	   <p>Fix:</p>
	     <pre class="code">
	       <xsl:apply-templates select="./cdf:fix/text() | ./cdf:fix/*" mode="text"/>
	     </pre>
        </div>
      </xsl:if>
  </xsl:if>

  <xsl:if test="./cdf:requires | ./cdf:conflicts">
     <h4>Dependencies</h4>
     <div class="propertyText"><ul>
     <xsl:for-each select="./cdf:requires">
          <xsl:variable name="thisid" select="@idref"/>
          <li><xsl:text>Requires: </xsl:text>
	     <!--<a href="#{@idref}">-->
	       <!--<xsl:value-of select="key('items', @idref)/cdf:title/text()"/>-->
	       <xsl:value-of select="@idref"/>
	     <!--</a>-->
	  </li>
     </xsl:for-each>
     <xsl:for-each select="./cdf:conflicts">
          <xsl:variable name="thisid" select="@idref"/>
          <li><xsl:text>Conflicts with: </xsl:text>
	     <a href="#{@idref}">
	       <xsl:value-of select="key('items', @idref)/cdf:title/text()"/>
	     </a>
	  </li>
     </xsl:for-each>
     </ul></div>
  </xsl:if>    

  <xsl:if test="./cdf:reference">
     <h4>References</h4>
     <ol>
	 <xsl:for-each select="./cdf:reference[text()]">
	   <li><xsl:value-of select="text()"/>
	     <xsl:if test="@href">
	       [<a href="{@href}">link</a>]
             </xsl:if>
	   </li>
	 </xsl:for-each>
    </ol>
  </xsl:if>
  </div>

  <xsl:apply-templates select="." mode="links" />

</xsl:template>

<xsl:template match='/cdf:Benchmark'>
  <xsl:variable name="introSecNum" select="1"/>
  <xsl:variable name="valSecNum" select="2"/>
  <xsl:variable name="ruleSecNum"
	        select="2 + number(count(//cdf:Value[not(number(@hidden)+number(@abstract))])!=0)"/>
  <xsl:variable name="profSecNum"
                select="2 + number(count(./cdf:Rule[not(number(@hidden)+number(@abstract))] | ./cdf:Group[not(number(@hidden)+number(@abstract))])!=0) + number(count(//cdf:Value[not(number(@hidden)+number(@abstract))])!=0)"/>
  <xsl:variable name="concSecNum" 
                select="2 + number(count(./cdf:Rule[not(number(@hidden)+number(@abstract))] | ./cdf:Group[not(number(@hidden)+number(@abstract))])!=0) + number(count(//cdf:Value[not(number(@hidden)+number(@abstract))])!=0) + number(count(./cdf:Profile)!=0)"/>
  <xsl:variable name="refSecNum" 
                select="2 + number(count(./cdf:Rule[not(number(@hidden)+number(@abstract))] | ./cdf:Group[not(number(@hidden)+number(@abstract))])!=0) + number(count(//cdf:Value[not(number(@hidden)+number(@abstract))])!=0) + number(count(./cdf:Profile)!=0) + number(count(./cdf:rear-matter)!=0)"/>

  <xsl:call-template name='warn-unresolved'/>

  <xsl:call-template name='skelet'>
    <xsl:with-param name='title' select='string(cdf:title[1])'/>
    <xsl:with-param name='footer'><a href="http://scap.nist.gov/specifications/xccdf/">XCCDF</a> benchmark security guide.</xsl:with-param>
    <xsl:with-param name='content'>
          <h2 id="section-intro"><!--<xsl:value-of select='cdf:title[1]'/>-->Security Guide</h2>
          <xsl:if test="./cdf:front-matter">
             <xsl:for-each select="./cdf:front-matter">
               <p id="front-matter">
                  <xsl:apply-templates select="./text() | ./*" mode="text"/>
               </p>
             </xsl:for-each>
          </xsl:if>
          <xsl:if test="./cdf:description">
             <h3>Description</h3>
             <xsl:for-each select="./cdf:description">
               <div class="propertyText">
                  <xsl:apply-templates select="./text() | ./*" mode="text"/>
               </div>
             </xsl:for-each>
          </xsl:if>
          <xsl:if test="./cdf:notice">
              <xsl:for-each select="./cdf:notice">
                <h3>Legal Notice</h3>       
                  <div class="legal"><p><xsl:value-of select="text()"/></p></div>
              </xsl:for-each>
          </xsl:if>
          <xsl:if test="./cdf:status | ./cdf:version | ./cdf:platform">
              <h3>Benchmark information</h3>
              <p>Status: <b><xsl:value-of select="./cdf:status/text()"/></b>
                <xsl:if test="./cdf:status/@date"> (as of <xsl:value-of select="./cdf:status/@date"/>)</xsl:if>
              </p>
              <xsl:if test="./cdf:version"><p>Version: <xsl:value-of select="./cdf:version/text()"/></p></xsl:if>
              <xsl:if test="./cdf:platform">
                <p>Applies to:</p><ul><xsl:apply-templates select="./cdf:platform" mode="idlist"/></ul>
              </xsl:if>
          </xsl:if>
           
          <xsl:if test="./cdf:Group[not(number(@hidden)+number(@abstract))] | ./cdf:Rule[not(number(@hidden)+number(@abstract))]">
             <h2 id="section-rules">
                 <!--<xsl:value-of select="$ruleSecNum"/>. -->Groups and Rules
             </h2>
             <ul class="toc-struct"><xsl:apply-templates select="./cdf:Group[not(number(@hidden)+number(@abstract))] | ./cdf:Rule[not(number(@hidden)+number(@abstract))]" mode="toc"/></ul>
             <xsl:apply-templates select="./cdf:Group[not(number(@hidden)+number(@abstract))] | ./cdf:Rule[not(number(@hidden)+number(@abstract))]" mode="body"/>
          </xsl:if>

          <xsl:if test="./cdf:Profile">
             <h2 id="section-profiles"><!--<xsl:value-of select="$profSecNum"/>. -->Profiles</h2>
             <xsl:apply-templates select=".//cdf:Profile" mode="body">
            <xsl:sort select="./cdf:title/text()" data-type="text" order="ascending"/>
             </xsl:apply-templates>
          </xsl:if>

          <xsl:if test=".//cdf:Value[not(number(@hidden)+number(@abstract))]">
             <h2 id="section-values">
                   <!--<xsl:value-of select="$valSecNum"/>. -->Tailoring Values
             </h2>
             <xsl:apply-templates select=".//cdf:Value[not(number(@hidden)+number(@abstract))]" mode="body">
            <xsl:sort select="./cdf:title/text()" data-type="text" order="ascending"/>
             </xsl:apply-templates>
          </xsl:if>

          <xsl:if test="./cdf:rear-matter">
             <h2 id="section-conc">
                 <!--<xsl:value-of select="$concSecNum"/>. -->Conclusions
             </h2>
             <xsl:for-each select="./cdf:rear-matter">
               <div class="propertyText">
                  <xsl:apply-templates select="./text() | ./*" mode="text"/>
               </div>
             </xsl:for-each>
          </xsl:if>

          <xsl:if test="./cdf:reference">
             <h2 id="section-references">
                <!--<xsl:value-of select="$refSecNum"/>. -->References
             </h2>
             <ol class="propertyText">
            <xsl:for-each select="./cdf:reference[normalize-space(text())]">
              <li><xsl:value-of select="text()"/>
                <xsl:if test="@href">
                  [<a href="{@href}">link</a>]
                    </xsl:if>
              </li>
            </xsl:for-each>
             </ol>
          </xsl:if>
    </xsl:with-param>
  </xsl:call-template>
</xsl:template>

</xsl:stylesheet>
