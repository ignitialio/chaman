<template>
  <div :id="id" class="el-layout">
    <input v-if="editing" class="el-input" :value="text"
      @focusout="editing = false" @change="handleUpdate"/>
    <div v-if="!editing" class="el-text no-text-selection"
      @dblclick="handleDoubleClick">{{ text }}</div>
    <i v-if="!editing" class="el-icon material-icons"
      @click="handleEditing">edit</i>
  </div>
</template>

<script>
import * as d3 from 'd3'

export default {
  props: {
    value: String
  },
  data: () => {
    return {
      id:  'el_' + Math.random().toString(36).slice(2, 10),
      text: '',
      editing: false
    }
  },
  watch: {
    value: function(val) {
      this.text = this.value
    }
  },
  methods: {
    async handleEditing() {
      this.editing = true
      await this.$utils.waitForDOMReady('.el-input')
      d3.select('#' + this.id).select('.el-input').node().focus()
    },
    handleUpdate(e) {
      this.$emit('input', e.target.value)
      this.editing = false
    },
    handleDoubleClick(e) {
      this.$emit('dblclick', e)
    }
  },
  mounted() {
    this.text = this.value
  }
}
</script>

<style scoped>
.el-layout {
  display: flex;
  align-items: center;
  margin: 2px;
}

.el-input {
  flex: 1;
  background: none;
}

.el-input:focus {
  outline: none;
  border-bottom: 1px solid dodgerblue;
}

.theme--dark .el-input:focus {
  border-bottom: 1px solid peru;
}

.el-text {
  flex: 1;
}

.el-icon {
  margin: 4px;
  font-size: 1em;
  opacity: 0.2;
  cursor: pointer;
}

.el-icon:hover {
  opacity: 1;
}

</style>
