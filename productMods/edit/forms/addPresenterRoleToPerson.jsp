<%-- $This file is distributed under the terms of the license in /doc/license.txt$ --%>


<jsp:include page="addRoleToPersonTwoStage.jsp">    
	<jsp:param name="roleActivityTypeLabel" value="presenter" />
	<jsp:param name="roleType" value="http://vivoweb.org/ontology/core#PresenterRole" />	
	
	<jsp:param name="roleActivityType_optionsType" value="HARDCODED_LITERALS" />
	<jsp:param name="roleActivityType_objectClassUri" value="" /> 
	<jsp:param name="roleActivityType_literalOptions" value='["", "Select one"], ["http://vivoweb.org/ontology/core#Presentation", "Presentation" ], [ "http://vivoweb.org/ontology/core#InvitedTalk","Invited Talk"] ' />
</jsp:include>