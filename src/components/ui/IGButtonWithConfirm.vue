<template>
  <div :id="id" class="butwithcfm-layout"
    :class="{ 'absolute': absolute, 'isIcon': icon }" :color="color">
    <v-icon v-if="icon" :color="color"
      @mouseup.prevent.stop="handleMouseUp"
      @mousedown.prevent.stop="handleMouseDown"
      @click.prevent.stop="handleClick">{{ icon }}</v-icon>

    <v-btn v-else :id="id" :text="text"
      :small="small" :color="color"
      @mouseup.prevent.stop="handleMouseUp"
      @mousedown.prevent.stop="handleMouseDown"
      @click.stop.prevent="handleClick">
      {{name}}
    </v-btn>
  </div>
</template>

<script>
import * as d3 from 'd3'

export default {
  props: {
    name: String,
    text: Boolean,
    icon: String,
    small: Boolean,
    color: String,
    absolute: Boolean
  },
  data: () => {
    return {
      id:  'bwc_' + Math.random().toString(36).slice(2, 10)
    }
  },
  methods: {
    handleClick(e) {
      this.timeout = setTimeout(() => {
        d3.select('#' + this.id).classed('ig-blink-fast-highlighted', false)
        this.counter = 2
      }, 5000)

      this.counter--
      if (this.counter === 0) {
        clearTimeout(this.timeout)
        d3.select('#' + this.id).classed('ig-blink-fast-highlighted', false)
        this.counter = 2
        this.$emit('click', e)
      } else {
        d3.select('#' + this.id).classed('ig-blink-fast-highlighted', true)
      }
    },
    handleMouseUp(e) {
      this.$emit('mouseup', e)
    },
    handleMouseDown(e) {
      this.$emit('mousedown', e)
    }
  },
  mounted() {
    this.counter = 2
  }
}
</script>

<style scoped>
.butwithcfm-layout {
  display: flex;
  align-items: center;
  justify-content: center;
}

.butwithcfm-layout.absolute {
  position: absolute;
}

.butwithcfm-layout.isIcon {
  padding: 2px;
  border-radius: 50%;
}
</style>
