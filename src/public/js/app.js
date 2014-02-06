function createChart(seriesOptions, config) {

	chart = new Highcharts.StockChart({
		chart: {
			renderTo: 'io-graph',
			borderColor: "black",
			borderWidth: 2,
			borderRadius: 10
		
		},
		credits: {
			enabled : false
		},
		title : {
			text : config['title']
		},
		rangeSelector: {
			enabled: false
		},
		navigator : {
			enabled: true
		},
		scrollbar : {
			enabled: false
		},
		legend : {
			layout : "vertical",
			enabled : true,
			floating : true,
			backgroundColor : '#FFFF33',
			align: "right",
			verticalAlign : "top	"
		},
		exporting : {
			enabled : false
		},
		
		yAxis: [{
			endOnTick : false,
			startOnTick : false,
			showLastLabel : true,
			opposite: true,
			title: {
				text: config['right_axis_legend']
			},
			/*labels: {
				formatter: function() {
					return (this.value > 0 ? '+' : '') + this.value / 1000000 + 'm';
				}
			},*/
			plotLines: [{
				value: 0,
				width: 2,
				color: 'blue'
			}]
		},
		{
			endOnTick : false,
			startOnTick : false,
			showLastLabel : true,
			opposite: false,
			title: {
				text: config['left_axis_legend']
			},
			
			/*labels: {
				formatter: function() {
					return (this.value > 0 ? '+' : '') + this.value / 1000000 + 'm';
				}
			},*/
			plotLines: [{
				value: 0,
				width: 2,
				color: 'silver'
			}]
		}],			
		
					
		tooltip: {
			pointFormat: '<span style="color:{series.color}">{series.name}</span>: <b>{point.y}</b><br/>',
			valueDecimals: 0
		},
		
		series: seriesOptions
	});
}

function get_url_arguments(){
	var params = {};
	var queryString=window.location.search.substring(1);
	var field_values = queryString.split('&');
	for(var i=0;i<field_values.length;i++){
		field_value = field_values[i].split("=");
		params[field_value[0]] = field_value[1];
	}	
	return params;
}

function element_name_to_title(string){
	var strings = string.split("-");
	var new_strings = [];
	for(i=0;i<strings.length;i++){
			var s = strings[i];
			new_strings.push(s.substring(0,1).toUpperCase()+s.substring(1));			
	}
	return new_strings.join(" ");
}