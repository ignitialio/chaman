<template>
  <div class="main-layout">
    <ig-workflow class="main-workflow"></ig-workflow>
  </div>
</template>

<script>
import IGWorkflow from '../components/workflow/IGWorkflow.vue'

export default {
  data() {
    return {

    }
  },
  watch: {},
  components: {
    'ig-workflow': IGWorkflow
  },
  computed: {},
  methods: {},
  mounted() {
    // wait for login
    this.$services.waitForProperty(this.$store.state, 'user').then(async () => {
      let myunified = await this.$services.waitForService('myunified')
      let result = await myunified.myServiceMethod()
      console.log('service method result= ', result)
      let myaddon = await this.$modules.waitForModule('myaddon')
      result = await myaddon.myAddOnMethod()
      console.log('module method result= ', result)

      // check service access
      result = await myunified.myProtectedServiceMethod()

      this.$db.collection('notifications')
        .then(notificationsCollection => {
          notificationsCollection.dPut({
            text: 'Tralalalalallalalalallal bip bip',
            level: 'notification',
            username: this.$store.state.user.login.username
          }).then(response => {
            let _id = response._id
            notificationsCollection.dUpdate({ _id: _id }, {
              text: 'Tralalilalalilalilalilala bop bop',
              level: 'warning',
              username: this.$store.state.user.login.username
            }).then(response => {
              console.log(response)
            }).catch(err => console.log(err))
          }).catch(err => console.log(err))
        }).catch(err => console.log(err))
    }).catch(err => console.log(err))
  },
  beforeDestroy() {

  }
}
</script>

<style>
.main-layout {
  width: 100%;
  height: calc(100% - 0px);
}

.main-workflow {
  width: 100%;
  height: calc(100% - 0px);
}
</style>
