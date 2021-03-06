<template>
  <div v-if="schema._meta && !schema._meta.hidden && showIf(schema._meta.showIf)"
    class="ig-form"
    :class="{ 'error': error, 'removable': removable }">

    <v-btn class="ig-form-rmbut" small icon v-if="removable"
      @click="handleRemoveItem">
      <v-icon color="red darken-2">clear</v-icon>
    </v-btn>

    <div v-if="isObjectId(value) || isPrimitive(value) || value === null"
      class="ig-form-content">
      <div class="ig-form-items threequarter">
        <!-- enum selection with component -->
        <component v-if="schema.enum && schema._meta.component"
          :label="$t(schema.title || name)"
          :is="schema._meta.component.name"
          :items="translatedArray(schema.enum)"
          :properties="schema._meta.component.properties"
          :value="value" @input="handleInput"/>

        <!-- enum -->
        <v-select v-else-if="schema.enum" :label="$t(schema.title || name)"
          :items="translatedArray(schema.enum)"
          :value="value" @input="handleInput"></v-select>

        <!-- boolean -->
        <v-switch inset
          v-else-if="schema.type === 'boolean'"
          :label="$t(schema.title || name)"
          @hook:mounted="handleBooleanValue"
          :value="booleanValue" @change="handleChange"></v-switch>

        <!-- Image field -->
        <div class="ig-form-hgroup"
          v-else-if="schema._meta && schema._meta.type === 'image'">
          <img ref="imageField"
            v-if="schema._meta.showThumbnail"
            style="width: 64px; height: 64px; border: 1px solid gainsboro; margin-right: 8px;"
            :src="imageSrc"/>

          <v-text-field
            :value="value" @input="handleInput" autocomplete="off"
            :label="$t(schema.title || name)"></v-text-field>

          <ig-fileload-but :accept="schema._meta.imageType"
            :maxSize="schema._meta.maxSize"
            @input="handleFileInput" @error="handleFileError"/>

          <v-progress-linear class="ig-form-progress" v-if="fileProgress"
            :value="fileProgress"></v-progress-linear>
        </div>

        <!-- File field -->
        <div class="ig-form-hgroup"
          v-else-if="schema._meta && schema._meta.type === 'file'">
          <v-text-field
            :readonly="isReadOnly"
            :value="value" @input="handleInput" autocomplete="off"
            :label="$t(schema.title || name)"></v-text-field>

          <ig-fileload-but :accept="schema._meta.imageType"
            :maxSize="schema._meta.maxSize"
            @input="handleFileInput" @error="handleFileError"/>

          <v-progress-linear class="ig-form-progress" v-if="fileProgress"
            :value="fileProgress"></v-progress-linear>
        </div>

        <v-menu ref="datePicker"
          v-else-if="schema._meta && schema._meta.type && schema._meta.type.match(/date|time/)"
          v-model="datepickerMenu"
          :close-on-content-click="false"
          :return-value="value"
          transition="scale-transition"
          offset-y
          min-width="290px">

          <template v-slot:activator="{ on }">
            <v-text-field
              :value="new Date(value).toLocaleDateString()"
              :label="$t(schema.title || name)"
              prepend-icon="event"
              readonly
              v-on="on"
            ></v-text-field>
          </template>

          <v-date-picker :value="new Date(value).toISOString().slice(0, 10)" no-title scrollable
            @input="handleInput">
            <v-spacer></v-spacer>
            <v-btn text color="primary" @click="datepickerMenu = false">
              {{ $t('Cancel') }}</v-btn>
            <v-btn text color="primary"
              @click="$refs.datePicker.save(new Date(value).toISOString().slice(0, 10))">
              {{ $t('Accept') }}</v-btn>
          </v-date-picker>
        </v-menu>

        <!-- Source code -->
        <div class="igform-editor"
          v-else-if="schema._meta && schema._meta.type && schema._meta.type === 'code'"
          :style="'height: ' + (schema._meta.height || '300px')">
          <div style="margin-left: -25%; font-weight: bold;">{{ schema.title }}</div>
          <prism-editor ref="editor" class="igform-editor--content"
            lineNumbers :code="value" @change="handleInput"
            :language="schema._meta.language || 'js'"></prism-editor>
        </div>

        <!-- with external provider -->
        <div class="igform-selector"
          v-else-if="schema._meta && schema._meta.selection && schema._meta.selection.provider">
          <v-text-field
            :type="schema._meta.type || 'text'"
            :readonly="isReadOnly"
            :value="value" @input="handleInput" autocomplete="off"
            :label="$t(schema.title || name)"></v-text-field>

          <v-btn text icon @click="handleExternalSelectionDialog" color="blue lighten-1">
            <v-icon>play_for_work</v-icon>
          </v-btn>
        </div>

        <!-- color -->
        <div class="igform-selector"
          v-else-if="schema._meta && schema._meta.type === 'color'">
          <label style="margin-right: 4px;">{{ $t(schema.title || name) }}</label>
          <ig-color-picker :value="value" :readonly="isReadOnly"
            @input="handleInput"/>
        </div>

        <!-- with list provided by function -->
        <v-select
          v-else-if="schema._meta && schema._meta.selection && schema._meta.selection.list"
          :label="$t(schema.title || name)"
          :items="listFromFunctionItems"
          :value="$t(value)" @input="handleInput"></v-select>

        <v-text-field v-else
          :type="schema._meta.type || 'text'"
          :readonly="isReadOnly"
          :value="value" @input="handleInput" autocomplete="off"
          :label="$t(schema.title || name)"></v-text-field>
      </div>
    </div>

    <!-- next level: is Object, but not geopoint -->
    <div v-if="value && !isPrimitive(value) && schema.properties &&
      schema.type !== 'array' && schema._meta.type !== 'geopoint' && schema.properties[prop]"
      class="ig-form-next"
      v-for="(prop, index) in properties" :key="index">
      <div v-if="(value[prop] !== null && !isObjectId(value[prop])) && !isPrimitive(value[prop]) && showIf(schema.properties[prop]._meta.showIf)"
        class="ig-form-next-header">
        <div class="ig-form-next-header--text">
          {{ schema.properties[prop] ? $t(schema.properties[prop].title) : $t(prop) }}</div>
      </div>

      <ig-form :name="prop"
        :schema="schema.properties[prop]"
        class="ig-form-next-form"
        :value="value[prop]" @input="handlePropInput(prop, $event)" :root="root"></ig-form>
    </div>

    <!-- next level: is Array -->
    <div v-if="value && schema.type === 'array'"
      class="ig-form-next">
      <ig-form v-if="!Array.isArray(schema.items) && schema.items.type !== 'object' && showIf(schema.items._meta.showIf)"
        v-for="(item, index) in value" :key="index"
        :name="$t(schema.items.title || schema.items[index].name)"
        :schema="schema.items"
        class="ig-form-next-object"
        :value="item" removable @input="handleItemInput(index, $event)"
        @remove="handleRemove(index)"
        :root="root"></ig-form>

      <ig-form v-if="schema.items.type === 'object' && schema.items !== undefined && showIf(schema.items._meta.showIf)"
        v-for="(item, index) in value" :key="index"
        :name="$t(schema.items.title || schema.items[index].name) + '[' + index + ']'"
        :schema="schema.items"
        class="ig-form-next-object"
        :value="item" removable @input="handleItemInput(index, $event)"
        @remove="handleRemove(index)"
        :root="root"></ig-form>

      <ig-form v-if="itemSchema && Array.isArray(schema.items) && showIf(itemSchema._meta.showIf)"
        v-for="(itemSchema, index) in schema.items" :key="index"
        :name="$t(itemSchema.title || itemSchema.name)"
        :schema="itemSchema"
        class="ig-form-next-object"
        :value="value[index]" removable @input="handleItemInput(index, $event)"
        @remove="handleRemove(index)"
        :root="root"></ig-form>
    </div>

    <v-btn icon small style="max-width: 28px; margin: 4px 0;"
      v-if="schema.type === 'array' && !Array.isArray(schema.items)"
      @click.stop="handleAddItem">
      <v-icon color="green darken-2">add</v-icon>
    </v-btn>

    <div v-if="schema._meta.type === 'geopoint'"
      class="ig-form-geo">
      <ig-geo v-if="schema._meta.type === 'geopoint'" :height="400"
        :marker="value" @update:marker="handleGeoloc"/>
    </div>

    <!-- Selection dialog -->
    <ig-dialog v-model="selectionDialog" :zIndex="200"
      :title="$t('Select item') + ' [ ' + $t(schema.title) + ' ]'">
      <component v-if="schema._meta && schema._meta.selection"
        :is="schema._meta.selection.provider"
        :inputData="schema._meta.selection.inputData"></component>
    </ig-dialog>
  </div>
