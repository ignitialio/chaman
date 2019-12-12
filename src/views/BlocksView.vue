<template>
  <div class="blocks-layout">
    <div class="blocks-left">
      <div class="blocks-search">
        <v-text-field id="blocks-search"
          v-model="search" :label="$t('Search')" dense flat
          hide-details solo outlined append-icon="search" clearable>
        </v-text-field>
      </div>

      <v-list class="blocks-list">
        <v-list-item v-for="block in blocks" :key="block.name">
          <v-list-item-avatar>
            <v-img :src="$utils.fileUrl(block.icon)" alt=""></v-img>
          </v-list-item-avatar>

          <v-list-item-content>
            <v-list-item-title v-text="block.title">
            </v-list-item-title>
            <v-list-item-subtitle v-text="block.description"></v-list-item-subtitle>
          </v-list-item-content>
        </v-list-item>
      </v-list>

      <v-btn class="blocks-button--add" dark fab small color="blue lighten-1"
        @click="handleAdd">
        <v-icon>add</v-icon>
      </v-btn>
    </div>

    <div class="blocks-right">
      <ig-form v-if="selected && schema" v-model="selected" :schema="schema" :root="selected"/>
    </div>
  </div>
</template>

<script>

export default {
  data() {
    return {
      blocks: [],
      search: '',
      selected: null,
      schema: null
    }
  },
  watch: {
    selected: function(val) {
      this.$services.emit('view:blocks:modified')
    }
  },
  components: {

  },
  computed: {},
  methods: {
    update() {
      this.$db.collection('blocks').then(blocksCollection => {
        blocksCollection.dFind({}).then(docs => {
          this.blocks = docs
        }).catch(err => console.log(err))
      }).catch(err => console.log(err))
    },
    handleAdd() {
      this.selected = {
        "name": "",
        "service": "",
        "type": "",
        "description": "",
        "icon": "assets/icons/cube.png",
        "inputs": [],
        "outputs": []
      }
    },
    handleSave() {

    }
  },
  mounted() {
    // show contextual menu bar
    this.$services.emit('app:context:bar', 'blocks-ctx')

    this._listeners = {
      onBlockAdd: this.handleAdd.bind(this),
      onBlockSave: this.handleSave.bind(this)
    }

    fetch('data/schemas/block.schema.json').then(function(response) {
      return response.json()
    }).then(data => {
      this.schema = data
    }).catch(err => console.log(err))

    this.update()

    this.$services.on('view:blocks:save', this._listeners.onBlockSave)
    this.$services.on('view:blocks:add', this._listeners.onBlockAdd)
  },
  beforeDestroy() {
    this.$services.off('view:blocks:save', this._listeners.onBlockSave)
    this.$services.off('view:blocks:add', this._listeners.onBlockAdd)
  }
}
</script>

<style>
.blocks-layout {
  width: 100%;
  height: calc(100% - 0px);
  display: flex;
}

.blocks-left {
  width: 360px;
  height: calc(100% - 0px);
  position: relative;
  border-right: 1px solid gainsboro;
}

.blocks-search {
  width: 100%;
  height: 96px;
  background-color: rgba(0, 191, 255, 0.05);
  display: flex;
  align-items: center;
  padding: 24px 8px;
}

.blocks-list {
  width: 100%;
  height: calc(100% - 96px);
}

.blocks-button--add {
  position: absolute;
  top: 78px;
  right: 8px;
}

.blocks-right {
  flex: 1;
  height: calc(100% - 0px);
  padding: 0 32px;
  overflow-y: auto;
}
</style>
