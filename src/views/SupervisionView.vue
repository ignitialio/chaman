<template>
  <div class="supervision-layout">
    <div class="supervision-section">{{ $t('Services') }}</div>
    <div class="supervision-services">
      <div class="supervision-service elevation-1"
        v-for="service in services" :key="service.name"
        @click="handleServiceSelect(service)">
        <div class="supervision-service--name"
          :class="{ 'local': service.isLocal }">
          <div>{{service.name}}</div>
          <img v-if="service._iconUrl" :src="service._iconUrl"
            class="supervision-service--icon"/>
        </div>
        <div v-if="service.hostname">
          <span style="color: slategrey;">hostname:</span>
          {{service.hostname}}</div>
        <div v-if="service.version">
          <span style="color: slategrey;">version:</span>
          {{service.version}}</div>
      </div>
    </div>

    <div class="supervision-section">{{ $t('Modules') }}</div>
    <div class="supervision-services">
      <div class="supervision-module elevation-1"
        v-for="module in modules" :key="module.name"
        @click="handleModuleSelect(module)">
        <div>{{module.name}}</div>
      </div>
    </div>
  </div>
</template>

<script>
import sortBy from 'lodash/sortBy'
import map from 'lodash/map'
import values from 'lodash/values'

export default {
  data() {
    return {
      services: [],
      modules: []
    }
  },
  watch: {},
  components: {},
  computed: {
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

      let configService = await this.$services.waitForService('config')
      this.modules = (await configService.modules()).list

      this.$forceUpdate()
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

            console.log(itemToUpdate._iconUrl)
            resolve()
          }
        } catch (err) {
          reject(err)
        }
      })
    },
    handleServiceUp(service) {
      this.update()
    },
    handleServiceDown(service) {
      this.update()
      if (this.selected && service === this.selected.name) {
        this.selected = null
      }
    },
    handleServiceSelect(service) {
      console.log($j(service))
    },
    handleModuleSelect(module) {
      console.log($j(module))
    },
    handleHeartBeat(message) {
      for (let i = 0; i < this.services.length; i++) {
        if (this.services[i].name === message.meta.service) {
          this.services[i].hostname = message.data.hostname
          this.services[i].version = message.data.version
          this.$forceUpdate()
          break
        }
      }
    }
  },
  mounted() {
    // listeners
    this._listeners = {
      onServiceUp: this.handleServiceUp.bind(this),
      onServiceDown: this.handleServiceDown.bind(this),
      onHeartBeat: this.handleHeartBeat.bind(this)
    }

    this.$services.on('service:up', this._listeners.onServiceUp)
    this.$services.on('service:down', this._listeners.onServiceDown)

    this.update()

    this.$ws.socket.on('service:heartbeat:event', this._listeners.onHeartBeat)
  },
  beforeDestroy() {
    this.$ws.socket.off('service:heartbeat:event', this._listeners.onHeartBeat)
  }
}
</script>

<style>
.supervision-layout {
  width: 100%;
  height: calc(100% - 0px);
}

.supervision-services {
  margin: 8px 8px 24px 8px;
  width: calc(100% - 16px);
  height: 212px;
  display: flex;
  flex-wrap: wrap;
  overflow-y: auto;
  border-radius: 2px;
}

.supervision-service {
  width: 200px;
  height: 96px;
  display: flex;
  flex-flow: column;
  margin: 4px;
  border-radius: 2px;
}

.supervision-service--name {
  background-color: dodgerblue;
  padding: 4px;
  color: white;
  margin-bottom: 8px;
  display: flex;
  align-items: center;
  justify-content: space-between;
}

.supervision-service--name.local {
  background-color: olive;
}

.supervision-service--icon {
  width: 24px;
  height: 24px;
}

.supervision-section {
  width: 100%;
  text-align: center;
  font-weight: bold;
  border-bottom: 1px solid deepskyblue;
  margin: 8px 4px;
}

.supervision-module {
  width: 200px;
  height: 40px;
  display: flex;
  align-items: center;
  margin: 4px;
  justify-content: center;
  overflow: hidden;
}
</style>
