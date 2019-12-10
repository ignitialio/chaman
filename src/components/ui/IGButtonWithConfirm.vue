<template>
  <v-btn :id="id" :text="text" :icon="!!icon"
    :small="small" :absolute="absolute" :color="color"
    @click.stop.prevent="handleClick">
    <v-icon v-if="icon"
      @mouseup.prevent.stop="handleMouseUp"
      @mousedown.prevent.stop="handleMouseDown"
      @click.prevent.stop="handleClick">{{ icon }}</v-icon>
    <div v-else>{{name}}</div>
  </v-btn>
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
</style>
