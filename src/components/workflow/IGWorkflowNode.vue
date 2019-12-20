<template>
  <div v-if="node" :id="id" draggable
    class="wfnode-layout"
    :class="{
      'sink': node.family === 'Sources',
      'processing': node.family === 'Processings',
      'widget': node.family === 'Widgets'
    }"
    @dragstart="handleDragStart"
    @dragend="handleDragEnd">

    <img class="wfnode-background" :src="node.icon"/>

    <div class="wfnode-top">
      <v-icon class="wfnode-icon" @click="handleSettings">settings</v-icon>
      <ig-btn-confirm class="wfnode-icon delete"
        small flat icon="delete_forever"
        @mouseup.prevent.stop=""
        @mousedown.prevent.stop=""
        @click.prevent.stop="handleDelete"></ig-btn-confirm>
    </div>

    <div class="wfnode-bottom">
      <div class="wfnode-title" :title="node.title">{{ node.title }}</div>
    </div>

    <div class="wfnode-inputs">
      <div v-for="(slot, index) in node.inputs" :key="index"
        :ref="'input_' + index" class="wfnode-slot"
        :data-parent="node.id" :data-index="index"
        :class="{ 'active': slot.active }"
        @mouseup.stop.prevent="slotMouseUp($event, node.id, index)"
        @mousedown="endSlot($event, index)">

        <div class="wfnode-labels">{{ slot.name }}</div>
      </div>
    </div>

    <div class="wfnode-outputs">
      <div v-for="(slot, index) in node.outputs" :key="index"
        :ref="'output_' + index" class="wfnode-slot"
        :data-parent="node.id" :data-index="index"
        :class="{ active: slot.active}"
        @mousedown.prevent.stop="slotMouseDown($event, index)">

        <div class="wfnode-labels right">{{ slot.name }}</div>
      </div>
    </div>

    <!-- Node settings dialog -->
    <ig-dialog v-model="settingsDialog">
      <v-card class="wfnode-dialog-card">
        <v-toolbar dark color="primary">
          <v-btn icon dark @click.native="settingsDialog = false">
            <v-icon>close</v-icon>
          </v-btn>
          <v-toolbar-title>{{ $t('Node settings') }} - {{ node.title }}</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-toolbar-items>
          </v-toolbar-items>
        </v-toolbar>

        <v-card-text class="wfnode-dialog-content">
          <v-text-field v-model="node.id" :label="$t('Id')"></v-text-field>
          <v-text-field v-model="node.title" :label="$t('Title')"></v-text-field>
          <v-text-field v-model="node.description" :label="$t('Description')"></v-text-field>
          <v-select v-if="families" :label="$t('Family')"
            :items="families" v-model="node.family"></v-select>

          <h3 class="wfnode-section">{{ $t('Options') }}</h3>

          <ig-form v-if="node.optionsSchema" class="wfnode-form"
            v-model="node.options" :schema.sync="node.optionsSchema"/>
        </v-card-text>
      </v-card>
    </ig-dialog>
  </div>
</template>

<script>
import _ from 'lodash'

export default {
  name: 'ig-worflow-node',
  props: {
    id: String,
    data: {
      type: Object
    },
    scale: {
      type: Number,
      default: 1
    }
  },
  data: () => {
    return {
      node: null,
      settingsDialog: false,
      families: null
    }
  },
  watch: {
    node: {
      handler: function(val) {
        if (this.$el.style) {
          this.$el.style.left = val.geometry.x + 'px'
          this.$el.style.top = val.geometry.y + 'px'
        }
      },
      deep: true
    }
  },
  methods: {
    // type = output | input
    getSlotElement(type, index) {
      if (this.$refs[type + '_' + index]) {
        return this.$refs[type + '_' + index][0]
      }
    },
    handleSettings() {
      this.settingsDialog = true
    },
    handleDelete() {
      this.$emit('delete', this.node)
    },
    handleDragStart(event) {
      let mx = parseInt(event.x / this.scale)
      let my = parseInt(event.y / this.scale)

      let img = document.createElement('img')
      img.src = ''
      img.style.opacity = 0
      event.dataTransfer.setDragImage(img, 0, 0)

      let obj = _.cloneDeep(this.node)
      let bb = event.srcElement.getBoundingClientRect()
      obj._dx = mx - bb.x / this.scale
      obj._dy = my - bb.y / this.scale

      event.dataTransfer
       .setData('text/plain', JSON.stringify(this.node))

      this.onDrag = dragEvent => {
        let dx = parseInt(dragEvent.x / this.scale)
        let dy = parseInt(dragEvent.y / this.scale)

        this.node.geometry.x = parseInt(dx - obj._dx)
        this.node.geometry.y = parseInt(dy - obj._dy - 48 / this.scale)

        this.$emit('update:data', this.node)
        this.$emit('position', {
          x: this.node.geometry.x,
          y: this.node.geometry.y
        }, this.node)
      }

      document.addEventListener('drag', this.onDrag)
    },
    handleDragEnd() {
      document.removeEventListener('drag', this.onDrag)
    },
    slotMouseUp(event, nodeId, index) {
      let bb = event.srcElement.getBoundingClientRect()

      this.$emit('connectorEnd', nodeId, this.$el, index, {
        x: bb.x + bb.width,
        y: bb.y + bb.height / 2
      })
    },
    slotMouseDown(event, index) {
      let bb = event.srcElement.getBoundingClientRect()

      this.$emit('connectorStart', this.node.id, this.$el, index, {
        x: bb.x + bb.width / 2,
        y: bb.y + bb.height / 2
      })

      let onMouseUp = event => {
        // ended nowhere
        this.$emit('connectorEnd')

        document.removeEventListener('mouseup', onMouseUp)
      }

      document.addEventListener('mouseup', onMouseUp)
    },
    endSlot(event, index) {
    }
  },
  async mounted() {
    this.node = _.cloneDeep(this.data)
    await this.$utils.waitForDOMReady(this.$el)

    this.$el.style.left = this.node.geometry.x + 'px'
    this.$el.style.top = this.node.geometry.y + 'px'

    this.families = [{
      value: 'Sources',
      text: this.$t('Sources')
    }, {
      value: 'Processings',
      text: this.$t('Processings')
    },{
      value: 'Widgets',
      text: this.$t('Widgets')
    }]
  },
  beforeDestroy () {
  }
}
</script>

