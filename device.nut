hardware.pin2.configure(ANALOG_IN);
hardware.pin5.configure(ANALOG_IN);
hardware.pin7.configure(ANALOG_IN);

local temperatureReadings = 0;
local temperatureV = null;
local temperatureC = null;
local temperatureF = null;

local moisture1Readings = 0;
local moisture1VWC = null;

local moisture2Readings = 0;
local moisture2VWC = null;

local hwlightReadings = 0;
local hwlightPercent = null

local hwvoltsReadings = 0;

local submitDeltaSeconds = 1;

function map(x, in_min, in_max, out_min, out_max) {
    return (x - in_min) * (out_max - out_min) / (in_max - in_min) + out_min;
}

function vh400(reading) {
    // http://www.vegetronix.com/Curves/VH400-RevA/VG400-RevA-Curves.phtml
    // 65535 = 3300mV
    
    local mV = map(reading, 0, 65535, 0, 3300);
    
    if ((0 <= mV) && (mV < 1100)) {
        return 10*mV-1000;
    } else if ((1100 <= mV) && (mV < 1300)) {
        return 25*mV-17500;
    } else if ((1300 <= mV) && (mV < 1820)) {
        return 48.08*mV-47500;
    } else if ((1820 <= mV) && (mV < 2200)) {
        return 26.32*mV-7890;
    } else {
        // Cap at 51?
        return 26.32*mV-7890;
    }
}

function logData() {
    // get the raw voltage value from temp sensor btw 0-65535
    // in this case that needs mapping to the range 0-3.3V
    
    local samples = 10

    // First smooth the data
    for(local i=0; i<samples; i+=1) {
        temperatureReadings += hardware.pin2.read();
        moisture1Readings += hardware.pin5.read();
        moisture2Readings += hardware.pin7.read();
        hwlightReadings += hardware.lightlevel();
        hwvoltsReadings += hardware.voltage();
        imp.sleep(0.5);
        
        // server.log(i + " temp " + temperatureReadings);
        // server.log(i + " m1 " + moisture1Readings);
        // server.log(i + " m2 " + moisture2Readings);
    }
    
    temperatureReadings /= samples;
    moisture1Readings /= samples;
    moisture2Readings /= samples;
    hwlightReadings /= samples;
    hwvoltsReadings /= samples;
    
    // server.log("F temp " + temperatureReadings);
    // server.log("F m1 " + moisture1Readings);
    // server.log("F m2 " + moisture2Readings);
    
    
    temperatureV = map(temperatureReadings, 0, 65535, 0, 3300);
    moisture1VWC = vh400(moisture1Readings) / 1000.0;
    moisture2VWC = vh400(moisture2Readings) / 1000.0;
    
    hwlightPercent = map(hwlightReadings, 0, 65535, 0, 100);

    server.log("Moisture 1 " + moisture1Readings + " -> " + moisture1VWC);
    server.log("Moisture 2 " + moisture2Readings + " -> " + moisture2VWC);
    
  
    // get temperature in degrees Celsius
    temperatureC = (temperatureV - 500) / 10.0;
  
    // convert to degrees Farenheit
    temperatureF = (temperatureC * 9.0 / 5.0) + 32.0;
    
    local data = {
        "time": time(), 
        "tempF": temperatureF, 
        "tempC": temperatureC, 
        "moisture1": moisture1VWC, 
        "moisture2": moisture2VWC, 
        "hwvolts": hwvoltsReadings, 
        "hwlight": hwlightPercent,
    };
    
    agent.send("sensorUpdate", data);  
}


// Run when idle
function idle() {
    server.log("On idle");
    
    local t = time();
    local d = date(t, "u"); // Local time

    // Find the info
    logData();

  
    // If it's been more than an hour, send the temps
    // if (t - nv.lastSubmit > submitDeltaSeconds) {
        // sendData();
    // }
    
    // imp.wakeup(60, idle);
    
    
    
    local sleepSeconds = null;
    // Wake up periodically
    if (d.hour >= 7 && d.hour < 14) {
        // Midnight to 7 AM -- 30 minutes
        sleepSeconds = 360;
    } else {
        // Daytime -- 1 minute
        sleepSeconds = 180;
    }

    server.log("Sleeping for "+sleepSeconds+" seconds.");
    server.sleepfor(sleepSeconds);
};

// Initialize NV table, if not initalized
if (!("nv" in getroottable())) {
    nv <- { table = [], lastSubmit = 0 };
}

// When done, call the idle func
imp.onidle(idle);
