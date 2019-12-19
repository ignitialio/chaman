<template>
  <div class="services-layout">
    <v-list class="services-left-panel">
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

    <div class="services-right-panel">
      <component :is="selected.name"
        class="services-component elevation-2"
        v-if="selected && selected.options &&
          selected.options.uiComponentInjection"></component>

      <div>

      </div>
    </div>
  </div>
</template>

<script>
import sortBy from 'lodash/sortBy'
import values from 'lodash/values'

export default {
  data: () => {
    return {
      selected: null,
      services: null
    }
  },
  methods: {
    async update() {
      this.services = sortBy(values(this.$services.servicesDico), [ 'name' ])

      for (let i = 0; i < this.services.length; i++) {
        try {
          let service = await this.$services.waitForService(this.services[i].name)
          if (this.services[i].options && this.services[i].options.description) {
            await this.getImage(this.services[i], this.services[i].name,
              this.services[i].options.description.icon)
          }

          this.services[i].isLocal = await service.isLocal()
        } catch (err) {
          console.log(err)
        }
      }

      this.$forceUpdate()
    },
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
    handleSelect(service) {
      this.selected = service
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
.services-layout {
  width: 100%;
  height: calc(100% - 0px);
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.services-left-panel {
  position: relative;
  width: calc(33% - 8px);
  height: calc(100% - 0px)!important;
  overflow-y: auto;
}

.services-right-panel {
  margin-right: 8px;
  width: calc(67% - 8px);
  height: calc(100% - 16px);
}

.services-component {
  width: calc(100% - 4px);
  height: calc(100% - 4px);
  padding: 4px;
  display: flex;
  justify-content: center;
  align-items: center;
  overflow-y: auto;
}

.services-item.selected {
  background-color: rgba(0, 191, 255, 0.05);
  border-bottom: 1px solid deepskyblue;
}
</style>
