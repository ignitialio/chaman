<template>
  <div class="blocks-layout">
    <div class="blocks-left">
      <v-progress-linear v-if="loading"
        indeterminate class="blocks-progress-bar"></v-progress-linear>

      <div class="blocks-search">
        <v-text-field id="blocks-search"
          v-model="search" :label="$t('Search')" dense flat
          hide-details solo outlined append-icon="search" clearable>
        </v-text-field>
      </div>

      <v-list class="blocks-list">
        <v-list-item v-for="block in blocks" :key="block.id"
          @click="handleSelect(block)"
          class="blocks-item"
          :class="{ 'selected': selected === block }">
          <v-list-item-avatar>
            <img :id="'icon_' + block.id" :src="icon(block)" alt=""/>
          </v-list-item-avatar>

          <v-list-item-content>
            <v-list-item-title v-text="block.name">
            </v-list-item-title>
            <v-list-item-subtitle v-text="block.description"></v-list-item-subtitle>
          </v-list-item-content>

          <v-list-item-action>
            <v-btn icon @click.stop="handleDelete(block)">
              <v-icon color='red darken-1'>clear</v-icon>
            </v-btn>
          </v-list-item-action>
        </v-list-item>
      </v-list>

      <v-btn class="blocks-button--add" dark fab small color="blue lighten-1"
        @click="handleAdd">
        <v-icon>add</v-icon>
      </v-btn>
    </div>

    <div class="blocks-right">
      <ig-form v-if="selected && schema" class="blocks-form"
        v-model="selected" :schema="schema" :root="selected"/>

      <div v-if="selected && selected.service"
        class="blocks-section">{{ $t('Settings') }}</div>

      <component v-if="selected && selected.service && $services[selected.service]"
        :is="selected.service"
        :defaultMethod="selected.type === 'Source' && selected.outputs.length === 1 ? selected.outputs[0].method : null"/>
    </div>
  </div>
</template>

<script>
import findIndex from 'lodash/findIndex'

export default {
  data() {
    return {
      blocks: [],
      search: '',
      selected: null,
      schema: null,
      loading: false
    }
  },
  watch: {
    selected: {
      handler: function(val, old) {
        if (old && val._id && ('' + val._id === '' + old._id)) {
          this.$services.emit('view:blocks:modified', true)
        } else if (!val._id) {
          this.$services.emit('view:blocks:modified', true)
        }
      },
      deep: true
    },
    'selected.service': function(val) {
      if (val) {
        this.selected.icon = '$$service(' + val + ')/assets/' +
          val + '-64.png'

        if (this.$services[val] && this.$services[val].addInstance) {
          this.$services[val].addInstance(this.selected.id).catch(err => {
            // silently fails: no multinstance
            console.log(err, 'no multiinstance for service [%s]', val)
          })
        }

        this.$forceUpdate()
      }
    },
    search: function(val) {
      this.update()
    }
  },
  methods: {
    update() {
      this.loading = true

      this.$db.collection('blocks').then(blocksCollection => {
        blocksCollection.dFind({}).then(async docs => {
          if (this.search !== '' && this.search.length > 2) {
            this.blocks =
              filter(docs, e =>
                (e.name.toLowerCase() + ' ' + e.description.toLowerCase()).match(this.search.toLowerCase()))
          } else {
            this.blocks = docs
          }

          // clean up services instances when no associated block
          for (let service in this.$services.servicesDico) {
            try {
              let instances = await this.$services[service].getInstances()

              for (let instanceId of instances) {
                let idx = findIndex(this.blocks, e => e.id === instanceId)
                if (idx === -1) {
                  await this.$services[service].removeInstance(instanceId)
                  console.log('removed instance [%s]', instanceId)
                }
              }
            } catch (err) {
              !!err
            }
          }

          this.loading = false
        }).catch(err => console.log(err))
      }).catch(err => console.log(err))
    },
    handleSelect(block) {
      this.selected = block
      console.log($j(block))
    },
    handleAdd() {
      this.selected = {
        id: this.$utils.uuid(),
        name: '',
        label: '',
        service: '',
        instance: '',
        types: [ 'Processing' ],
        description: '',
        icon: 'assets/icons/cube.png',
        inputs: [],
        outputs: []
      }
    },
    handleDelete(item) {
      this.$db.collection('blocks').then(blocksCollection => {
        blocksCollection.dDelete(item).then(result => {
          this.update()
        }).catch(err => console.log(err))
      }).catch(err => console.log(err))
    },
    handleSave() {
      this.$db.collection('blocks').then(async blocksCollection => {
        try {
          let result
          if (this.selected._id) {
            result = await blocksCollection.dUpdate({ _id: this.selected._id }, this.selected)
          } else {
            result = await blocksCollection.dPut(this.selected)
            this.selected._id = result._id
          }

          this.$services.emit('view:blocks:modified', false)
          this.$services.emit('app:notification', this.$t('Modification done'))
        } catch (err) {
          this.$services.emit('app:notification', this.$t('Modification failed'))
        }
      }).catch(err => console.log(err))
    },
    icon(block) {
      (async () => {
        let el = (await this.$utils.waitForDOMReady('#icon_' + block.id)).node()
        this.$utils.fileUrl(block.icon, 'assets/icons/cube.png', el)
      })()
      return ''
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
  overflow-y: auto;
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

.blocks-form {
  height: auto!important;
}

.blocks-section {
  margin: 32px 0;
  font-weight: bold;
  border-bottom: 1px solid gainsboro;
}

.blocks-item.selected {
  background-color: rgba(0, 191, 255, 0.05);
  border-bottom: 1px solid deepskyblue;
}

.blocks-progress-bar {
  position: absolute;
  width: 100%;
}
</style>
