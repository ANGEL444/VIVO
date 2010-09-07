<%-- $This file is distributed under the terms of the license in /doc/license.txt$ --%>

<%@ page import="java.util.List" %>
<%@ page import="java.util.ArrayList" %>
<%@ page import="java.util.Arrays" %>

<%@ page import="com.hp.hpl.jena.rdf.model.Literal"%>
<%@ page import="com.hp.hpl.jena.rdf.model.Model"%>
<%@ page import="com.hp.hpl.jena.vocabulary.XSD" %>

<%@ page import="edu.cornell.mannlib.vitro.webapp.beans.Individual"%>
<%@ page import="edu.cornell.mannlib.vitro.webapp.dao.VitroVocabulary"%>
<%@ page import="edu.cornell.mannlib.vitro.webapp.edit.n3editing.EditConfiguration"%>
<%@ page import="edu.cornell.mannlib.vitro.webapp.dao.WebappDaoFactory"%>
<%@ page import="edu.cornell.mannlib.vitro.webapp.controller.VitroRequest"%>
<%@ page import="edu.cornell.mannlib.vitro.webapp.web.MiscWebUtils"%>
<%@page import="edu.cornell.mannlib.vitro.webapp.edit.n3editing.StartYearBeforeEndYear"%>
<%@ page import="edu.cornell.mannlib.vitro.webapp.controller.freemarker.UrlBuilder.JavaScript" %>
<%@ page import="edu.cornell.mannlib.vitro.webapp.controller.freemarker.UrlBuilder.Css" %>

<%@ page import="org.apache.commons.logging.Log" %>
<%@ page import="org.apache.commons.logging.LogFactory" %>

<%@ taglib prefix="c" uri="http://java.sun.com/jstl/core"%>
<%@ taglib prefix="v" uri="http://vitro.mannlib.cornell.edu/vitro/tags" %>

<%! 
    public static Log log = LogFactory.getLog("edu.cornell.mannlib.vitro.webapp.jsp.edit.forms.personHasPositionHistory.jsp");
%>
<%
    VitroRequest vreq = new VitroRequest(request);
    WebappDaoFactory wdf = vreq.getWebappDaoFactory();    
    vreq.setAttribute("defaultNamespace", ""); //empty string triggers default new URI behavior
    
    request.setAttribute("stringDatatypeUriJson", MiscWebUtils.escape(XSD.xstring.toString()));
    request.setAttribute("gYearDatatypeUriJson", MiscWebUtils.escape(XSD.gYear.toString()));
%>

<c:set var="vivoCore" value="http://vivoweb.org/ontology/core#" />
<c:set var="rdfs" value="<%= VitroVocabulary.RDFS %>" />
<c:set var="label" value="${rdfs}label" />
<c:set var="positionClass" value="${vivoCore}Position" />
<c:set var="orgClass" value="http://xmlns.com/foaf/0.1/Organization" />

<%-- Define predicates used in n3 assertions and sparql queries --%>
<c:set var="titlePred" value="${vivoCore}titleOrRole" />
<c:set var="startYearPred" value="${vivoCore}startYear" />
<c:set var="endYearPred" value="${vivoCore}endYear" />
<c:set var="positionInOrgPred" value="${vivoCore}positionInOrganization" />
<c:set var="orgForPositionPred" value="${vivoCore}organizationForPosition" />

<%-- Assertions for adding a new role --%>

<v:jsonset var="orgTypeAssertion">
    ?org a ?orgType .
</v:jsonset>

<v:jsonset var="orgLabelAssertion">
    ?org <${label}> ?orgLabel .
</v:jsonset>

<v:jsonset var="positionTitleAssertion" >      
    ?position <${titlePred}> ?positionTitle ;
              <${label}> ?positionTitle . 
</v:jsonset>

<v:jsonset var="positionTypeAssertion">
    ?position a ?positionType .
</v:jsonset>

<v:jsonset var="startYearAssertion" >
    ?position <${startYearPred}> ?startYear .
</v:jsonset>

