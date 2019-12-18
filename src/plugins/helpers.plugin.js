export default {
  install:
    function (Vue) {
      Vue.prototype.$helpers = {
        getServiceMethods: async function(serviceName, instance) {
          try {
            if (this.$services[serviceName]) {
              let methods = await this.$services[serviceName].getMethods(instance)
              return methods
            } else {
              return null
            }
          } catch (err) {
            console.log(err)
            return null
          }
        },
        getServiceInstances: async function(serviceName) {
          try {
            if (this.$services[serviceName] && this.$services[serviceName].getInstances) {
              let instances = await this.$services[serviceName].getInstances()
              return instances
            } else {
              return null
            }
          } catch (err) {
            console.log(err)
            return null
          }
        }
      }
    }
}
