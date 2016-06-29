module.exports = {
  title: "pimatic-mochad-simple config"
  type: "object"
  properties:
    host:
      description: "Hostname mochad is available on"
      type: "string"
      default: "localhost"
    port:
      description: "Port mochad is available on"
      type: "number"
      default: 1099
}

