local storageTable = { "data":[] };
local maxTableSize = 256;
local wundergroundApiKey = "INSERT KEY HERE";
local agentId = "INSERT AGENT ID HERE";

local updateCount = 0;

local settings = server.load();
// If no preferences have been saved, settings will be empty
 
if (settings.len() != 0)
{
    // Settings table is NOT empty so set the clockPrefs to the loaded table
    server.log("Loaded " + settings.data.len() + " entries from persistent storage.");
    storageTable = settings;
}

const html = @"<!DOCTYPE html>
<html lang=""en"">
    <head>
        <meta charset=""utf-8"">
        <meta name=""viewport"" content=""width=device-width, initial-scale=1, maximum-scale=1, user-scalable=0"">

        <script src=""//ajax.googleapis.com/ajax/libs/jquery/2.1.1/jquery.min.js""></script>
        <script src=""//cdnjs.cloudflare.com/ajax/libs/flot/0.8.2/jquery.flot.min.js""></script>
        <script src=""//cdnjs.cloudflare.com/ajax/libs/flot/0.8.2/jquery.flot.time.min.js""></script>
        <script src=""//cdnjs.cloudflare.com/ajax/libs/flot/0.8.2/jquery.flot.selection.min.js""></script>
        <script src=""//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/js/bootstrap.min.js""></script>
    
        <link href=""//maxcdn.bootstrapcdn.com/bootstrap/3.1.1/css/bootstrap.min.css"" rel=""stylesheet"">
        
        <style type='text/css'>
           .plot { height:300px; }
           #tooltip {opacity: 0.8; position: absolute; display: none; border: 1px solid #fdd; padding: 2px; background-color: #fef; }
        </style>

        <title>Garden Imp</title>
    </head>
    <body>
        <script type=""text/javascript"">
        var allSeries = {
            moisture1:{ label: 'Moisture 1 VWC' , data:[] },
            moisture2:{ label: 'Moisture 2 VWC' , data:[] },
            wx_relativehumidity:{ label: 'Rel. Humidity', data:[], yaxis: 2},
            tempF:{ label: 'Int. Temp F', data:[], yaxis: 3 },
            wx_tempF:{ label: 'Ext. Temp F', data:[], yaxis: 3 },

            hwlight:{ label: 'Light' , data:[] },
            hwvolts:{ label: 'Supply V' , data:[], yaxis: 2  },
        };
        
        var lastTimestamp = 0;
        
        var plots = {};
        
        $(function(){ 
            var hardwareFormat = {
                xaxis: {
					mode: 'time',
					minTickSize: [1, 'hour'],
					timezone: 'browser',
				},
    			grid: {
    				hoverable: true,
    			},
    			selection: {
    				mode: 'x'
    			},
    			yaxes: [ 
    			    { 
       			        tickFormatter: function (val, axis) {
                            return val.toFixed(2) + ' %';
                        },
    			    }, 
    			    { 
    			        position: 'right',
       			        tickFormatter: function (val, axis) {
                            return val.toFixed(2) + ' V';
                        },
                    },
    			],
            }
            
            var moistureFormat = {
                xaxis: {
					mode: 'time',
					minTickSize: [1, 'hour'],
					timezone: 'browser',
				},
                series: {
    				lines: {
    					show: true
    				},
    			},
    			grid: {
    				hoverable: true
    			},
    			selection: {
    				mode: 'x'
    			},
    			yaxes: [
    			    { 
    			        position: 'right',
       			        tickFormatter: function (val, axis) {
                            return val.toFixed(2) + ' θ';
                        },
    			    }, 
    			    { 
       			        tickFormatter: function (val, axis) {
                            return val.toFixed(2) + ' %';
                        },
    			    }, 
    			    { 
       			        tickFormatter: function (val, axis) {
                            return val.toFixed(2) + ' °F';
                        },
                    },
    			],
            };
            
            function plotZoom(event, ranges) {
                var plot = plots[event.target.id];
				$.each(plot.getXAxes(), function(_, axis) {
					var opts = axis.options;
					opts.min = ranges.xaxis.from;
					opts.max = ranges.xaxis.to;
				});
				plot.setupGrid();
				plot.draw();
				plot.clearSelection();
    		}
    		
    		function plotUnZoom(event) {
    		     var plot = plots[$(event.target).parent()[0].id];
    		     plot.setupGrid();
				 plot.draw();
				 plot.clearSelection();
    		}
            
            function tooltipHover(event, pos, item) {
                if (item) {
                    var timeMillis = item.datapoint[0]
                    var d = new Date(timeMillis);
                    
					var	y = item.datapoint[1].toFixed(2);

					$('#tooltip').html(item.series.label + ' of ' + d.toTimeString() + ' = ' + y)
						.css({top: item.pageY+5, left: item.pageX+5})
						.fadeIn(200);
                } else {
                    $('#tooltip').hide();
                }
            }

            function loopFast(){
                $.getJSON( 'https://agent.electricimp.com/'+agentId+'?dataLast', function( entry ) {
                    
                    if (entry['time'] <= lastTimestamp) {
                        return;
                    } else {
                        lastTimestamp = entry['time'];
                    }
                
                    var timeMillis = entry['time'] * 1000;
                    var d = new Date(timeMillis);
                      
                    $('#time').text(d.toTimeString());
                    $('#moisture1').text(entry['moisture1']);
                    $('#moisture2').text(entry['moisture2']);
                    $('#tempF').text(entry['tempF']);
                    $('#hwlight').text(entry['hwlight']);
                    $('#hwvolts').text(entry['hwvolts']);
                      
                    Object.keys(allSeries).forEach(function(key){
                        allSeries[key].data.push([timeMillis, entry[key]])
                    });
                    
                    plots['graph'] = $.plot($('#graph'), [allSeries['moisture1'], allSeries['moisture2'], allSeries['tempF'], allSeries['wx_tempF'], allSeries['wx_relativehumidity']], moistureFormat);
                    plots['graphHw'] = $.plot($('#graphHw'), [allSeries['hwlight'], allSeries['hwvolts']], hardwareFormat);
                      
                });
                setTimeout(loopFast, 60*1000);
            };
                
            (function load(){
                $.getJSON( 'https://agent.electricimp.com/JVeU9cMQuWZ2?dataFull', function( response ) {
                  
                    for (i = 0; i < response.length; i++) { 
                        var timeMillis = response[i]['time']*1000;
                        
                        Object.keys(allSeries).forEach(function(key) {
                            if (response[i][key]) {
                                allSeries[key].data.push([timeMillis, response[i][key]]);
                            }
                        });
                    }
                    
                    loopFast();
                 }
                );
            })();
            
            $('#graph').bind('plothover', tooltipHover);
            $('#graphHw').bind('plothover', tooltipHover);
            
            $('#graph').bind('plotselected', plotZoom);
            $('#graphHw').bind('plotselected', plotZoom);
            
            $('#graph').bind('contextmenu', plotUnZoom);
            $('#graphHw').bind('contextmenu', plotUnZoom);
            
        });
        </script>
        <div class='container-fluid'>
            <div class='row'>
                <div class='col-md-8 col-md-offset-2'>
                    <h1 class='text-center'><a href='http://saifeinc.com/iot'><img src='//saifeinc.com/static/img/logo.png' alt='SAIFE'/></a> Garden <a href='https://www.sparkfun.com/products/11395'>Imp</a></h1>
                    <p class='lead text-center'>The current status of the system...</p>
                </div>
            </div>
            <div class='row'>
                <div class='col-md-8 col-md-offset-2'>
                    <table class='table table-bordered'>
                        <tr>
                            <th>Time of Reading</th>
                            <td id='time'/>
                        </tr>
                        <tr>
                            <th><a href='http://www.vegetronix.com/Products/VG400/'>Moisture Sensor</a> 1 <small>(Tomatoes) (<a href='http://en.wikipedia.org/wiki/Water_content'>VWC</a>)</small></th>
                            <td id='moisture1'/>
                        </tr>
                        <tr>
                            <th><a href='http://www.vegetronix.com/Products/VG400/'>Moisture Sensor</a> 2 <small>(Peppers) (<a href='http://en.wikipedia.org/wiki/Water_content'>VWC</a>)</small></th>
                            <td id='moisture2'/>
                        </tr>
                        <tr>
                            <th>Internal <a href='https://www.sparkfun.com/products/10988'>Temperature</a> <small>(F)</small></th>
                            <td id='tempF'/>
                        </tr>
                        <tr>
                            <th>Light <small>(%)</small></th>
                            <td id='hwlight'/>
                        </tr>
                        <tr>
                            <th><a href='https://www.sparkfun.com/products/526'>Power Supply</a> <small>(Volts)</small></th>
                            <td id='hwvolts'/>
                        </tr>
                    </table>
                </div>
            </div>
            <div class='row'>
                <div class='col-md-offset-1 col-md-10 plot' id='graph'></div>
            </div>
            <div class='row'>
                <div class='col-md-offset-1 col-md-10 plot' id='graphHw'></div>
            </div>
            <div id='tooltip'></div>
        </div>
    </body>
