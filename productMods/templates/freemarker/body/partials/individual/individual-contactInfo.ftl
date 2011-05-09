<#-- $This file is distributed under the terms of the license in /doc/license.txt$ -->

<#-- Contact info on individual profile page -->

<#-- Email -->    
<#assign email = propertyGroups.getPropertyAndRemoveFromList("${core}email")!>      
<#if email?has_content> <#-- true when the property is in the list, even if not populated (when editing) -->
    <@p.addLinkWithLabel email editable />
    <#if email.statements?has_content> <#-- if there are any statements -->
        <ul id="individual-email" role="list">
            <#list email.statements as statement>
                <li role="listitem">
                    <img class ="icon-email middle" src="${urls.images}/individual/emailIcon.gif" alt="email icon" /><a class="email" href="mailto:${statement.value}">${statement.value}</a>
                    <@p.editingLinks "${email.localName}" statement editable />
                </li>
            </#list>
        </ul>
    </#if>
</#if>
  
<#-- Phone --> 
<#assign phone = propertyGroups.getPropertyAndRemoveFromList("${core}phoneNumber")!>
<#if phone?has_content> <#-- true when the property is in the list, even if not populated (when editing) -->
    <@p.addLinkWithLabel phone editable />
    <#if phone.statements?has_content> <#-- if there are any statements -->
        <ul id="individual-phone" role="list">
            <#list phone.statements as statement>
                <li role="listitem">                           
                   <img class ="icon-phone  middle" src="${urls.images}/individual/phoneIcon.gif" alt="phone icon" />${statement.value}
                    <@p.editingLinks "${phone.localName}" statement editable />
                </li>
            </#list>
        </ul>
    </#if>
</#if>