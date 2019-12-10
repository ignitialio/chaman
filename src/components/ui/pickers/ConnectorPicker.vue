<template>
  <div class="connectorpicker-layout">
    <img v-for="(ctype, index) in connectorTypes" :key="index"
      class="connectorpicker-thumbnail"
      :src="'/assets/thumbnails/connector-' + ctype + '.jpg'"
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
    value: {
      value: Object,
      required: true
    }
  },
  data: () => {
    return {
      type: null,
      connectorTypes: [ 'database', 'hyperasset', 'mqtt', 'http', 'file' ],
    }
  },
  watch: {
    settings: {
      handler: function(val) {
        this.$emit('input', val)
      }
    }
  },
  methods: {
    handleType(type) {
      this.type = type
      console.log(this.type)
    }
  },
  mounted() {
    this.type = _.cloneDeep(this.value)
  }
}
</script>

<style scoped>
.connectorpicker-layout {
  display: flex;
  flex-wrap: wrap;
  width: 100%;
}

.connectorpicker-thumbnail {
  width: 96px;
  height: 96px;
  margin: 4px;
  border: 1px solid dimgrey;
}

.connectorpicker-thumbnail:hover {
  border: 1px solid orange;
}

.theme--dark .connectorpicker-thumbnail:hover {
  border: 1px solid slategrey;
}

.connectorpicker-thumbnail.selected {
  border: 1px solid dodgerblue;
}

.theme--dark .connectorpicker-thumbnail.selected {
  border: 1px solid peru;
}
</style>
