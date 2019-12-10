<template>
  <div class="chartpicker-layout">
    <img v-for="(ctype, index) in chartTypes" :key="index"
      class="chartpicker-thumbnail"
      :src="url(ctype)"
      @click="handleType(ctype)"
      :class="{ 'selected': type === ctype}"
      :title="ctype"/>
  </div>
</template>

<script>
import _ from 'lodash'
import * as d3 from 'd3'

export default {
  props: {
    value: String
  },
  data: () => {
    return {
      type: null,
      chartTypes: [ 'bar', 'bubble', 'column', 'heatmap', 'line', /* 'mixed', */ 'pie' ]
    }
  },
  methods: {
    url(ctype) {
      return 'assets/thumbnails/charts-' + ctype + '.jpg'
    },
    handleType(type) {
      this.type = type
      this.$emit('input', type)
    }
  },
  async mounted() {
    this.type = this.value
  }
}
</script>

<style scoped>
.chartpicker-layout {
  display: flex;
  flex-wrap: wrap;
  width: 100%;
  justify-content: center;
}

.chartpicker-thumbnail {
  width: 80px;
  height: 80px;
  margin: 4px;
  padding: 2px;
  border: 1px solid rgba(0, 0, 0, 0);
}

.chartpicker-thumbnail:hover {
  border: 1px solid orange;
}

.theme--dark .chartpicker-thumbnail:hover {
  border: 1px solid slategrey;
}

.chartpicker-thumbnail.selected {
  border: 1px solid dodgerblue;
}

.theme--dark .chartpicker-thumbnail.selected {
  border: 1px solid peru;
}
</style>
