var express = require('express');
var dht = require('node-dht-sensor');
var fs = require('fs');
var https = require('https');
var noble = require('noble');
var app = express();

const LOCK_SERVICE_UUID = "4fafc2011fb5459e8fccc5c9c331914b";
const BATT_SERVICE_UUID = "0af2d54c4d334fc79e34823b02c294d5";
const LOCK_CHARACTERISTIC_UUID = "beb5483e36e14688b7f5ea07361b26a8";
const BATT_CHARACTERISTIC_UUID = "134c298f7d6b4f6484968965e0851d03";
const PERIPHERAL_NAME = "IOTDoor";

var sslOptions = {
	key: fs.readFileSync('express.key'),
	cert: fs.readFileSync('express.crt'),
	csr: fs.readFileSync('express.csr')
};

var savedPeripheral;
var response;

var batteryStatus;
var doorStatus;
var lastUpdateTime;

const date = new Date();


//app.use(express.static(__dirname, { dotfiles: 'allow' } ));

app.get('/', function (req, res) {
    //res.send('Hello World');
    res.json({
    	'response': "Hello World!"
    });
});

https.createServer(sslOptions, app).listen(4443);

app.listen(80);

app.get('/temperature', function (req, res) {
	dht.read(22, 21, function(err, temperature, humidity) {
		res.type('json');
		if (!err) {
			res.json({
				'temperature': temperature.toFixed(1),
				'humidity':  humidity.toFixed(1)
			});
		} else {
			res.status(500).json({error: 'Could not access sensor'});
		}
	});
});

app.post('/door/connect', function (req, res) {
	console.log("start connect");
	response = res;
	noble.startScanning();
});


app.post('/door/disconnect', function (req, res) {

	noble.stopScanning();
	console.log("stop scan");
	if (savedPeripheral) {
		console.log('disconnected');
		savedPeripheral.disconnect();
		savedPeripheral = null;
	}
	res.json({
		'status': 'disconnected'
	});
});

app.get('/door/status', function (req, res) {
  console.log("start connect");
  if (savedPeripheral) {
    res.json({
      'doorStatus': doorStatus,
      'batteryStatus': batteryStatus,
      'lastUpdateTime': lastUpdateTime,
      'ping': 'pong'
    });
  } else {
    res.status(500).json({error: 'Not connected to a sensor. Please re-connect and try again.'});
  }
});

//BLE support

noble.on('discover', function(peripheral) {
  console.log("discovered");
  console.log("peripheral name "+peripheral.id+" "+peripheral.address + " | " + peripheral.advertisement.localName);

  var advertisement = peripheral.advertisement;
  if (PERIPHERAL_NAME == advertisement.localName) {
    noble.stopScanning();

    console.log('peripheral with name ' + advertisement.localName + ' found');

    console.log('attempting to connect');
    connect(peripheral);
  }
});


function connect(peripheral) {

  	peripheral.connect(function(error) {

  		if (error) {
  			console.log('error = ' + error);
  			response.status(500).json({error: 'Could not find sensor'});

  		} else {
  			console.log('connected');

  			response.json({'status': 'connected'});

  			savedPeripheral = peripheral;

        	discoverServices();
  		}
  	});
}

function discoverServices() {
  if (savedPeripheral) {
  	console.log('begin discovering services');
    savedPeripheral.discoverAllServicesAndCharacteristics(function(error, services,  characteristics) {

          if (error) {
            console.log('error  = ' + error);
          }

          console.log('characteristics = ' + characteristics);
          console.log('services = ' + services);

          for (characteristic in characteristics) {
          	console.log('characteristic = ' + characteristic);
             if (characteristic.uuid == LOCK_CHARACTERISTIC_UUID || characteristic.uuid == BATT_CHARACTERISTIC_UUID)  {
                console.log('found a match' + characteristic.uuid);
                observeCharacteristic(characteristic);
             }
          }
    });
  }
}

function observeCharacteristic(characteristic) {

  //Fires when data comes in 
  characteristic.on('data', (data, isNotification) => {
    console.log('data: "' + data + '"');
    lastUpdateTime = date.getTime();

    if (characteristic.uuid == BATT_CHARACTERISTIC_UUID) {
        batteryStatus = data;
    }

    if (characteristic.uuid == LOCK_CHARACTERISTIC_UUID) {
        doorStatus = data;
    }
  });
  
  //Used to setup subscription
  characteristic.subscribe(error => {
    if (error) {
      console.log('error setting up subscription = ' + error + 'for uuid:' + characteristic.uuid);
    } else {
      console.log('subscription successful for uuid:' + characteristic.uuid);
    }
  });

}