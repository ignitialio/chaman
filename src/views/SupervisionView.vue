<template>
  <div class="supervision-layout">
    <div class="supervision-half">
      <div class="supervision-section">{{ $t('Services') }}</div>
      <div class="supervision-services">
        <div class="supervision-service elevation-1"
          v-for="service in services" :key="service.name"
          @click="handleServiceSelect(service)">
          <div class="supervision-service--name"
            :class="{ 'local': service.isLocal }">
            <div>{{service.name}}
              <span v-if="service.hostname"
                class="supervision-service--name--sub">
                {{$t('host') + ' ' + service.hostname}}</span>
              <span v-if="service.version"
                class="supervision-service--name--sub">
                {{$t('version') + ' ' + service.version}}</span>
            </div>
            <img v-if="service._iconUrl" :src="service._iconUrl"
              class="supervision-service--icon"/>
          </div>
          <div class="supervision-service--methods">
            <div class="supervision-service--method"
              v-for="m in service.methods">{{m}}</div>
          </div>
        </div>
      </div>
    </div>

    <div class="supervision-half">
      <div class="supervision-section">{{ $t('Modules') }}</div>
      <div class="supervision-services">
        <div class="supervision-module elevation-1"
          v-for="module in modules" :key="module.name"
          @click="handleModuleSelect(module)">
          <div>{{module.name}}</div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import sortBy from 'lodash/sortBy'
import map from 'lodash/map'
import values from 'lodash/values'
import filter from 'lodash/filter'

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

      let subServices = {}
      this.services.forEach(e => {
        if (e.name.match(/:/)) {
          let svc = e.name.split(':')[0]
          let ssvc = e.name.split(':')[10]

          subServices[svc] = subServices[svc] || []
          subServices[svc].push(ssvc)
        }
      })

      this.services = filter(this.services, e => !e.name.match(/:/))

      for (let i = 0; i < this.services.length; i++) {
        try {
          let service = await this.$services.waitForService(this.services[i].name)
          if (this.services[i].options && this.services[i].options.description) {
            await this.getImage(this.services[i], this.services[i].name,
              this.services[i].options.description.icon)
          }

          this.services[i].isLocal = await service.isLocal()
          this.services[i].sub = subServices[this.services[i].name]
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
  display: flex;
}

.supervision-half {
  width: 50%;
  height: calc(100% - 0px);
}

.supervision-services {
  width: calc(100% - 0px);
  height: calc(100% - 48px);
  display: flex;
  flex-flow: column;
  overflow-y: auto;
  border-radius: 2px;
  align-items: center;
}

.supervision-service {
  width: calc(100% - 8px);
  min-height: 96px;
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

.supervision-service--name--sub {
  color: gainsboro;
  margin: 0 8px;
}

.supervision-service--name.local {
  background-color: olive;
}

.supervision-service--icon {
  width: 24px;
  height: 24px;
}

.supervision-service--methods {
  width: 100%;
  height: 90px;
  max-height: 90px;
  overflow-y: auto;
  display: flex;
  flex-wrap: wrap;
}

.supervision-service--method {
  border: 1px solid gainsboro;
  height: 1.5em;
  padding: 2px;
  margin: 2px;
}

.supervision-section {
  width: calc(100% - 8px);
  text-align: center;
  font-weight: bold;
  border-bottom: 1px solid dimgray;
  margin: 8px 4px;
}

.supervision-module {
  width: calc(100% - 8px);
  height: 40px;
  display: flex;
  align-items: center;
  margin: 4px;
  justify-content: center;
  overflow: hidden;
}

@media screen and (max-width: 600px) {
  .supervision-layout {
    flex-flow: column;
    overflow-y: auto;
  }

  .supervision-half {
    width: 100%;
    height: auto;
  }
}
</style>
