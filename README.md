pimatic-mochad-monitor
======================

Connects [pimatic](http://pimatic.org) to [mochad](http://sourceforge.net/apps/mediawiki/mochad) (an X10-controller controller) and monitors all X10 devices and sensors.

#### Description

pimatic-mochad-monitor gives you the abililty to monitor activity of your X-10 connected devices and sensors via RF (433 Mhz) and powerline (PL) interfaces.  Mochad already translates the X10 activity to plain text format, this plugin simply listens to Mochad and logs that activity to a file. You can then use the [pimatic-log-reader](https://pimatic.org/plugins/pimatic-log-reader) plugin to parse the log and create devices and attributes and use the excellent pimatic rules engine to drive other things.

X-10 has been around forever, I have used X-10 equipment for over 20 years. and there is lot inexpensive X-10 equipment in circulation. However, mantaining true state of X-10 devices in software has always been challenging and buggy. There are also connectivity issues and endless frustration with getting the X-10 signals especially over powerline to the right devices.  There is one area where X-10 shines and that is in RF remotes and sensors, the RF remotes last forever, signal can usually cover most mid-sized houses, repeaters are abundantly available.  Their motion sensors have been time tested and battries last for a year or so.

Examples:
 - Use inexpensive X-10 rf remotes to control devices
 - Use X-10 motion sensors and integrate them to trigger other devices or log the data

#### Hardware schematic

```
                                       RF Antenna (433 Mhz)
          
                                       \ /           \ /
           Network                    - o -         - o -
 +---------+     +---------+   USB      |             |   
 | RPi     |-----| RPi [1] |════════╗   |             `-- X10 devices (sensors, remotes, ..)
 | Pimatic |     | Mochad  |        ║   |                         
 +---------+     +---------+       +-----+                        
                                   |     |
          _OR_                     | X10 |
                                   |     |
 +-------------+     USB           |     |
 | RPi Pimatic |═══════════════════|     | X10 controllor (CM15A/CM19A/CM15Pro)
 | and Mochad  |                   +-----+
 +-------------+                     |  
                                     `----- Powerline ------> X10 devices 
                                                              (switches, dimmers, blinds, ..)
                                     
 [1] Or even OpenWrt (, etc) running Mochad                                    
```

#### Configuration

Under "plugins" add:

```
{
  "plugin": "mochad-monitor"
}
```

Add the following under "devices":

```
{
  "id": "CM15Pro",
  "class": "MochadMonitor",
  "name": "CM15Pro",
  "host": "192.168.1.11",
  "port": 1099,
  "logfile:" "/var/logs/mochad.log"
}   
```

#### Usage Example

Turn the hallway light on/off based on motion sensor X-10 device I-1:

Add the following under devices - make sure pimatic-log-reader plugin has been installed, and you have verified that the mochad-monitor is successfully logging to the file.

```
    {
      "id": "hall-motion-sensor",
      "name": "Hall Sensor",
      "class": "LogWatcher",
      "file": "/var/logs/mochad.log",
      "attributes": [
        {
          "name": "TriggerState",
          "type": "boolean",
          "labels": [
            "switched on",
            "switched off"
          ]
        }
      ],
      "lines": [
        {
          "match": "HouseUnit: I1 Func: On",
          "Presence": true
        },
        {
          "match": "HouseUnit: I1 Func: Off",
          "Presence": false
        }
      ]
    },
```

Add the following rules 

``` 
  "when TriggerState of hall-motion-sensor is switched on then turn hall on"
 
  "when TriggerState of hall-motion-sensor is switched off then turn hall off",

```

Some interesting lines from mochad logs

Respone to 'st' command to check status (mochad only remember status of commands it has seen, may not be true status of devices)
```  
          # 06/04 21:50:55 Device status
          # 06/04 21:50:55 House A: 1=1
          # 06/04 21:50:55 House P: 1=1,2=0,3=1,4=0,5=1,6=0,7=0,8=0,9=0,10=0,11=0,12=0,13=0,14=0,15=0,16=0
          # 06/04 21:50:55 Security sensor status

```

Handling all-units-on/off
```
          #  example: 05/22 00:34:04 Rx PL House: P Func: All units on
          #  example: 05/22 00:34:04 Rx PL House: P Func: All units off
          # example2: 00:04:29.391 [pimatic-mochad] 09/02 00:04:29 Rx PL House: P Func: All units off
          # example2: 00:04:29.391 [pimatic-mochad]>
```

Handling simple on/off (RF-style)
``` 
          # 11/30 17:57:12 Tx RF HouseUnit: A10 Func: On
          # 11/30 17:57:24 Tx RF HouseUnit: A10 Func: Off
```
Handling simple on/off (PL-style)
```
          #  example: 05/30 20:59:20 Tx PL HouseUnit: P1
          #  example: 05/30 20:59:20 Tx PL House: P Func: On
          #  example2: 23:42:03.196 [pimatic-mochad] 09/01 23:42:03 Tx PL HouseUnit: P1
          #  example2: 23:42:03.196 [pimatic-mochad]>
          #  example2: 23:42:03.198 [pimatic-mochad] 09/01 23:42:03 Tx PL House: P Func: On
```
 
#### Credits

This plugin has been derived from [pimatic-mochad](https://pimatic.org/plugins/pimatic-mochad) plugin by [Patrick Kuijvenhoven](https://github.com/petski)  


