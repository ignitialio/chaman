<template>
  <div class="widgetpicker-layout">
    <img v-for="(wtype, index) in widgetTypes" :key="index"
      class="widgetpicker-thumbnail"
      :src="'/assets/thumbnails/widget-' + wtype + '.jpg'"
      @click="handleType(wtype)"
      :class="{ 'selected': type === wtype}"
      :title="wtype"/>
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
      widgetTypes: [ 'chart', 'map', 'container' ],
    }
  },
  methods: {
    handleType(type) {
      this.type = type
      this.$emit('input', type)
      console.log(this.type)
    }
  },
  mounted() {
    this.type = this.value
  }
}
</script>

<style scoped>
.widgetpicker-layout {
  display: flex;
  flex-wrap: wrap;
  width: 100%;
  justify-content: center;
}

.widgetpicker-thumbnail {
  width: 96px;
  height: 96px;
  margin: 4px;
  border: 1px solid dimgrey;
}

.widgetpicker-thumbnail:hover {
  border: 1px solid orange;
}

.theme--dark .widgetpicker-thumbnail:hover {
  border: 1px solid slategrey;
}

.widgetpicker-thumbnail.selected {
  border: 1px solid dodgerblue;
}

.theme--dark .widgetpicker-thumbnail.selected {
  border: 1px solid peru;
}
</style>