</template>

<script>
import map from 'lodash/map'
import cloneDeep from 'lodash/cloneDeep'
import ss from 'socket.io-stream'
import jsonpath from 'jsonpath'

export default {
  name: 'ig-form',
  props: {
    name: {
      type: String
    },
    value: {},
    removable: {
      type: Boolean
    },
    schema: {
      type: Object
    },
    root: {
      type: Object
    }
  },
  watch: {
    'schema._meta.type': function(val) {
      this._schema._meta.type = val

      switch (val) {
        case 'enum':
          this._schema.enum = this._schema.enum || []
          break

        case 'image':
          this._schema._meta.imageType = 'image/*'
          break

        case 'file':
          this._schema._meta.fileType = '*/*'
          break

        case 'date':
          this._schema.format = 'date'
          break

        case 'time':
          this._schema.format = 'time'
          break

        case 'datetime':
          this._schema.format = 'datetime'
          break

        default:
      }

      this.$emit('update:schema', this._schema)
    },
    'schema.enum': function(val) {
      if (this.$refs.settings) {
        this.$refs.settings.$forceUpdate()
      }
    }
  },
  data: () => {
    return {
      selectionDialog: false,
      error: false,
      /* populate selection list with helpers */
      listFromFunctionItems: [],
      /* bug on boolean value */
      booleanValue: false,
      /* data picker menu */
      datepickerMenu: false
    }
  },
  methods: {
    /* bug on v-switch */
    handleBooleanValue() {
      this.booleanValue = this.value
    },
    _updateI18N(schema) {
      if (schema._meta && schema._meta.i18n) {
        this.$i18n.addTranslations(schema._meta.i18n)
      }
    },
    translatedArray(arr) {
      return map(arr, e => {
        return {
          text: this.$t(e),
          value: e
        }
      })
    },
    isObjectId(obj) {
      let isObjectId = obj ? obj._bsontype === 'ObjectID' : false

      if (isObjectId && (this.value === obj)) {
        this.handleType('objectid')
      }

      return isObjectId
    },
    isPrimitive(obj) {
      return !(typeof obj === 'object') && !Array.isArray(obj)
    },
    handleType(val) {
      switch (val) {
        case 'objectid':
          this._schema.readOnly = true
          break

        default:
      }

      this.$emit('update:schema', this._schema)
    },
    handleInput(val) {
      this.$emit('input', val)
    },
    handlePropInput(prop, val) {
      let rVal = JSON.parse(JSON.stringify(this.value))
      rVal[prop] = val
      this.$emit('input', rVal)
    },
    handleItemInput(index, val) {
      let rVal = JSON.parse(JSON.stringify(this.value))
      rVal[index] = val
      this.$emit('input', rVal)
    },
    handleChange(event) {
      this.$emit('input', event ? event : false)
    },
    handleGeoloc(val) {
      console.log('GEOLOC', val)
      if (this._schema.type === 'object') {
        this.$emit('input', {
          latitude: val[1],
          longitude: val[0]
        })
      } else {
        this.$emit('input', val)
      }
    },
    /* adds item to an array generating fake data */
    handleAddItem() {
      let data = this.$utils.generateDataFormJSONSchema(this.schema).json
      let arr = this.value.concat([ data[0] ])

      this.$emit('input', arr)
    },
    /* detect removal request */
    handleRemoveItem() {
      this.$emit('remove')
    },
    /* proceeds to removal request */
    handleRemove(index) {
      this.value.splice(index, 1)
      this.$emit('input', this.value)
    },
    handleFileLoad(data) {
      try {
      } catch (err) {
        console.log(err)
      }
    },
    handleFileError(err) {
      this.$services.emit('app:notification', this.$t(err))
      this.error = true
    },
    handleFileInput(file) {
      this.file = file
      this.error = false
      let filename = this.file.name + '-' + this.$utils.uuid()

      let handler = result => {
        if (result.err) {
          console.log('error', result)
          this.$emit('input', '/api/s3/' + filename)
          this.$services.emit('app:notification', this.$t('failed to upload file'))
          this.error = true
        } else {
          this.$ws.socket.off('ws:file:upload:result', handler)
          this.$emit('input', '/api/s3/' + filename)

          console.log('file uploaded', filename)
        }
      }

      this.$ws.socket.on('ws:file:upload:result', handler)

      let stream = ss.createStream()

      // upload a file to the server.
      ss(this.$ws.socket).emit('ws:file:upload', stream, {
        name: filename,
        size: this.file.size,
        bucket: this.$config.store.bucket.name
      })

      let blobStream = ss.createBlobReadStream(this.file)

      let size = 0

      blobStream.on('data', chunk => {
        size += chunk.length
        this.file.progress = parseInt(size / this.file.size * 100)
      })

      blobStream.pipe(stream)
    },
    handleExternalSelectionDialog() {
      this.selectionDialog = true

      let onSelect = data => {
        if (this.schema._meta.selection.field) {
          this.$emit('input', data[this.schema._meta.selection.field])
        } else {
          this.$emit('input', data)
        }

        this.selectionDialog = false
      }

      this.$services.once(this.schema._meta.selection.event, onSelect)
    },
    listFromFunctionHelper(fct, params, paramValue, text) {
      params = map(params, e => jsonpath.query(this.root, e)[0])
      if (paramValue) {
        params[paramValue.index] = paramValue.value
      }

      let result = this.$helpers[fct].apply(this,  params)
      if (typeof result.then == 'function') {
        result.then(r => {
          if (text) {
            r = map(r, e => {
              text.match =
                text.match.replace(/\$\.(.*)/g, m => jsonpath.query(this.root, m)[0])
              text.value =
                text.value.replace(/\$\.(.*)/g, m => jsonpath.query(this.root, m)[0])

              return {
                text: e.replace(text.match, text.value),
                value: e
              }
            })
          }

          this.listFromFunctionItems = r
        }).catch(err => console.log(err))
      } else {
        if (text) {
          result = map(result, e => {
            text.match =
              text.match.replace(/\$\.(.*)/g, m => jsonpath.query(this.root, '$.' + m)[0])
            text.value =
              text.value.replace(/\$\.(.*)/g, m => jsonpath.query(this.root, '$.' + m)[0])

            return {
              text: e.replace(text.match, text.value),
              value: e
            }
          })
        }

        this.listFromFunctionItems = result
      }
    },
    showIf(showIf) {
      let check = item => {
        let value = jsonpath.query(this.root, item.jsonpath)[0]

        switch (item.condition) {
          case 'eq': return value === item.value
          case 'neq': return value !== item.value
          case 'gte': return value >= item.value
          case 'gt': return value > item.value
          case 'lte': return value <= item.value
          case 'lt': return value < item.value
        }
      }

      if (showIf) {
        if (Array.isArray(showIf)) {
          let result = check(showIf[0])
          for (let i = 1; i < showIf.length; i++) {
            if (showIf[i].operator) continue
            if (showIf[i - 1].operator) {
              switch (showIf[i - 1].operator) {
                case '&&':
                  result = result && check(showIf[i])
                  break
                case '||':
                  result = result || check(showIf[i])
                  break
              }
            }
          }

          return result
        } else {
          return check(showIf)
        }
      }

      return true
    }
  },
  async beforeMount() {
    if (!this.schema) {
      console.error('!!! no schema', this.name, global.$j(this.value))
    }

    this._updateI18N(this.schema)
    this._schema = cloneDeep(this.schema)
    this._schema._meta = this._schema._meta || { type: null }
    this.$emit('update:schema', this._schema)
    // console.log(this.name, global.$j(this._schema))
  },
  mounted() {
    // future use: sets root component for all
    if (this.$parent) {
      if (this.$parent.$options._componentTag === 'ig-form') {
        this._formRootElement = this.$parent._formRootElement
      } else {
        this._formRootElement = this.$parent.$el
      }
    }

    // vuetify issue with code tag
    setTimeout(() => {
      if (this.$refs.editor) {
        let code = this.$refs.editor.$el.getElementsByTagName('code')[0]
        code.style.boxShadow = 'none'
      }
    }, 500)

    // helpers
    if (this.schema._meta && this.schema._meta.selection &&
      this.schema._meta.selection.list) {
      let params = this.schema._meta.selection.params
      this.listFromFunctionHelper(this.schema._meta.selection.list,
        params, undefined, this.schema._meta.selection.text)

      for (let p = 0; p < params.length; p++) {
        this.$watch(params[p].replace('$', 'root'), function (val) {
          let paramValue = { index: p, value: val }
          this.listFromFunctionHelper(this.schema._meta.selection.list,
            params,
            paramValue,
            this.schema._meta.selection.text)
        })
      }
    }

    this.$forceUpdate()
  },
  computed: {
    properties() {
      if (this.value && (typeof this.value === 'object' || Array.isArray(this.value))) {
        return Object.keys(this.value)
      }

      return []
    },
    isReadOnly() {
      return !!this.schema.readOnly
    },
    fileProgress() {
      if (this.file) {
        return this.file.progress
      }

      return null
    },
    imageSrc() {
      if (this.value.match(/png|jpg|jpeg|gif/)) {
        if (this.value.match(/\$\$/)) {
          let serviceName = this.value.match(/\$\$service\((.*?)\)\/(.*)/)[1]
          if (this.$services[serviceName]) {
            (async () => {
              await this.$utils.waitForProperty(this.$refs, 'imageField')
              let el = this.$refs.imageField
              this.$utils.fileUrl(this.value, 'assets/icons/cube.png', el)
            })()
            return ''
          } else {
            return 'assets/icons/cube.png'
          }
        } else {
          return this.$utils.fileUrl(this.value, 'assets/icons/cube.png')
        }
      } else {
        return 'assets/icons/cube.png'
      }
    }
  }
}
</script>

