<template>
  <g v-if="line" @click="handleClick" class="wfconnector-layout">
  </g>
</template>

<script>
import { svgPath, bezierCommand } from './utils'

export default {
  name: 'IGWorkflowConnector',
  props: {
    line: Object
  },
  data: () => {
    return {
      data: null,
      transform: ''
    }
  },
  watch: {
    line: {
      handler: function(val) {
        this.update(val)
      },
      deep: true
    }
  },
  methods: {
    handleClick(event) {
      this.$emit('click', event)
    },
    update(line) {
      let d = {
        x: line.x2 - line.x1,
        y: line.y2 - line.y1
      }

      let points = [
        [line.x1, line.y1],
        [line.x1 + d.x / 4, line.y1 + d.y / 10],
        [line.x1 + d.x / 2, line.y1 + d.y / 2],
        [line.x1 + 3 * d.x / 4, line.y1 + 9 * d.y / 10],
        [line.x2, line.y2]
      ]

      this.$el.innerHTML = svgPath(points, bezierCommand)
      // this.transformArrow = `translate(${this.l.x2 - this.aCX }, ${this.l.y2 - this.aCY}) rotate(-90)`
    }
  },
  mounted() {
    this.update(this.line)
  }
}
</script>

<style scoped>
.wfconnector-layout {
  position: absolute;
  border: 1px solid red;
}
</style>
