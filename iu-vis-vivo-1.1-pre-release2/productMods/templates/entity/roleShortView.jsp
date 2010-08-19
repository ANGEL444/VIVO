<%-- $This file is distributed under the terms of the license in /doc/license.txt$ --%>
 
<%@ taglib uri="http://java.sun.com/jstl/core" prefix="c" %>
<%@ taglib uri="http://java.sun.com/jsp/jstl/functions" prefix="fn" %>
<%@ taglib uri="http://vitro.mannlib.cornell.edu/vitro/tags/StringProcessorTag" prefix="p" %>

<%-- 
 This short view is intended to be called to handle short views for roles
 
 The following vars should be set by the jsp that is calling this short view 
 personToRolePredicate: URI of the person to role predicate.
 roleToPersonPredicate: URI of the role to person predicate. 
 roleActivityToRolePredicate: URI of the activity to role predicate. 
 roleActivityLabel: human readable label of activity.   --%>
 
<c:choose>
	<c:when test="${!empty individual}"><%-- individual is the OBJECT of the property referenced -- the Role individual, not the Person or grant --%>
        <%-- c:set var="authorRank" value="${individual.dataPropertyMap['http://vivoweb.org/ontology/core#authorRank'].dataPropertyStatements[0].data}"/ --%>
 		<c:choose>
			<c:when test="${!empty predicateUri}">
 			    <c:choose>
 			    
 			    	<%-- SUBJECT is a Person, so get info from other part of the role --%>
				    <c:when test="${predicateUri == param.personToRolePredicate}">
					    <c:choose>
                            <c:when test="${!empty individual.objectPropertyMap['http://vivoweb.org/ontology/core#roleIn']}">
					            <c:set var="roleActivity" value="${individual.objectPropertyMap['http://vivoweb.org/ontology/core#roleIn'].objectPropertyStatements[0].object}" />
					            <c:set var="name"  value="${roleActivity.name}"/>
                                <c:set var="label" value="${roleActivity.moniker}"/>
                                <c:set var="uri" value="${roleActivity.URI}"/>
                            </c:when>
 				            <c:otherwise><%-- this Role is not linked to a anything yet; use name as a placeholder and add link to the Role so user can add more information --%>
 				                <c:choose>
 				                    <c:when test="${!empty individual.name}"> 				                    	
 				                        <c:set var="name" value="${individual.name}"/>
 				                    </c:when>
 				                    <c:otherwise>
                                        <c:set var="name" value="unlabeled role"/>
                                    </c:otherwise>
 				                </c:choose>
                                <c:set var="label" >(no ${param.roleActivityLabel} linked yet)</c:set>
                                <c:set var="uri" value="${individual.URI}"/>
				            </c:otherwise>
				        </c:choose>
				    </c:when>
				    
				    <%-- SUBJECT is an activity of some sort, so get info from the Role about the related Person --%>
				    <c:when test="${predicateUri == param.roleActivityToRolePredicate}">				    				   
				    	<c:choose>
				    	
				    	    <%-- there is a related Person --%>
				    		<c:when test="${!empty individual.objectPropertyMap[ param.roleToPersonPredicate ]}">				    		
				    		    <c:set var="person" value="${individual.objectPropertyMap[ param.roleToPersonPredicate ].objectPropertyStatements[0].object}" />
					    		<c:set var="name" value="${person.name}"/>
<%--                                <c:set var="label" value="${person.dataPropertyMap['http://vivoweb.org/ontology/core#preferredTitle'].dataPropertyStatements[0].data}" />  --%>
                                <c:set var="uri" value="${person.URI}"/>
					    	</c:when>					    						    	
					    	
					    	<%-- this is a Role with out a Person (likely from before custom form available) --%>
					    	<c:otherwise>					    	
                                <c:choose>
                                    <c:when test="${!empty individual.name}"><c:set var="name" value="${individual.name}"/></c:when>
                                    <c:otherwise><c:set var="name" value="unlabeled ${param.roleActivityLabel} to person relation"/></c:otherwise>
                               </c:choose>                    
                               <c:set var="label" value="(no person linked yet)"/>
                               <c:set var="uri" value="${individual.URI}"/>
					        </c:otherwise>
					    </c:choose>
					</c:when>
					
				    <c:otherwise>				    				
				        <c:set var="name" value="unknown predicate"/>
				        <c:set var="label" value="please contact your VIVO support team"/>
				        <c:set var="uri" value="${predicateUri}"/>
				    </c:otherwise>
			    </c:choose>
			    
			    <c:choose>
			    	<c:when test="${!empty uri}">
			            <c:url var="olink" value="/entity"><c:param name="uri" value="${uri}"/></c:url>
		                <a href="<c:out value="${olink}"/>"><p:process>${name}</p:process></a> <p:process>${label}</p:process>
		            </c:when>
		            <c:otherwise>
		                <p:process><strong>${name}</strong> ${label}</p:process> 
		            </c:otherwise>
		        </c:choose>
			</c:when>
			<c:otherwise>
				<c:out value="No predicate available for custom rendering ..."/>
			</c:otherwise>
        </c:choose>
	</c:when>
	<c:otherwise>
		<c:out value="Got nothing to draw here ..."/>
	</c:otherwise>
</c:choose>
