<template>
  <div class="colorpicker-layout">
    <div class="colorpicker-color" @click="showPicker"
      :style="'background-color: ' + cssColor(selected)"></div>

    <div v-if="pickerVisible" class="colorpicker-picker">
      <div v-for="(color, index) in palette"
        :key="index" :title="color" class="colorpicker-color"
        @click="select(color)" :style="'background-color: ' + cssColor(color)"></div>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'
import * as d3 from 'd3'
import colors from 'vuetify/es5/util/colors'

export default {
  props: {
    value: String,
    native: Boolean,
    useMaterialPalette: Boolean
  },
  data: () => {
    return {
      selected: null,
      pickerVisible: false,
      palette: d3.schemeCategory10
        .concat([ 'white', 'black', 'gold', 'forestgreen', 'deepskyblue' ])
    }
  },
  methods: {
    select(color) {
      this.selected = color

      if (this.native) {
        color = colors[_.camelCase(color)].base
      }

      this.$emit('input', color)
      this.$services.emit('selection:color', color)
      this.pickerVisible = false
    },
    async showPicker(e) {
      this.pickerVisible = true
      let picker = await this.$utils.waitForDOMReady('.colorpicker-picker')
      picker
        .style('top', e.clientY + 'px')
        .style('left', e.clientX + 'px')
    },
    cssColor(color) {
      if (this.useMaterialPalette) {
        return colors[_.camelCase(color)] ? colors[_.camelCase(color)].base
          : 'rgba(0, 0, 0, 0)'
      } else {
        return color
      }
    }
  },
  mounted() {
    this.selected = this.value
  }
}
</script>

<style scoped>
.colorpicker-layout {
  margin: 4px;
  width: 24px;
  height: 24px;
}

.colorpicker-color {
  width: 24px;
  height: 24px;
  border: 1px solid gainsboro;
}

.colorpicker-color:hover {
  border: 1px solid black;
}

.colorpicker-picker {
  position: fixed;
  margin: 1px;
  display: flex;
  align-items: center;
  flex-wrap: wrap;
  width: 124px;
  border: 1px solid gainsboro;
  background-color: rgba(255, 255, 255, 0.8);
  z-index: 10;
}

.colorpicker-color:hover {
  border: 1px solid black;
}
</style>
