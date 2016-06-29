module.exports = {
  title: "pimatic-mochad-simple device config schemas"
  MochadSimple: {
    title: "Mochad Monitor config options"
    type: "object"
    properties:
      logfile:
        description: "fully qualified path to the log file"
        type: "string"
        required: true
  }
  MochadSimpleSwitch: {
    title: "Simple Swich for Mochad"
    type: "object"
    properties:
      housecode:
        description: "X10 housecode"
        type: "string"
        required: true
        pattern: "^[A-Pa-p]$"
      unitcode:
        description: "X10 unitcode"
        type: "number"
        required: true
        minimum: 1
        maximum: 16
      protocol:
        description: "X10 protocol (RF/PL)"
        type: "string"
        default: "pl"
        enum: ["rf", "pl"]
  }
}
