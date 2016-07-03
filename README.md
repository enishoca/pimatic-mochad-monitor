pimatic-mochad-simple
======================

Sends and recieves X10 commands and events to/from [pimatic](http://pimatic.org) through mochad [mochad](http://sourceforge.net/apps/mediawiki/mochad) (an X10-controller controller) for X10 devices and sensors.

#### Description
This plugin allows you to recieve and send command to/from X10 devices.

pimatic-mochad-simple gives you the abililty to monitor activity of your X-10 connected devices and sensors via RF (433 Mhz) and powerline (PL) interfaces.  Mochad already translates the X10 activity to plain text format, this plugin simply sets a device attribute to reflect the commands.  You can then use the excellent pimatic rules engine to drive other things.  

X-10 has been around forever, I have used X-10 equipment for over 20 years. and there is lot inexpensive X-10 equipment in circulation. However, mantaining true state of X-10 devices in software has always been challenging and buggy. There are also connectivity issues and endless frustration with getting the X-10 signals especially over powerline to the right devices.  There is one area where X-10 shines and that is in RF remotes and sensors, the RF remotes last forever, signal can usually cover most mid-sized houses, repeaters are abundantly available.  Their motion sensors have been time tested and battries last for a year or so. 

This plugin doesn't attempt to preserve the X10 states, simply passes the commands down to X10, and lets pimatic do the state management.

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

Configuration
------------------

#### Plugin
-----------
Under "plugins" add:

```
{
  "plugin": "mochad-simple",
  "host": "192.168.1.11",
  "port": 1099
}
```
#### Devices
------------
This plugin has two devices
 -MochadSimpleController  - used to recieve X10 commands
 -MochadSimpleSwitch  - used to send on/off commands to X10 switches and dimmers

Add them under the devices section -

```
    {
      "id": "CM15Pro",
      "name": "CM15Pro",
      "class": "MochadSimpleController"
    },   
    {
      "id": "router",
      "class": "MochadSimpleSwitch",
      "name": "Den Light",
      "housecode": "A", - X10 house code [A-P]
      "unitcode": 1,    - X10 unit code [1-16]
      "protocol": "rf"  - X10 protocol rf/pl
    }
```

The MochadSimpleController device is used to recieve X10 commands - this device exposes attribute 'lastX10Message' which contains the last X10 command. This attribute can then be used in rules.  
The format of data in 'lastX10Message' attribute is a string: 
 - Individual units - [housecode][unitcode]-[on/off] 
 - All lights       - [housecode]-[on/off]


#### Rules Examples

``` 
  "when lastX10Message of CM15Pro equals \"b1-on\" then turn Bedroom Fan on"
  "when lastX10Message of CM15Pro equals \"b1-off\" then turn Bedroom Fan off"
  "when lastX10Message of CM15Pro equals \"b-off\" then turn All Lights off"
 
```

Some interesting lines from mochad logs
 
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


