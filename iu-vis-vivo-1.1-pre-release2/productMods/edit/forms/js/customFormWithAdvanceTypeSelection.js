/* $This file is distributed under the terms of the license in /doc/license.txt$ */

var customForm = {
    
    /* *** Initial page setup *** */
   
    onLoad: function() {
        this.mixIn();
        this.initObjects();                 
        this.initPage();       
    },

    mixIn: function() {
        // Mix in the custom form utility methods
        $.extend(this, vitro.customFormUtils);

        // Get the custom form data from the page
        $.extend(this, customFormData);
    },
    
    // On page load, create references for easy access to form elements.
    // NB These must be assigned after the elements have been loaded onto the page.
    initObjects: function(){
        
        this.form = $('#content form');
        this.fullViewOnly = $('#fullViewOnly');
        this.button = $('#submit');
        this.baseButtonText = this.button.val();
        this.requiredLegend = $('#requiredLegend');
        this.typeSelector = this.form.find('#typeSelector');

        // These are classed rather than id'd in case we want more than one autocomplete on a form.
        // At that point we'll use ids to match them up with one another.
        this.acSelector = this.form.find('.acSelector');
        this.acSelection = this.form.find('.acSelection');
        this.acSelectionInfo = this.form.find('.acSelectionInfo');
        this.acReceiver = this.form.find('.acReceiver');
        this.verifyMatch = this.form.find('.verifyMatch');    
        this.verifyMatchBaseHref = this.verifyMatch.attr('href');    
        this.acSelectorWrapper = this.acSelector.parent();
        
        // This is the label element for the field with name 'label'
        this.labelFieldLabel = $('label[for=' + $('#label').attr('id') + ']');       
        // Get this on page load, so we can prepend to it. We can't just prepend to the current label text,
        // because it may have already been modified for a previous selection.
        this.baseLabelText = this.labelFieldLabel.html();
        
        this.or = $('span.or');       
        this.cancel = this.form.find('.cancel');

    },

    // Set up the form on page load
    initPage: function() {

        if (!this.typeSelector.length) {
            this.formSteps = 1;
        // there's also going to be a 3-step form - look for this.subTypeSelector
        } else {
            this.formSteps = 2;
        }
                
        this.bindEventListeners();
        
        this.initAutocomplete();
        
        this.initFormView();

    },
    
    initFormView: function() {
        
        var typeVal = this.typeSelector.val();   
        
        if (this.formSteps == 1 || this.findValidationErrors()) {
            this.initFormFullView();
        }
        // If type is already selected when the page loads (Firefox retains value
        // on a refresh), go directly to full view. Otherwise user has to reselect
        // twice to get to full view.
        else if (typeVal.length) {
            this.acType = typeVal;
            this.setLabelFieldLabel();
            this.initFormFullView();
        }
        else {
            this.initFormTypeView();
        }     
    },
    
    initFormTypeView: function() {
  
        this.hideFields(this.fullViewOnly);
        this.button.hide();
        this.requiredLegend.hide();
        this.or.hide();

        this.cancel.unbind('click');
    },
    
    initFormFullView: function() {

        this.fullViewOnly.show();
        this.or.show();
        this.requiredLegend.show();
        this.button.show();
        this.button.val('Create ' + this.baseButtonText);
        this.cancel.unbind('click');     
           
        if( this.formSteps > 1 ){

            this.cancel.click(function() {
                customForm.clearFormData(); // clear any input and validation errors
                customForm.initFormTypeView();
                return false;            
            });
        }
    },
    
    // Bind event listeners that persist over the life of the page.
    bindEventListeners: function() {
        
        this.typeSelector.change(function() {
            var typeVal = $(this).val();
            
            // If an autocomplete selection has been made, undo it
            customForm.undoAutocompleteSelection();
            
            // Set the type of individual that the autocomplete will search for.
            // We do this even if typeVal is empty, to clear out a previous value.
            customForm.acType = typeVal;
            
            if (typeVal.length) {    
                customForm.setLabelFieldLabel();            
                customForm.initFormFullView();            
            } else {
                // If no selection, go back to type view. This prevents problems like trying to run autocomplete
                // or submitting form without a type selection.
                customForm.initFormTypeView();
            }     
        }); 
        
        this.verifyMatch.click(function() {
            window.open($(this).attr('href'), 'verifyMatchWindow', 'width=640,height=640,scrollbars=yes,resizable=yes,status=yes,toolbar=no,menubar=no,location=no');
            return false;
        });      
    },
    
    initAutocomplete: function() {
        
        this.getAcFilter();
        this.acCache = {};
        
        this.acSelector.autocomplete({
            minLength: 3,
            source: function(request, response) {
                if (request.term in customForm.acCache) {
                    // console.log('found term in cache');
                    response(customForm.acCache[request.term]);
                    return;
                }
                // console.log('not getting term from cache');

                $.ajax({
                    url: customForm.acUrl,
                    dataType: 'json',
                    data: {
                        term: request.term,
                        type: customForm.acType,
                    },
                    complete: function(xhr, status) {
                        // Not sure why, but we need an explicit json parse here. jQuery
                        // should parse the response text and return a json object.
                        var results = $.parseJSON(xhr.responseText), 
                            filteredResults = customForm.filterAcResults(results);
                        customForm.acCache[request.term] = filteredResults;
                        response(filteredResults);
                    }

                });
            },
            select: function(event, ui) {
                customForm.showAutocompleteSelection(ui);   
                    
            }
        });

    },
    
    getAcFilter: function() {
        // Define this.acFilter here, so in case the sparql query fails
        // we don't get an error when referencing it later.
        this.acFilter = [];
        $.ajax({
            url: customForm.sparqlQueryUrl,
            data: {
                resultFormat: 'RS_JSON',
                query: customForm.sparqlForAcFilter
            },
            success: function(data, status, xhr) {
                // Not sure why, but we need an explicit json parse here. jQuery
                // should parse the response text and return a json object.
                customForm.setAcFilter($.parseJSON(data));
            }
        });
    },
    
    setAcFilter: function(data) {
        var key = data.head.vars[0];
        
        $.each(data.results.bindings, function() {
            customForm.acFilter.push(this[key].value);
        });         
    },
    
    filterAcResults: function(results) {
        var filteredResults;
        
        if (!this.acFilter.length) {
            return results;
        }
        
        filteredResults = [];
        $.each(results, function() {
            if ($.inArray(this.uri, customForm.acFilter) == -1) {
                // console.log("adding " + this.label + " to filtered results");
                filteredResults.push(this);
            }
            else {
                // console.log("filtering out " + this.label);
            }
        });
        return filteredResults;
    },

    // Reset some autocomplete values after type is changed
    resetAutocomplete: function(typeVal) {
        // Append the type parameter to the base autocomplete url
        var glue = this.baseAcUrl.indexOf('?') > -1 ? '&' : '?';
        this.acUrl = this.baseAcUrl + glue + 'type=' + typeVal;
        
        // Flush autocomplete cache when type is reset, since the cached values 
        // pertain only to the previous type.
        this.acCache = {};
    },       
        
    showAutocompleteSelection: function(ui) {
        
        var uri = ui.item.uri;
        
        this.acSelectorWrapper.hide();
        this.acSelector.attr('disabled', 'disabled');
        
        // If only one form step, type is pre-selected, and this label is coded in the html.
        if (this.formSteps > 1) {
            this.acSelection.find('label').html('Selected ' + this.getSelectedTypeName() + ':');
        }
              
        this.acSelection.show();

        this.acReceiver.val(uri);
        this.acSelectionInfo.html(ui.item.label);
        this.verifyMatch.attr('href', this.verifyMatchBaseHref + uri);
        
        this.button.val('Add ' + this.baseButtonText);               

        this.cancel.unbind('click');
        this.cancel.click(function() {
            customForm.undoAutocompleteSelection();
            customForm.initFormFullView();
            return false;
        });
    },
    
    // Cancel action after making an autocomplete selection: undo autocomplete 
    // selection (from showAutocomplete) before returning to full view.
    undoAutocompleteSelection: function() {
        
        this.acSelectorWrapper.show();
        this.acSelector.attr('disabled', '');
        this.acSelector.val('');
        this.hideFields(this.acSelection);
        this.acReceiver.val('');
        this.acSelectionInfo.html('');
        this.verifyMatch.attr('href', this.verifyMatchBaseHref);
        this.button.val('Create ' + this.baseButtonText)
        
        if (this.formSteps > 1) {
            this.acSelection.find('label').html('Selected ');
        }
                
    },
    
    getSelectedTypeName: function() {
        return this.typeSelector.find(':selected').html();
    },
    
    setLabelFieldLabel: function() {
        this.labelFieldLabel.html(this.getSelectedTypeName() + ' ' + this.baseLabelText);        
    }
    
};

$(document).ready(function() {   
    customForm.onLoad();
});
