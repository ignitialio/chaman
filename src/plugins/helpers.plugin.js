export default {
  install:
    function (Vue) {
      Vue.prototype.$helpers = {
        getServiceMethods: function(serviceName) {
          console.log(serviceName, this.$services.servicesDico)
          return this.$services.servicesDico[serviceName].methods
        }
      }
    }
}
