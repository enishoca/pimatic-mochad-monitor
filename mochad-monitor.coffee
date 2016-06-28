# MochadMonitor plugin
module.exports = (env) ->

  # Require lodash
  _ = env.require 'lodash'

  # Require the bluebird promise library
  Promise = env.require 'bluebird'
 
  # Require [reconnect-net](https://www.npmjs.org/package/reconnect-net)
  reconnect = require 'reconnect-net'

  fs = require "fs"

  # ###Plugin class
  class MochadMonitorPlugin extends env.plugins.Plugin

    # ####init()
    #
    # #####params:
    #  * `app` is the [express] instance the framework is using.
    #  * `framework` the framework itself
    #  * `config` the properties the user specified as config for your plugin in the `plugins`
    #     section of the config.json file
    #
    init: (app, @framework, config) =>

      deviceConfigSchema = require("./device-config-schema")

      @framework.deviceManager.registerDeviceClass("MochadMonitor", {
        configDef: deviceConfigSchema.MochadMonitor,
        createCallback: (config) => new MochadMonitor(@framework, config)
      })



  # #### MochadMonitor class
  class MochadMonitor extends env.devices.Sensor

    # ####constructor()
    #
    # #####params:
    #  * `deviceConfig`
    #
    constructor: (@framework, @config) ->

      @id        = @config.id
      @name      = @config.name
      @host      = @config.host
      @port      = @config.port
      @logfile   = @config.logfile

      env.logger.debug("Initiating id='#{@id}', name='#{@name}', host='#{@host}', port='#{@port}'")
      @connection = null
      @initConnection(@host, @port)

      super()

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
          env.logger.debug(lines)
          
          fs.appendFile @logfile, lines, (error) ->
            env.logger.error("Error writing file", error) if error
 
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
  # ###Finally
  # Create a instance of my plugin
  plugin = new MochadMonitorPlugin
  # and return it to the framework.
  return plugin 
