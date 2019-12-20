<template>
  <div class="workflow-palette-layout" :class="{ 'hidden': hidden }">
    <div class="workflow-palette-handle" @click="hidden = !hidden">
      <v-icon v-if="hidden">drag_handle</v-icon>
      <v-icon v-if="!hidden">clear</v-icon>
    </div>

    <v-tabs v-if="blocks" v-model="tab" class="workflow-palette-tabs elevation-2"
      centered grow>
      <v-tabs-slider></v-tabs-slider>

      <v-tab v-for="(family, index) in families" :key="index"
        :href="`#tab-${family}`">
        {{ family }}
      </v-tab>

      <v-tab-item v-for="(family, index) in families" :key="index"
        :value="'tab-' + family">
        <v-list>
          <v-list-item v-for="block in blocksByFamily(family)"
            :data-block="JSON.stringify(block)"
            :key="block.name" draggable @dragstart="handleDragStart">
            <v-list-item-avatar>
              <v-img :src="$utils.fileUrl(block.icon)" alt=""></v-img>
            </v-list-item-avatar>

            <v-list-item-content>
              <v-list-item-title v-text="block.title">
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
import * as d3 from 'd3'
import _ from 'lodash'

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
      families: [ 'Sources', 'Processings', 'Widgets' ]
    }
  },
  watch: {
  },
  methods: {
    blocksByFamily(family) {
      return _.filter(this.blocks, e => {
        return e.family === family
      })
    },
    handleDragStart(event) {
      let block = JSON.parse(event.srcElement.dataset.block)

      event.dataTransfer
       .setData('text/plain', event.srcElement.dataset.block)

      let img = document.createElement('img')
      img.src = this.$utils.fileUrl(block.icon)
      img.style.maxWidth = '100px'
      img.style.maxHeight = '100px'
      event.dataTransfer.setDragImage(img, 64, 64)
    },
    handleDeleteInput(name) {
      this.block.inputs = _.filter(this.block.inputs, e => {
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
      this.block.outputs = _.filter(this.block.inputs, e => {
        return e.name !== name
      })
    },
    handleAddOutput(block) {
      this.block.outputs.push({
        name: 'out_' + Math.random().toString(36).slice(2, 8),
        active: false
      })
    }
  },
  async mounted() {
    try {
      // await this.$utils.waitForProperty(this, 'scene')
      d3.json('data/blocks.workflow.json').then(data => {
        this.blocks = data
      }).catch(err => { console.log(err) })
    } catch (err) {
      console.log(err)
    }
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