<style scoped>
.ig-form {
  height: calc(100% - 0px);
  display: flex;
  flex-flow: column;
  position: relative;
}

.ig-form.removable {
  width: calc(100% - 48px);
  margin-left: 48px;
}

.ig-form-content {
  width: 100%;
  display: flex;
  justify-content: flex-end;
}

.ig-form-next {
  width: 100%;
  display: flex;
  flex-flow: column;
}

.ig-form-next-header {
  display: flex;
  align-items: center;
}

.ig-form-next-header--text {
  margin: 16px 0px;
  font-weight: bold;
}

.ig-form-next-header--actions {
  display: flex;
  align-items: center;
  margin-bottom: 4px;
}

.ig-form-next-form {
  width: calc(100% - 10px);
  margin: 2px 2px 2px 8px;
  border: 1px solid rgba(100, 100, 100, 0.1);
  padding: 2px 4px;
}

.ig-form-next-object {
  margin-left: 8px;
  width: calc(100% - 8px);
  border: 1px solid rgba(100, 100, 100, 0.1);
}

.ig-form-geo {
  width: 100%;
  display: flex;
  flex-flow: column;
}

.ig-form-meta {
  width: 25%;
  display: flex;
  align-items: center;
  padding: 0 8px;
}

.ig-form-hgroup {
  display: flex;
  align-items: center;
}

.ig-form-items.half {
  width: 50%;
}

.ig-form-items.threequarter {
  width: 75%;
}

.ig-form-rmbut {
  position: absolute;
  top: 4px;
  left: -48px;
  z-index: 100;
}

.igform-editor {
  position: relative;
  width: 100%;
}

.igform-editor--content {
  position: absolute;
  top: 0;
  left: 0;
}

/* does not work since dynamic update by Vuetify */
.igform-editor--content code {
  -webkit-box-shadow: none;
  box-shadow: none!important;
}

.igform-selector {
  width: 100%;
  display: flex;
  align-items: center;
}

@media screen and (max-width: 800px) {

}
</style>
