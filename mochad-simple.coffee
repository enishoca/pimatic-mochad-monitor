# MochadSimple plugin
module.exports = (env) ->

  # Require lodash
  _ = env.require 'lodash'

  # Require the bluebird promise library
  Promise = env.require 'bluebird'
 
  # Require [reconnect-net](https://www.npmjs.org/package/reconnect-net)
  reconnect = require 'reconnect-net'

  EventEmitter = require('events').EventEmitter


  fs = require "fs"

  # ###Plugin class
  class MochadSimplePlugin extends env.plugins.Plugin

    # ####init()
    #
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins`
    #     section of the config.json file
    #
    init: (app, @framework, config) =>
      
      @host = @config.host
      @port = @config.port

      env.logger.info("Initiating  host='#{@host}', port='#{@port}'")

      deviceConfigSchema = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("MochadSimple", {
        configDef: deviceConfigSchema.MochadSimple,
        createCallback: (config) => new MochadSimple(@framework, config)
      })

      @connection = null
      @emitter = new EventEmitter();
      @initConnection(@host, @port)


    # ####initConnection()
    #
    initConnection: (host, port)->

      # TODO Test 1) Start with non-working connection, make connection     work
      # TODO Test 2) Start with     working connection, make connection non-working and switch button in frontend
      reconnector = reconnect(((conn) ->

        # XXX Keep alive does not work [as expected](https://github.com/joyent/node/issues/6194)
        conn.setKeepAlive(true, 0)

        conn.setNoDelay(true)

        conn.on 'data', ((data) ->
          lines = data.toString()
          env.logger.info(lines)
          @emitter.emit("X10", lines);
        ).bind(@)
      ).bind(@)).connect(port, host);

      reconnector.on 'connect', ((connection) ->
        env.logger.info("(re)Opened connection")
        @connection = connection
      ).bind(@)

      reconnector.on 'disconnect', ((err) ->
        env.logger.error("Disconnected from #{@host}:#{@port}: " + err)
        @connection = null;
      ).bind(@)



  # #### MochadSimple class
  class MochadSimple extends env.devices.Sensor

    # ####constructor()
    #
    # #####params:
    #  * `deviceConfig`
    #
    constructor: (@framework, @config) ->
      @id        = @config.id
      @name      = @config.name
      @logfile   = @config.logfile

      plugin.emitter.on 'X10', ((lines) ->
        env.logger.info("in emitter handlers")
        fs.appendFile @logfile, lines, (error) ->
          env.logger.error("Error writing file", error) if error
      ).bind(@)

      myEventEmitter.on('X10', fnListener) ->
                  fs.appendFile @logfile, lines, (error) ->
            env.logger.error("Error writing file", error) if error

      super()


  class MochadSimpleSwitch extends env.devices.PowerSwitch

    constructor: (@config) ->
      @id = @config.id
      @name = @config.name
      @housecode = @config.housecode
      @unitcode = @config.unitcode
      @protocol - @config.protocol
 

    destroy: () ->
        super()


    # ####changeStateTo()
    #
    # #####params:
    #  * `state`
    #
    changeStateTo: (state) ->
      @plugin.sendCommand("#{@protocol} #{@housecode}#{@unitcode} " + ( if state then "on" else "off" ))


    
  # ###Finally
  # Create a instance of my plugin
  plugin = new MochadSimplePlugin
  # and return it to the framework.
  return plugin 