<v:jsonset var="endYearAssertion" >
    ?position <${endYearPred}> ?endYear .
</v:jsonset>

<v:jsonset var="n3ForNewPosition">       
    @prefix core: <${vivoCore}>  .   

    ?person core:personInPosition  ?position .
    
    ?position a  ?positionType ;              
              core:positionForPerson ?person ;
              <${positionInOrgPred}> ?org .
              
    ?org <${orgForPositionPred}> ?position .
</v:jsonset>

<v:jsonset var="n3ForPositionToOrg" >      
    ?position <${positionInOrgPred}> ?org .
    ?org <${orgForPositionPred}> ?position .
</v:jsonset>


<%-- Queries for editing an existing role --%>

<v:jsonset var="orgQuery" >      
    SELECT ?existingOrg WHERE {
        ?position <${positionInOrgPred}> ?existingOrg . }
</v:jsonset>

<v:jsonset var="orgLabelQuery" >      
    SELECT ?existingOrgLabel WHERE {
        ?position <${positionInOrgPred}> ?existingOrg .
        ?existingOrg <${label}> ?existingOrgLabel .
    }
</v:jsonset>

<v:jsonset var="orgTypeQuery" >      
    SELECT ?existingOrgType WHERE {
        ?position <${positionInOrgPred}> ?existingOrg .
        ?existingOrg a ?existingOrgType .
    }
</v:jsonset>

<v:jsonset var="positionTitleQuery" >  
    SELECT ?existingPositionTitle WHERE {
          ?position <${titlePred}> ?existingPositionTitle . }
</v:jsonset>

<v:jsonset var="positionTypeQuery">
    SELECT ?existingPositionType WHERE {
        ?position a ?existingPositionType . }
</v:jsonset>

<v:jsonset var="startYearQuery" >      
    SELECT ?existingStartYear WHERE {  
        ?position <${startYearPred}> ?existingStartYear . }
</v:jsonset>

<v:jsonset var="endYearQuery" >      
    SELECT ?existingEndYear WHERE {  
        ?position <${endYearPred}> ?existingEndYear . }
</v:jsonset>

<v:jsonset var="positionClassUriJson">${positionClass}</v:jsonset>
<v:jsonset var="orgClassUriJson">${orgClass}</v:jsonset>

<c:set var="requiredHint" value="<span class='requiredHint'> *</span>" />
<c:set var="yearHint" value="<span class='hint'>(YYYY)</span>" />

<%-- Configure add vs. edit --%>
<%

    String objectUri = (String) request.getAttribute("objectUri");
    if (objectUri != null) { // editing existing entry
%>
        <c:set var="editMode" value="edit" />
        <c:set var="titleVerb" value="Edit" />
        <c:set var="submitButtonText" value="Edit Position" />
        <c:set var="disabledVal" value="disabled" />
        <%-- Start year is required for an add but not an edit (so editors don't have to look up the start date in order
             to edit an existing entry with no start date). --%> 
        <c:set var="startYearRequired" value="" />
        <c:set var="startYearRequiredHint" value="" />
<% 
    } else { // adding new entry
%>
        <c:set var="editMode" value="add" />
        <c:set var="titleVerb" value="Create" />
        <c:set var="submitButtonText" value="Position" />
        <c:set var="disabledVal" value="" />
        <c:set var="startYearRequired" value="\"nonempty\"," />
        <c:set var="startYearRequiredHint" value="${requiredHint}" />
<%  } %> 



