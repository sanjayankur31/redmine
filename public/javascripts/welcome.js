$(document).ready(function() {

    callGeppetto("", addDashboard, true);

    $('a[data-toggle="tab"]').on('shown.bs.tab', function (e) {

        var target = $(e.target).attr("href") // activated tab
        switch(target){
        case "#workspace":
	    hideFooter();
    	    break;
        case "#netpyne":
            hideFooter();
            break;
        case "#nwbexplorer":
            hideFooter();
            break;
        default:
    	    showFooter();
    	    break;
        }
    });

});