<style lang="scss" scoped>
$titleColor: #303030;
$backgroundColor: rgba(255, 255, 255, 0.7);
$nodeBorder: 1px;
$nodeBorderColor: deepskyblue;
$selectedNodeBorderColor: tomato;
$nodeBorderColorDark: peru;

$ioPaddingInner: 2px 0;
$ioHeight: 24px;
$ioFontSize: 14px;
$ioFontFamily: monospace;
$ioColor: gainsboro;

$slotBorder: 1px;
$slotSize: 10px;
$slotMargin: 2px; // left/right

$slotNewColor: forestgreen;
$slotRemoveColor: tomato;
$slotConnectedColor: gold;
$slotNotConnectedColor: orange;

.wfnode-layout {
  position: absolute;
  box-sizing: border-box;
  background-position: center;
  background-size: contain;
  border-radius: 4px;
  border: $nodeBorder solid $nodeBorderColor;
  background-color: $backgroundColor;
  width: 100px;
  height: 100px;
  display: flex;
  justify-content: center;
  align-items: center;
  cursor: pointer;

  &.selected {
    border: $nodeBorder solid $selectedNodeBorderColor;
  }

  .theme--dark &.selected {
    border: $nodeBorder solid $selectedNodeBorderColor;
  }

  .wfnode-background {
    position: absolute;
    width: 64px;
    height: 64px;
  }

  .wfnode-icon {
    cursor: default;
  }

  .wfnode-top {
    width: 100%;
    position: absolute;
    top: -26px;
    display: flex;
    justify-content: space-between;
    align-items: center;

    .wfnode-title {
      width: calc(100% - 32px - 32px);
      border-radius: 4px 4px 0 0;
      text-align: center;
      color: $titleColor;
      font-weight: bold;
      text-overflow: ellipsis;
      white-space: nowrap;
      overflow-x: hidden;
    }

    .wfnode-icon {
      opacity: 0.6;
      color: gainsboro;
      cursor: pointer;
      width: 24px;
      height: 24px;
    }

    .wfnode-icon:hover {
      color: dodgerblue;
      opacity: 1;
    }

    .wfnode-icon.delete:hover {
      color: tomato;
      opacity: 1;
    }
  }

  .wfnode-bottom {
    width: 100%;
    position: absolute;
    bottom: -32px;
    border-radius: 4px 4px 0 0;
    display: flex;
    align-items: center;

    .wfnode-title {
      width: 100%;
      text-align: center;
      user-select: none;
      color: $titleColor;
      text-overflow: ellipsis;
      white-space: nowrap;
      overflow-x: hidden;
    }
  }

  .wfnode-inputs, .wfnode-outputs {
    position: absolute;
    padding: $ioPaddingInner;

    display: node;

    > * {
      width: 100%;
    }
  }

  .wfnode-slot {
    box-sizing: border-box;
    margin-top: $ioHeight / 2 - $slotSize / 2;

    width: $slotSize;
    height: $slotSize;

    border: $slotBorder solid $nodeBorderColor;
    border-radius: 100%;

    cursor: crosshair;
    background: $slotNotConnectedColor;

    &.active {
      background: $slotConnectedColor;
    }

    .wfnode-labels {
      margin-top: -100%;
      margin-left: -66px;
      pointer-events: none;
      color: gainsboro;
      text-align: right;
      width: 60px;
      text-overflow: ellipsis;
      white-space: nowrap;
      overflow-x: hidden;
    }

    .wfnode-labels.right {
      margin-top: -100%;
      margin-left: 15px;
      text-align: left;
    }
  }

  .wfnode-slot:hover {
    .wfnode-labels {
      color: tomato;
    }
  }

  .wfnode-inputs {
    position: absolute;
    top: 0;
    left: -$slotSize/2;
  }

  .wfnode-outputs {
    position: absolute;
    top: 0;
    right: -$slotSize/2;
  }

  .wfnode-dialog-card {
    width: 100%;
    height: calc(100% - 0px);
    border-radius: 0!important;

    .wfnode-dialog-content {
      height: calc(100vh - 64px);
      width: 100%;
      padding: 16px 15% 0 15%;
      overflow-y: auto;
    }

    .wfnode-section {
      width: 100%;
      margin: 16px 0;
      padding-left: 8px;
      background-color: rgba(0, 0, 0, 0.1);
      border-top: 1px solid dimgray;
      border-bottom: 1px solid dimgray;
    }
  }
}

.wfnode-layout.sink {
  border-color: green;
}

.wfnode-layout.widget {
  border-color: orange;
}
</style>