<c:set var="editjson" scope="request">
  {
    "formUrl" : "${formUrl}",
    "editKey" : "${editKey}",
    "urlPatternToReturnTo" : "/entity",

    "subject"   : ["person",    "${subjectUriJson}" ],
    "predicate" : ["predicate", "${predicateUriJson}" ],
    "object"    : ["position", "${objectUriJson}", "URI" ],
    
    "n3required"    : [ "${n3ForNewPosition}", "${positionTitleAssertion}", "${positionTypeAssertion}", 
    					"${orgLabelAssertion}", "${orgTypeAssertion}" ],
    
    "n3optional"    : [ "${startYearAssertion}", "${endYearAssertion}" ],                        
                                                                     
    "newResources"  : { "position" : "${defaultNamespace}",
                        "org" : "${defaultNamespace}" },

    "urisInScope"    : { },
    "literalsInScope": { },
    "urisOnForm"     : [ "org", "orgType", "positionType" ],
    "literalsOnForm" :  [ "positionTitle", "orgLabel", "startYear", "endYear" ],                          
    "filesOnForm"    : [ ],
    "sparqlForLiterals" : { },
    "sparqlForUris" : {  },
    "sparqlForExistingLiterals" : {
        "orgLabel"           : "${orgLabelQuery}",
        "positionTitle"      : "${positionTitleQuery}",
        "startYear"          : "${startYearQuery}",
        "endYear"            : "${endYearQuery}"
    },
    "sparqlForExistingUris" : {
        "org"               : "${orgQuery}",
        "orgType"           : "${orgTypeQuery}",
        "positionType"      : "${positionTypeQuery}"
    },
    "fields" : {
      "positionTitle" : {
         "newResource"      : "false",
         "validators"       : [ "nonempty" ],
         "optionsType"      : "UNDEFINED",
         "literalOptions"   : [ ],
         "predicateUri"     : "",
         "objectClassUri"   : "",
         "rangeDatatypeUri" : "${stringDatatypeUriJson}",
         "rangeLang"        : "",
         "assertions"       : [ "${positionTitleAssertion}" ]
      },
     "positionType" : {
         "newResource"      : "false",
         "validators"       : [ "nonempty" ],
         "optionsType"      : "CHILD_VCLASSES_WITH_PARENT",
         "literalOptions"   : [ "Select one" ],
         "predicateUri"     : "",
         "objectClassUri"   : "${positionClassUriJson}",
         "rangeDatatypeUri" : "",
         "rangeLang"        : "",
         "assertions"       : [ "${positionTypeAssertion}" ]
      },         
     "org" : {
         "newResource"      : "false",
         "validators"       : [  ],
         "optionsType"      : "INDIVIDUALS_VIA_VCLASS",
         "literalOptions"   : [ "Select one" ],
         "predicateUri"     : "",
         "objectClassUri"   : "${orgClassUriJson}",
         "rangeDatatypeUri" : "",
         "rangeLang"        : "",
         "assertions"       : [ "${n3ForPositionToOrg}" ]
      },      
      "orgLabel" : {
         "newResource"      : "false",
         "validators"       : [ "nonempty" ],
         "optionsType"      : "UNDEFINED",
         "literalOptions"   : [ ],
         "predicateUri"     : "",
         "objectClassUri"   : "",
         "rangeDatatypeUri" : "${stringDatatypeUriJson}",
         "rangeLang"        : "",         
         "assertions"       : [ "${orgLabelAssertion}" ]
      },
     "orgType" : {
         "newResource"      : "false",
         "validators"       : [ "nonempty" ],
         "optionsType"      : "CHILD_VCLASSES",
         "literalOptions"   : [ "Select one" ],
         "predicateUri"     : "",
         "objectClassUri"   : "${orgClassUriJson}",
         "rangeDatatypeUri" : "",
         "rangeLang"        : "",
         "assertions"       : [ "${orgTypeAssertion}" ]
      },      
      "startYear" : {
         "newResource"      : "false",
         "validators"       : [ ${startYearRequired} "datatype:${gYearDatatypeUriJson}" ],
         "optionsType"      : "UNDEFINED",
         "literalOptions"   : [ ],
         "predicateUri"     : "",
         "objectClassUri"   : "",
         "rangeDatatypeUri" : "${gYearDatatypeUriJson}",
         "rangeLang"        : "",         
         "assertions"       : ["${startYearAssertion}"]
      },
      "endYear" : {
         "newResource"      : "false",
         "validators"       : [ "datatype:${gYearDatatypeUriJson}" ],
         "optionsType"      : "UNDEFINED",
         "literalOptions"   : [ ],
         "predicateUri"     : "",
         "objectClassUri"   : "",
         "rangeDatatypeUri" : "${gYearDatatypeUriJson}",
         "rangeLang"        : "",         
         "assertions"       : ["${endYearAssertion}"]
      }
  }
}
</c:set>

