# MochadSimple plugin

module.exports = (env) ->
  Promise = env.require 'bluebird'

  # Require the [cassert library](https://github.com/rhoot/cassert).
  assert = env.require 'cassert'
  reconnect = require 'reconnect-net'

  _ = env.require 'lodash'

  # the plugin class
  class MochadSimplePlugin extends env.plugins.Plugin

    init: (app, @framework, config) ->
      env.logger.debug "MochadSimple: init"
      @connection = null
      host = config.host
      port = config.port

      env.logger.debug(
        "MochadSimple: init with mochad server #{host}@port #{port}"
      )

      @cmdReceivers = []
      deviceConfigDef = require("./device-config-schema")

      deviceClasses = [
        MochadSimpleController,
        MochadSimpleSwitch
      ]

      for Cl in deviceClasses
        do (Cl) =>
          @framework.deviceManager.registerDeviceClass(Cl.name, {
            configDef: deviceConfigDef[Cl.name]
            createCallback: (deviceConfig) =>
              device = new Cl(deviceConfig)
              if Cl in [MochadSimpleController]
                @cmdReceivers.push device
              return device
          })


      reconnector = reconnect(((conn) ->
        # XXX Keep alive does not work [as expected](https://github.com/joyent/node/issues/6194)
        conn.setKeepAlive(true, 0)
        conn.setNoDelay(true)

        conn.on 'data', ((data) ->
          lines = data.toString()
          env.logger.debug(lines)
          @receiveCommandCallback(lines)
        ).bind(@)
      ).bind(@)).connect(port, host);

      reconnector.on 'connect', ((connection) ->
        env.logger.debug("(re)Opened connection")
        @connection = connection
      ).bind(@)

      reconnector.on 'disconnect', ((err) ->
        env.logger.error("Disconnected from #{@host}:#{@port}: " + err)
        @connection = null;
      ).bind(@)

    sendCommand: (command) ->
      if @connection is null then throw new Error("No connection!")
      env.logger.debug("Sending '#{command}'")
      @connection.write(command + "\r\n")


    receiveCommandCallback: (cmdString) =>
      for cmdReceiver in @cmdReceivers
        handled = cmdReceiver.handleReceivedCmd cmdString
        break if handled

      if (!handled)
        env.logger.debug "received unhandled command string: #{cmdString}"

 
  # MochadSimpleSwitch sends commands to X.10 devices
  class MochadSimpleSwitch extends env.devices.PowerSwitch

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @housecode = @config.housecode
      @unitcode = @config.unitcode
      @protocol = @config.protocol
      super()

    changeStateTo: (state) ->
      return Promise.try( =>
        @sendCommand
        plugin.sendCommand ("#{@protocol} #{@housecode}#{@unitcode} " + ( if state then "on" else "off" ))
        @_setState state
      )
      .catch((error) -> env.logger.error("Couldn't send command '#{command}': " + error))

  class MochadSimpleController extends env.devices.ButtonsDevice

    attributes:
      lastX10Message:
        description: "Contains the last X10 message recieved"
        type: "string"

    _lastX10Message = ""

    constructor: (@config) ->
      @_lastSeen = {
        housecode: "x"
        unitcode: "0"
      }
      super(@config)

    getLastX10Message : () ->
      return Promise.resolve(@lastX10Message)

    handleReceivedCmd: (lines) ->

      # Parsing all-units-on/off
      # example: 05/22 00:34:04 Rx PL House: P Func: All units on
      # example: 05/22 00:34:04 Rx PL House: P Func: All units off
      if m = /^\d{2}\/\d{2}\s+(?:\d{2}:){2}\d{2}\s(Rx|Tx)\s+(RF|PL)\s+House:\s+([a-pA-P])\s+Func:\s+All\s+(units|lights)\s+(on|off)$/m.exec(lines)
        event = {
          protocol:  m[2].toLowerCase()
          direction: m[1].toLowerCase()
          housecode: m[3].toLowerCase()
          unitcode:  "*" + m[4]
          state:     m[5].toLowerCase()
        }
        env.logger.debug("Event: " + JSON.stringify(event))
        @_lastX10Message = event.housecode + "-" + event.state 
        @emit "lastX10Message", @_lastX10Message
        env.logger.debug("House #{event.housecode} unit #{unitcode} has state #{event.state}");
       
      # Parsing simple on/off (RF-style)
      # 11/30 17:57:12 Tx RF HouseUnit: A10 Func: On
      # 11/30 17:57:24 Tx RF HouseUnit: A10 Func: Off
      if m = /^\d{2}\/\d{2}\s+(?:\d{2}:){2}\d{2}\s(Rx|Tx)\s+(RF|PL)\s+HouseUnit:\s+([a-pA-P])(\d{1,2})\s+Func:\s+(On|Off)/m.exec(lines) 
        event = {
          protocol:  m[2].toLowerCase()
          direction: m[1].toLowerCase()
          housecode: m[3].toLowerCase()
          unitcode:  parseInt(m[4], 10)
          state:     m[5].toLowerCase()
        }
        env.logger.debug("Event: " + JSON.stringify(event))
        @_lastX10Message = event.housecode + event.unitcode + "-" + event.state 
        @emit "lastX10Message", @_lastX10Message   

      # Parsing simple on/off (PL-style)
      #  example: 05/30 20:59:20 Tx PL HouseUnit: P1
      #  example: 05/30 20:59:20 Tx PL House: P Func: On
      #  example2: 23:42:03.196 [pimatic-mochad] 09/01 23:42:03 Tx PL HouseUnit: P1
      #  example2: 23:42:03.196 [pimatic-mochad]>
      #  example2: 23:42:03.198 [pimatic-mochad] 09/01 23:42:03 Tx PL House: P Func: On
      else if m = /^\d{2}\/\d{2}\s+(?:\d{2}:){2}\d{2}\s(?:Rx|Tx)\s+(?:RF|PL)\s+HouseUnit:\s+([a-pA-P])(\d{1,2})/m.exec(lines)
        @_lastSeen.housecode = m[1].toLowerCase()
        @_lastSeen.unitcode  = parseInt(m[2], 10)
        env.logger.debug("Event: " + JSON.stringify(@_lastSeen))

      if @_lastSeen.housecode and @_lastSeen.unitcode and m = /\d{2}\/\d{2}\s+(?:\d{2}:){2}\d{2}\s(Rx|Tx)\s+(RF|PL)\s+House:\s+([a-pA-P])\s+Func:\s+(On|Off)$/m.exec(lines)
        event = {
          protocol:  m[2].toLowerCase()
          direction: m[1].toLowerCase()
          housecode: m[3].toLowerCase()
          unitcode:  null # filled later
          state:     m[5].toLowerCase()
        }

        if event.housecode == @_lastSeen.housecode
          event.unitcode = @_lastSeen.unitcode
          env.logger.debug("Event: " + JSON.stringify(event))
          @_lastX10Message = event.housecode + event.unitcode + "-" + event.state 
          @emit "lastX10Message", @_lastX10Message
          
      return true

  plugin = new MochadSimplePlugin
  return plugin
