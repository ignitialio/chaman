<template>
  <v-dialog v-model="status" fullscreen @input="handleInput">
    <v-card class="widget-groups">
      <v-toolbar dark color="blue darken-1">
        <v-btn icon dark @click.native="handleClose">
          <v-icon>close</v-icon>
        </v-btn>
        <v-toolbar-title>{{ $t('Data mapping') }}</v-toolbar-title>
        <v-spacer></v-spacer>
        <v-toolbar-items>
        </v-toolbar-items>
      </v-toolbar>

      <v-card-text class="dpdialog-content">
        <json-picker v-if="json" @pathSelection="handlePathSelection"
          showValue
          class="dpdialog-jsonpicker" :data="json"></json-picker>
      </v-card-text>
    </v-card>
  </v-dialog>
</template>

<script>
export default {
  props: {
    value: Boolean,
    json: Object
  },
  watch: {
    value: function(val) {
      this.status = val
    }
  },
  data: () => {
    return {
      status: false
    }
  },
  methods: {
    handleInput(e) {
      this.$emit('input', e)
    },
    handlePathSelection(which) {
      this.$emit('path', which)
      this.status = false
      this.$emit('input', this.status)
    },
    handleClose() {
      this.$emit('close')
    }
  },
  mounted() {
  }
}
</script>

<style scoped>
.dpdialog-jsonpicker {
  width: 50%;
  height: calc(100% - 0px);
  border-right: 1px solid gainsboro;
}

.dpdialog-content {
  height: calc(100vh - 64px);
}
</style>