<%
    log.debug(request.getAttribute("editjson"));

    EditConfiguration editConfig = EditConfiguration.getConfigFromSession(session,request);
    if (editConfig == null) {
        editConfig = new EditConfiguration((String) request.getAttribute("editjson"));     
        EditConfiguration.putConfigInSession(editConfig,session);
    }
    
    editConfig.addValidator(new StartYearBeforeEndYear("startYear","endYear") ); 
            
    Model model = (Model) application.getAttribute("jenaOntModel");
    
    if (objectUri != null) { // editing existing
        editConfig.prepareForObjPropUpdate(model);
    } else { // adding new
        editConfig.prepareForNonUpdate(model);
    }

    List<String> customJs = new ArrayList<String>(Arrays.asList(JavaScript.JQUERY_UI.path(),
                                                                JavaScript.CUSTOM_FORM_UTILS.path(),
                                                                "/edit/forms/js/customFormWithAutocomplete.js"                                                    
                                                               ));            
    request.setAttribute("customJs", customJs);
    
    List<String> customCss = new ArrayList<String>(Arrays.asList(Css.JQUERY_UI.path(),
                                                                 Css.CUSTOM_FORM.path(),
                                                                 "/edit/forms/css/customFormWithAutocomplete.css"
                                                                ));                                                                                                                                   
    request.setAttribute("customCss", customCss);
    
    String subjectName = ((Individual) request.getAttribute("subject")).getName();
%>

<jsp:include page="${preForm}" />

<h2>${titleVerb}&nbsp;position entry for <%= subjectName %></h2>

<form action="<c:url value="/edit/processRdfForm2.jsp"/>" >
    
    <p class="inline"><v:input type="select" label="Organization Type ${requiredHint}" name="orgType" disabled="${disabledVal}" id="typeSelector" /></p>
  
    <div class="fullViewOnly">
            
        <%-- <p> needed to create wrapper for show/hide --%>
        <p><v:input type="text" id="relatedIndLabel" name="orgLabel" label="### Name ${requiredHint}" cssClass="acSelector" disabled="${disabledVal}" size="50"  /></p>

        <%-- Store these values in hidden fields, because the displayed fields are disabled and don't submit. This ensures that when
        returning from a validation error, we retain the values. --%>
        <c:if test="${editMode == 'edit'}">
           <v:input type="hidden" id="orgType" />
           <v:input type="hidden" id="orgLabel" />
        </c:if>

        <div class="acSelection">
            <%-- RY maybe make this a label and input field. See what looks best. --%>
            <p class="inline"><label></label><span class="acSelectionInfo"></span> <a href="<c:url value="/individual?uri=" />" class="verifyMatch">(Verify this match)</a></p>
            <v:input type="hidden" id="org" cssClass="acUriReceiver" /> <!-- Field value populated by JavaScript -->
        </div>
                                
        <v:input type="text" label="Position Title ${requiredHint}" id="positionTitle" size="30" />
        <v:input type="select" label="Position Type ${requiredHint}" id="positionType" />

        <v:input type="text" label="Start Year ${startYearRequiredHint} <span class='hint'>(YYYY)</span>" id="startYear" size="4" />   
        <v:input type="text" label="End Year <span class='hint'>(YYYY)</span>" id="endYear" size="4" />
    
    </div>
       
    <p class="submit"><v:input type="submit" id="submit" value="${submitButtonText}" cancel="true"/></p>
    
    <p id="requiredLegend" class="requiredHint">* required fields</p>
</form>

<c:url var="acUrl" value="/autocomplete?tokenize=true&stem=true" />

<script type="text/javascript">
var customFormData  = {
    acUrl: '${acUrl}',
    editMode: '${editMode}',
    submitButtonTextType: 'compound' 
};
</script>
    
<jsp:include page="${postForm}"/>
