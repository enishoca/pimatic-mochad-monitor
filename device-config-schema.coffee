module.exports = {
  title: "pimatic-mochad-simple device config schemas"
  MochadSimpleSwitch: {
    title: "MochadSimpleSwitch config options"
    type: "object"
    properties:
      housecode:
        description: "X10 housecode"
        type: "string"
        default: "A"
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
        default: "1"
        default: "pl"
        enum: ["rf", "pl"]
  }
  MochadSimpleController: {
    title: "MochadSimpleController config options"
    type: "object"
    properties:
      buttons:
        description: "Buttons of the keypad"
        type: "array"
        default: [
          {
            "id": "reset-mochad",
            "text": "Reset Connection"
          }
        ]
        format: "table"
        items:
          type: "object"
          properties:
            id:
              type: "string"
            text:
              type: "string"
  }
}