<template>
  <div class="imgbasedpicker-layout">
    <div class="imgbasedpicker-list">
      <img :ref="'picture_' + index"
        v-for="(ctype, index) in items" :key="index"
        class="imgbasedpicker-thumbnail"
        :src="url(ctype, index)" alt=""
        @click="handleType(ctype)"
        :class="{
          'selected': value === ((ctype && ctype.value) ? ctype.value : ctype)
        }"
        :title="ctype"/>
    </div>

    <label>{{ label }}</label>
  </div>
</template>

<script>
export default {
  props: {
    value: String,
    items: Array,
    label: String,
    properties: Object
  },
  data: () => {
    return {
      imageBasePath: null,
      imageType: null,
    }
  },
  methods: {
    url(type, index) {
      type = type.value || type
      let url = this.imageBasePath + type + '.' + this.imageType
      let data = this.$utils.fileUrl(url, null,
        this.$refs['picture_' + index] ? this.$refs['picture_' + index][0] : null)
      return ''
    },
    handleType(type) {
      type = type.value || type
      this.$emit('input', type)
      this.$services.emit('selection:enum', type)
    }
  },
  mounted() {
    for (let p in this.properties) {
      this[p] = this.properties[p]
    }
  }
}
</script>

<style scoped>
.imgbasedpicker-layout {
  display: flex;
  flex-flow: column;
  width: 100%;
  align-items: center;
  justify-content: center;
}

.imgbasedpicker-list {
  display: flex;
  flex-wrap: wrap;
  width: 100%;
  justify-content: center;
}

.imgbasedpicker-thumbnail {
  width: 80px;
  height: 80px;
  margin: 4px;
  padding: 2px;
  border: 1px solid rgba(0, 0, 0, 0);
}

.imgbasedpicker-thumbnail:hover {
  border: 1px solid orange;
}

.theme--dark .imgbasedpicker-thumbnail:hover {
  border: 1px solid slategrey;
}

.imgbasedpicker-thumbnail.selected {
  border: 1px solid dodgerblue;
}

.theme--dark .imgbasedpicker-thumbnail.selected {
  border: 1px solid peru;
}
</style>
