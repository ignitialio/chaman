<template>
  <div v-if="value" class="dialog-layout">
    <slot></slot>
  </div>
</template>

<script>
export default {
  name: 'ig-dialog',
  props: {
    value: {
      type: Boolean,
      default: false
    }
  },
  mounted() {

  }
}
</script>

<style>
.dialog-layout {
  position: fixed;
  top: 0;
  left: 0;
  z-index: 100;
  width: 100vw;
  height: 100vh;
  background-color: white;
}

@media screen and (max-width: 800px) {

}
</style>
