import { Encoders } from '@ignitial/iio-app-client'

export default {
  install:
    function (Vue) {
      Vue.prototype.$encoders = Encoders
    }
}
