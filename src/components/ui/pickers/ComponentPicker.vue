<template>
  <div class="componentpicker-layout">
    <img v-for="(ctype, index) in componentTypes" :key="index"
      class="componentpicker-thumbnail"
      :src="'/assets/thumbnails/component-' + ctype + '.jpg'"
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
      componentTypes: [ ],
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
.componentpicker-layout {
  display: flex;
  flex-wrap: wrap;
  width: 100%;
}

.componentpicker-thumbnail {
  width: 96px;
  height: 96px;
  margin: 4px;
  border: 1px solid dimgrey;
}

.componentpicker-thumbnail:hover {
  border: 1px solid orange;
}

.theme--dark .componentpicker-thumbnail:hover {
  border: 1px solid slategrey;
}

.componentpicker-thumbnail.selected {
  border: 1px solid dodgerblue;
}

.theme--dark .componentpicker-thumbnail.selected {
  border: 1px solid peru;
}
</style>
