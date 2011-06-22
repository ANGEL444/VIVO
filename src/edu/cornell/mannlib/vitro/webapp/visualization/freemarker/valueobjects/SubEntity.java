/* $This file is distributed under the terms of the license in /doc/license.txt$ */
package edu.cornell.mannlib.vitro.webapp.visualization.freemarker.valueobjects;

import java.util.HashMap;
import java.util.Map;
import java.util.Set;
import java.util.HashSet;

import org.apache.commons.lang.WordUtils;

/**
 * @author bkoniden
 * Deepak Konidena
 */
public class SubEntity extends Individual {

	Set<BiboDocument> publications = new HashSet<BiboDocument>();
	Map<String, Map<String, String>> personToPositionAndStartYear = new HashMap<String, Map<String, String>>(); 
	Set<Grant> grants = new HashSet<Grant>();
	
	
	public SubEntity(String individualURI) {
		super(individualURI);
	}
	
	public Map<String, Map<String, String>> getPersonToPositionAndStartYear() {
		return personToPositionAndStartYear;
	}

	public void setPersonToPositionAndStartYear(
			Map<String, Map<String, String>> personToPositionAndStartYear) {
		this.personToPositionAndStartYear = personToPositionAndStartYear;
	}

	public Set<BiboDocument> getDocuments() {
		return publications;
	}

	public Set<Grant> getGrants() {
		return grants;
	}
	
	public SubEntity(String individualURI, String individualLabel) {
//		super(individualURI, WordUtils.capitalizeFully(individualLabel));
		super(individualURI, (individualLabel));
	}
	
	@Override
	public boolean equals(Object other){
		boolean result = false;
		if (other instanceof SubEntity){
			SubEntity person = (SubEntity) other;
			result = (this.getIndividualLabel().equals(person.getIndividualLabel())
						&& this.getIndividualURI().equals(person.getIndividualURI()));
		}
		return result;
	}
	
	@Override 
	public int hashCode(){
		return(41*(getIndividualLabel().hashCode() + 41*(getIndividualURI().hashCode())));
	}
	
	@Override
	public String toString(){
		return this.getIndividualLabel();
	}
	
	public void addPublication(BiboDocument biboDocument) {
		this.publications.add(biboDocument);
	}


	public void addGrant(Grant grant) {
		this.grants.add(grant);
	}
}
