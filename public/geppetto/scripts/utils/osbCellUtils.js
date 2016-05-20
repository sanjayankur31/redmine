var addSuggestionsToSpotlight = function(){
	var recordSample = {
        "label": "Record all membrane potentials",
        "actions": [
            "var instances=Instances.getInstance(GEPPETTO.ModelFactory.getAllPotentialInstancesEndingWith('.v'));",
            "GEPPETTO.ExperimentsController.watchVariables(instances,true);"
        ],
        "icon": "fa-dot-circle-o"
    };
	
	var lightUpSample = {
        "label": "Link morphology colour to recorded membrane potentials",
        "actions": [
            "G.addBrightnessFunctionBulkSimplified(GEPPETTO.ModelFactory.instances.getInstance(GEPPETTO.ModelFactory.getAllPotentialInstancesEndingWith('.v'),false), function(x){return (x+0.07)/0.1;});"
        ],
        "icon": "fa-lightbulb-o"
    };
	
	GEPPETTO.Spotlight.addSuggestion(recordSample, GEPPETTO.Resources.RUN_FLOW);
	GEPPETTO.Spotlight.addSuggestion(lightUpSample, GEPPETTO.Resources.PLAY_FLOW);
};

var executeOnSelection = function(callback) {
	if (GEPPETTO.ModelFactory.geppettoModel.neuroml.cell){
		var csel = G.getSelection()[0];
		if (typeof csel !== 'undefined') {
			callback(csel);
		} else {
			G.addWidget(1).setMessage('No cell selected! Please select one of the cells and click here for information on its properties.').setName('Warning Message');
		}
	}
};
var showConnectivityMatrix = function(instance){
	if (GEPPETTO.ModelFactory.geppettoModel.neuroml.projection == undefined){
		G.addWidget(1).setMessage('No connection found in this network').setName('Warning Message');
	}else{
		G.addWidget(6).setData(instance,
				{linkType:
					function(c){
						if (GEPPETTO.ModelFactory.geppettoModel.neuroml.synapse != undefined){
							var synapseType = GEPPETTO.ModelFactory.getAllVariablesOfType(c.getParent(),GEPPETTO.ModelFactory.geppettoModel.neuroml.synapse)[0];
							if(synapseType != undefined){
								return synapseType.getId();
							}
						}
						return c.getName().split("-")[0];
					}
				}).setName('Connectivity Widget on network ' + instance.getId());
	}
};
var showChannelTreeView = function(csel) {
	if (GEPPETTO.ModelFactory.geppettoModel.neuroml.ionChannel){
		var tv = initialiseTreeWidget('Ion Channels on cell ' + csel.getName(), widthScreen - marginLeft - defaultWidgetWidth, marginTop);
		
		var ionChannel = GEPPETTO.ModelFactory.getAllTypesOfType(GEPPETTO.ModelFactory.geppettoModel.neuroml.ionChannel);
		var ionChannelFiltered = [];
		for (ionChannelIndex in ionChannel){
			var ionChannelItem = ionChannel[ionChannelIndex];
			if (ionChannelItem.getId()!='ionChannel'){
				ionChannelFiltered.push(ionChannelItem);
			}
		}
		tv.setData(ionChannelFiltered);
	}
};

var showInputTreeView = function(csel) {
	if (GEPPETTO.ModelFactory.geppettoModel.neuroml.pulseGenerator){
		var tv = initialiseTreeWidget('Inputs on ' + csel.getId(), widthScreen - marginLeft - defaultWidgetWidth, marginTop);
		var pulseGenerator = GEPPETTO.ModelFactory.getAllTypesOfType(GEPPETTO.ModelFactory.geppettoModel.neuroml.pulseGenerator);
		var pulseGeneratorFiltered = [];
		for (pulseGeneratorIndex in pulseGenerator){
			var pulseGeneratorItem = pulseGenerator[pulseGeneratorIndex];
			if (pulseGeneratorItem.getId()!='pulseGenerator'){
				pulseGeneratorFiltered.push(pulseGeneratorItem);
			}
		}
		tv.setData(pulseGeneratorFiltered);
	}
};

var showVisualTreeView = function(csel) {
	var visualWidgetWidth = 350;
	var visualWidgetHeight = 400;

	var tv = initialiseTreeWidget('Visual information on cell ' + csel.getName(), widthScreen - marginLeft - visualWidgetWidth, heightScreen - marginBottom - visualWidgetHeight, visualWidgetWidth, visualWidgetHeight);
	tv.setData(csel.getType().getVisualType(), {
		expandNodes : true
	});
};

var showSelection = function(csel) {
	var visualWidgetWidth = 350;
	var visualWidgetHeight = 400;

	var tv = initialiseTreeWidget('Cell Information - ' + csel.getName(), widthScreen - marginLeft - visualWidgetWidth, heightScreen - marginBottom - visualWidgetHeight, visualWidgetWidth, visualWidgetHeight);
	tv.setData(csel.getType(), {
		expandNodes : true
	});
};

// Commands
initialiseControlPanel();
addSuggestionsToSpotlight();


var showExecutionDialog = function(callback){
	var formCallback = callback;

	var formWidget = G.addWidget(8);
	formWidget.generateForm({experimentName:{type:'Text', title: 'Experiment Name'},timeStep:{type:'Number', title: 'Time Step (s)'},lenght:{type:'Number', title: 'Length (s)'},simulator:{type:'Select', title: 'Simulator', options: [{ val: 'neuronSimulator', label: 'Neuron' }, { val: 'lemsSimulator', label: 'jLems' }, { val: 'neuronNSGSimulator', label: 'Neuron on NSG' }]},numberProcessors:{type:'Number', title: 'Number of Processors'}}, 'Execute');
	formWidget.setData({'experimentName': Project.getActiveExperiment().getName(),timeStep: Project.getActiveExperiment().simulatorConfigurations[window.Instances[0].getId()].getTimeStep(),lenght: Project.getActiveExperiment().simulatorConfigurations[window.Instances[0].getId()].getLength(),simulator:'neuronNSGSimulator', numberProcessors: 1});

	var innerForm = formWidget.getForm();
	innerForm.on('timeStep:change', function(form, timeStep, extra) {console.log('Attribute changed to "' + timeStep.getValue() + '".');$("#experimentsOutput").find(".activeExperiment").find("td[field='timeStep']").html(timeStep.getValue());});
	innerForm.on('lenght:change', function(form, lenght, extra) {console.log('Attribute changed to "' + lenght.getValue() + '".');$("#experimentsOutput").find(".activeExperiment").find("td[field='length']").html(lenght.getValue());});
	innerForm.on('numberProcessors:change', function(form, numberProcessors, extra) {console.log('Attribute changed to "' + numberProcessors.getValue() + '".');Project.getActiveExperiment().simulatorConfigurations[window.Instances[0].getId()].setSimulatorParameter('numberProcessors', numberProcessors.getValue());});
	innerForm.on('simulator:change', function(form, simulator, extra) {console.log('Attribute changed to "' + simulator.getValue() + '".');$("#experimentsOutput").find(".activeExperiment").find("td[field='simulatorId']").html(simulator.getValue());});
	innerForm.on('submit', function(event) {event.preventDefault();console.log('Submitting');GEPPETTO.Flows.showSpotlightForRun(formCallback); formWidget.destroy();});
};

GEPPETTO.Flows.addCompulsoryAction('showExecutionDialog', GEPPETTO.Resources.RUN_FLOW);