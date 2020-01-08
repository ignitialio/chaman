<template>
  <div v-if="value" class="dialog-layout"
    :style="'z-index: ' + zIndex">

    <div class="dialog-background"
      :style="'z-index: ' + (zIndex + 0)"></div>

    <div class="dialog-toolbar"
      :style="'z-index: ' + (zIndex + 1)">
      <div class="dialog-close">
        <v-btn icon dark @click="handleClose">
          <v-icon>close</v-icon>
        </v-btn>
      </div>

      <div>{{ title }}</div>
      <v-spacer></v-spacer>
    </div>

    <div class="dialog-content"
      :style="'z-index: ' + (zIndex + 1)">
      <slot></slot>
    </div>
  </div>
</template>

<script>
export default {
  name: 'ig-dialog',
  props: {
    value: {},
    title: {
      type: String
    },
    zIndex: {
      type: Number,
      default: 100
    }
  },
  methods: {
    handleClose() {
      this.$emit('input', null)
    }
  }
}
</script>

<style>
.dialog-layout {
  position: fixed;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: white;
}

.dialog-background {
  position: absolute;
  top: 0;
  left: 0;
  width: 100vw;
  height: 100vh;
  background-color: black;
}

.dialog-toolbar {
  position: relative;
  width: 100%;
  height: 64px;
  background-color: dodgerblue;
  display: flex;
  align-items: center;
  font-size: 1.3em;
  color: white;
}

.dialog-close {
  position: relative;
  width: 64px;
  height: 64px;
  display: flex;
  align-items: center;
  justify-content: center;
}

.dialog-content {
  position: relative;
  width: 100%;
  height: calc(100vh - 64px);
  overflow-y: auto;
  background-color: white;
}

@media screen and (max-width: 800px) {

}
</style>
