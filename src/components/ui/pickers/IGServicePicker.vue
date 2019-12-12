<template>
  <div class="servicepicker-layout">
    <v-list class="servicepicker-list">
      <v-list-item class="services-item"
        v-for="(service, index) in services" :key="index"
        @click.stop="handleSelect(service)"
        @hook:mounted="handleMounted(service)"
        :class="{ 'selected': selected === service }">
        <v-list-item-avatar>
          <v-img :src="service._iconUrl" alt=""></v-img>
        </v-list-item-avatar>

        <v-list-item-content>
          <v-list-item-title v-text="service.name"></v-list-item-title>
          <v-list-item-subtitle
            v-text="service.options && service.options.description ?
              $t(service.options.description.title) : null"></v-list-item-subtitle>
        </v-list-item-content>
      </v-list-item>
    </v-list>
  </div>
</template>

<script>
import sortBy from 'lodash/sortBy'
import values from 'lodash/values'

export default {
  data: () => {
    return {
      services: [],
      selected: null
    }
  },
  methods: {
    onServiceUp(service) {
      this.update()
    },
    onServiceDown(service) {
      this.update()
      if (this.selected && service === this.selected.name) {
        this.selected = null
      }
    },
    handleMounted(item) {
      if (item.options && item.options.description) {
        this.getImage(item, item.name, item.options.description.icon)
          .then(() => {
            this.$forceUpdate()
          })
          .catch(err => console.log(err))
      } else {
        console.log('no description for service [%s]', item.name)
      }
    },
    getImage(itemToUpdate, serviceName, fileName) {
      return new Promise(async (resolve, reject) => {
        try {
          let imageData = await this.$services.getFileFromService(serviceName, fileName)
          let typedArray = new Uint8Array(imageData)
          let type = fileName.toLowerCase().match(/\.[0-9a-z]+$/i)[0].replace('.', '')
          if (type) {
            itemToUpdate._iconUrl = 'data:image/' + type + ';base64, ' +
              btoa(String.fromCharCode.apply(null, typedArray))
            this.$forceUpdate()
            resolve()
          }
        } catch (err) {
          reject(err)
        }
      })
    },
    async update() {
      this.services = sortBy(values(this.$services.servicesDico), [ 'name' ])

      for (let i = 0; i < this.services.length; i++) {
        try {
          let service = await this.$services.waitForService(this.services[i].name)
          if (this.services[i].options && this.services[i].options.description) {
            await this.getImage(this.services[i], this.services[i].name,
              this.services[i].options.description.icon)
          }
        } catch (err) {
          console.log(err)
        }
      }

      this.$forceUpdate()
    },
    handleSelect(service) {
      this.selected = service
      this.$services.emit('selection:service', service)
    }
  },
  mounted() {
    // listeners
    this._listeners = {
      onServiceUp: this.onServiceUp.bind(this),
      onServiceDown: this.onServiceDown.bind(this)
    }

    this.$services.on('service:up', this._listeners.onServiceUp)
    this.$services.on('service:down', this._listeners.onServiceDown)

    this.update()
  },
  beforeDestroy() {
    this.$services.off('service:up', this._listeners.onServiceUp)
    this.$services.off('service:down', this._listeners.onServiceDown)
  }
}
</script>

<style scoped>
.servicepicker-layout {
  width: 100%;
  height: calc(100% - 0px);
  overflow-y: auto;
}

.servicepicker-layout {
  width: 100%;
}

.services-item.selected {
  background-color: rgba(0, 191, 255, 0.05);
  border-bottom: 1px solid deepskyblue;
}
</style>