</html>";
 
function requestHandler(request, response) {
    try {
        if ("dataFull" in request.query) {
            response.send(200, http.jsonencode(storageTable.data));
        } else if ("dataLast" in request.query) {
            local data = {};
            if (storageTable.data.len() > 0) {
                data = storageTable.data[storageTable.data.len()-1]
            }
            response.send(200, http.jsonencode(data));
        } else if ("dataReset" in request.query) {
            server.log("Deleting all data!");
            storageTable.data = [];
            server.save(storageTable);
            response.send(200, "Deleted everything");
        } else {
            response.send(200, html)
        }
    
    } catch (ex) {
        response.send(500, "Internal Server Error: " + ex);
    }
}

device.on("sensorUpdate", function(data){
    server.log("Received data array of size ... " + http.urlencode(data));

    local d = date(data.time - (7*60*60), "u");
    local datestring = format("%04d-%02d-%02d %02d:%02d:%02d", d.year, d.month+1, d.day, d.hour, d.min, d.sec);
    
    server.log("Time: " + datestring);
    server.log("Got temp update: " + data.tempF + " F / " + data.tempC + " C");
    
    // Sanity check
    if (
        d.year > 2013 && d.year < 2019 &&
        data.tempF > 10.0 && data.hwlight > 0
        ) {
            
        if (data.moisture1 < 0) {
            data.moisture1 = 0.0;
        }
        if (data.moisture2 < 0) {
            data.moisture2 = 0.0;
        }
        
        updateCount+=1;
        
        if (updateCount % 3 == 0) {
            // Get weather
            local uri = "http://api.wunderground.com/api/"+wundergroundApiKey+"/conditions/q/AZ/Tempe.json";
            local request = http.get(uri, {"Content-Type":"application/json"});
            local response = request.sendsync();
            local wxData = http.jsondecode(response.body);
    
            data.wx_tempF <- wxData.current_observation.temp_f;
            data.wx_relativehumidity <- split(wxData.current_observation.relative_humidity, "%")[0].tofloat();

            server.log("And now the weather... minute=" + d.min + " tempF=" + data.wx_tempF + " humidity="+data.wx_relativehumidity);
        } else {
            server.log("Skipping weather, minute=" + d.min);
        }
        
        server.log("Table length is " + storageTable.data.len() + " free " + imp.getmemoryfree());

        while(storageTable.data.len() >= maxTableSize) {
            storageTable.data.remove(0);
        }
        server.log("Table length is NOW " + storageTable.data.len() + " free " + imp.getmemoryfree());
        
        storageTable.data.push(data);
        server.save(storageTable);
    } else {
        server.log("Temperature data failed sanity check and won't be submitted... temp=" + data.tempF + 
        " time=" + data.time + " date=" + datestring + " hwlight=" + data.hwlight + 
        " moisture1=" +  data.moisture1 + " moisture2=" + data.moisture2 );
    }

    // local plotTable = {"un": "J.C.Jones", "key": "tffiwhmpl3", "origin": "plot", "platform": "electricImp", "args": 0, "kwargs": 0};
    // plotTable["kwargs"] = http.jsonencode({"filename": "Garden Monitor", "fileopt": "extend"});
    // plotTable["args"] = http.jsonencode([{"x":plotX, "y": plotYTemp, "name": "Temp F"},{"x":plotX, "y": plotYVolts, "name": "Volts"}]);

    // Debug... Print me the URLEncoding for review
    // server.log(http.urlencode(plotTable));
    
    // local request = http.post("https://plot.ly/clientresp", { }, http.urlencode(plotTable));
    // local response = request.sendsync();
    // foreach(i,j in response) { 
    //     server.log(i + " " + j); 
    // }
    
    // server.log("Server Response: " + response.body);    
});

// register the HTTP handler
http.onrequest(requestHandler);
