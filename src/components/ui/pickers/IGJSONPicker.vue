<template>
  <div v-if="tree" class="jsonpicker-layout">
    <div v-for="item in tree._properties" :key="item.name"
      class="jsonpicker-property">
      <span class="jsonpicker-property-name"
        @click.prevent.stop="handleHit(item)">{{ item.name}}</span>
      <span v-if="showValue"
        class="jsonpicker-property-content"> {{ item.value }}</span>
    </div>

    <div v-for="child in tree._children" :key="child.name"
      class="jsonpicker-property">
      <div class="jsonpicker-label">
        <v-icon v-if="child._childrenVisible && child._children"
          @click="child._childrenVisible = !child._childrenVisible">
          keyboard_arrow_down</v-icon>
        <v-icon v-if="!child._childrenVisible && child._children"
          @click="child._childrenVisible = !child._childrenVisible">
          keyboard_arrow_up</v-icon>
        <div v-if="!child._children" style="width: 24px; height: 24px"></div>
        <div class="jsonpicker-property-name" @click.prevent.stop="handleHit(child)">
          {{ child.name }}</div>

        <div v-if="showValue"
          class="jsonpicker-property-content"> {{child.value }}</div>
      </div>

      <json-picker :path="nextPath(child)" :parentIsArray="child._isArray"
        v-if="child._childrenVisible || !child._children"
        @pathSelection="handlePathSelection" :showValue="showValue"
        :dataAsTree="child"></json-picker>
    </div>
  </div>
</template>

<script>
import _ from 'lodash'

export default {
  props: {
    data: Object,
    dataAsTree: Object,
    showValue: Boolean,
    path: String,
    parentIsArray: Boolean
  },
  watch: {
    data: function(val) {
      if (this.data) {
        this.tree = this.buildTree('root', this.data)
        // console.log(JSON.stringify(this.tree, null, 2))
      } else {
        this.tree = this.dataAsTree
      }
    }
  },
  data: () => {
    return {
      tree: null
    }
  },
  components: {

  },
  methods: {
    buildTree(name, json) {
      let result = {
        name: name
      }

      if (typeof json === 'object') {
        let el = {}
        result._children = []
        result._childrenVisible = true
        if (Array.isArray(json)) {
          result._isArray = true
        }

        for (let p in json) {
          el[p] = { name: p }
          if (typeof json[p] === 'object') {
            result._children = result._children.concat(this.buildTree(p, json[p]))
          } else if (typeof json[p] === 'array') {
            result._children = result._children.concat(this.buildTree(p, json[p]))
          } else  {
            result._children.push({
              name: p,
              value: json[p]
            })
          }
        }
      } else {
        result = json
        result._childrenVisible = true
      }

      return result
    },
    handleHit(what) {
      let currentPath = (this.path ? this.path : '')
      if (this.parentIsArray) {
        currentPath += '[' + what.name + ']'
      } else {
        if (currentPath) {
          currentPath += '.' + what.name
        } else {
          currentPath = what.name
        }
      }

      this.$emit('pathSelection', currentPath)
      this.$services.emit('selection:jsonpath', currentPath)
    },
    handlePathSelection(which) {
      this.$emit('pathSelection', which)
      this.$services.emit('selection:jsonpath', which)
    },
    nextPath(what) {
      let currentPath = (this.path ? this.path : '')

      if (this.parentIsArray) {
        currentPath += '[' + what.name + ']'
      } else {
        if (currentPath) {
          currentPath += '.' + what.name
        } else {
          currentPath = what.name
        }
      }

      return currentPath
    }
  },
  computed: {
  },
  mounted() {
    if (this.data) {
      this.tree = this.buildTree('root', this.data)
      // console.log(JSON.stringify(this.tree, null, 2))
    } else {
      this.tree = this.dataAsTree
    }
  },
  beforeDestroy() {

  }
}
</script>

<style>
.jsonpicker-layout {
  width: 100%;
  height: calc(100% - 0);
  overflow-y: auto;
}

.jsonpicker-property {
  margin: 0px 4px;
  padding: 2px 8px;
  cursor: pointer;
}

.jsonpicker-label {
  display: flex;
  align-items: center;
}

.jsonpicker-property-name {
  padding: 1px 8px;
  border: 1px solid gainsboro;
}

.jsonpicker-property-name:hover {
  background-color: deepskyblue;
}

.jsonpicker-property-content {
  margin: 0 8px;
  font-size: 0.8em;
  font-family: monospace;
  color: gainsboro;
}
</style>
