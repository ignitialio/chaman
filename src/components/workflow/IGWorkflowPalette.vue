<template>
  <div class="workflow-palette-layout" :class="{ 'hidden': hidden }">
    <div class="workflow-palette-handle" @click="hidden = !hidden">
      <v-icon v-if="hidden">drag_handle</v-icon>
      <v-icon v-if="!hidden">clear</v-icon>
    </div>

    <v-tabs v-if="blocks" v-model="tab" class="workflow-palette-tabs elevation-2"
      centered grow>
      <v-tabs-slider></v-tabs-slider>

      <v-tab v-for="(type, index) in types" :key="index"
        :href="`#tab-${type}`">
        {{ $t(type) }}
      </v-tab>

      <v-tab-item v-for="(type, index) in types" :key="index"
        :value="'tab-' + type">
        <v-list>
          <v-list-item v-for="block in blocksByType(type)"
            :data-block="JSON.stringify(block)"
            :key="block.name" draggable @dragstart="handleDragStart">
            <v-list-item-avatar @hook:mounted="icon(block)">
              <img :draggable="false" :src="block.icon" alt=""/>
            </v-list-item-avatar>

            <v-list-item-content>
              <v-list-item-title v-text="block.label">
              </v-list-item-title>
              <v-list-item-subtitle v-text="block.description"></v-list-item-subtitle>
            </v-list-item-content>
          </v-list-item>
        </v-list>
      </v-tab-item>
    </v-tabs>
  </div>
</template>

<script>
import filter from 'lodash/filter'
import find from 'lodash/find'
import sortBy from 'lodash/sortBy'
import values from 'lodash/values'

export default {
  name: 'ig-workflow-palette',
  props: {
    blockId: String,
    disabledFamilies: Array,
    scene: Object
  },
  data () {
    return {
      tab: null,
      hidden: true,
      blocks: null,
      types: [ 'Source', 'Processing', 'Destination' ]
    }
  },
  watch: {
  },
  methods: {
    async update() {
      this.services = sortBy(values(this.$services.servicesDico), [ 'name' ])

      for (let i = 0; i < this.services.length; i++) {
        try {
          await this.$services.waitForService(this.services[i].name)
          let options = this.$services.servicesDico[this.services[i].name].options
          let workflow
          if (options) {
            workflow = options.workflow
          }

          if (workflow) {
            this.blocks = this.blocks || []
            if (!find(this.blocks, e => e.name === this.services[i].name)) {
              this.blocks.push({
                id: null,
                name: this.services[i].name,
                service: this.services[i].name,
                instance: '',
                label: options.description.title,
                types: workflow.types,
                description: options.description.info,
                icon: options.description.icon,
                inputs: workflow.inputs,
                outputs: workflow.outputs,
                options: null
              })
            }
          }
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
    blocksByType(type) {
      return filter(this.blocks, e => {
        return e.types.indexOf(type) !== -1
      })
    },
    handleDragStart(event) {
      let block = JSON.parse(event.srcElement.dataset.block)

      event.dataTransfer
        .setData('text/plain', event.srcElement.dataset.block)

      let img = new Image()
      img.src = block.icon
      event.dataTransfer.setDragImage(img, 32, 32)
    },
    handleDeleteInput(name) {
      this.block.inputs = filter(this.block.inputs, e => {
        return e.name !== name
      })
    },
    handleAddInput(block) {
      this.block.inputs.push({
        name: 'in_' + Math.random().toString(36).slice(2, 8),
        active: false
      })
    },
    handleDeleteOutput(name) {
      this.block.outputs = filter(this.block.inputs, e => {
        return e.name !== name
      })
    },
    handleAddOutput(block) {
      this.block.outputs.push({
        name: 'out_' + Math.random().toString(36).slice(2, 8),
        active: false
      })
    },
    icon(block) {
      this.$utils.getImage(block.name, block.icon).then(data => {
        block.icon = data
      }).catch(err => console.log(err, block.name, block.icon))
    }
  },
  async mounted() {
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

<style>
.workflow-palette-layout {
  position: absolute;
  width: 450px;
  top: 0;
  left: calc(100% - 450px);
  height: calc(100% - 0px);
  transition: left 1s ease;
  border: 1px solid gainsboro;
  background-color: rgba(255, 255, 255, 0.8);
}

.workflow-palette-layout.hidden {
  left: calc(100% - 0px);
}

.workflow-palette-handle {
  position: absolute;
  top: calc(50% - 16px);
  left: -32px;
  width: 32px;
  height: 32px;
  border-left: 1px solid gainsboro;
  border-top: 1px solid gainsboro;
  border-bottom: 1px solid gainsboro;
  border-right: 1px solid white;
  border-radius: 4px 0 0 4px;
  display: flex;
  justify-content: center;
  align-items: center;
}

.theme--dark .workflow-palette-layout {
  border-left: 1px solid dimgrey;
}

.workflow-palette-tabs {
  height: calc(100% - 0px);
}

.workflow-palette-list {
  height: calc(100% - 0px);
  overflow-y: auto;
}
</style>
