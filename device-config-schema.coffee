module.exports = {
  title: "pimatic-mochad-monitor device config schemas"
  Mochad:
    title: "Mochad Monitor config options"
    type: "object"
    properties:
      id:
        description: "Unique id"
        type: "string"
        required: true
      class:
        description: "Class"
        type: "string"
        required: true
        pattern: "^MochadMonitor$"
      name:
        description: "Unique name"
        type: "string"
        required: true
      host:
        description: "Hostname mochad is available on"
        type: "string"
        default: "localhost"
      port:
        description: "Port mochad is available on"
        type: "number"
        default: 1099
      logfile:
        description: "fully qualified path to the log file"
        type: "string"
        required: true
}
