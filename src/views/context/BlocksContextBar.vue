<template>
  <div class="blocksctx-layout">
    <div style="flex: 1"></div>

    <div class="blocksctx-divider"></div>

    <v-btn icon :title="$t('Add item')" @click="handleItemAdd">
      <v-icon color="blue darken-1">add</v-icon>
    </v-btn>

    <v-btn icon :title="$t('Save item')" @click="handleItemSave" light
      :disabled="!modified">
      <v-icon color="blue darken-1">save</v-icon>
    </v-btn>

    <div class="blocksctx-divider"></div>
  </div>
</template>

<script>
export default {
  name: 'ig-blocksctx',
  data: () => {
    return {
      modified: false
    }
  },
  methods: {
    handleItemAdd() {
      this.$services.emit('view:blocks:add')
    },
    handleItemSave() {
      this.$services.emit('view:blocks:save')
    },
    handleItemModified(val) {
      this.modified = val
    }
  },
  mounted() {
    this._listeners = {
      onItemModified: this.handleItemModified.bind(this)
    }

    this.$services.on('view:blocks:modified', this._listeners.onItemModified)
  },
  beforeDestroy() {
    this.$services.off('view:blocks:modified', this._listeners.onItemModified)
    this.$services.emit('app:context:bar', null)
  }
}
</script>

<style scoped>
.blocksctx-layout {
  width: 100%;
  height: calc(100% - 0px);
  display: flex;
  justify-content: flex-end;
  align-items: center;
}

.blocksctx-search {
  outline: none;
  color: dimgray;
  border-bottom: 1px solid gainsboro;
}

.blocksctx-search:focus {
  border-bottom: 1px solid dodgerblue;
}

.blocksctx-divider {
  height: 32px;
  border-left: 1px solid gainsboro;
}

.blocksctx-title {
  margin-right: 16px;
}

.theme--light .blocksctx-title {
  color: dimgray;
}

.theme--dark .blocksctx-title {
  color: dimgray;
}

@media screen and (max-width: 800px) {

}
</style>
