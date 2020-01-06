<template>
  <div class="main-layout">
    <ig-workflow class="main-workflow" @run="handleRun"></ig-workflow>
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
  methods: {
    _getDestBindingEndpoint(source, destination) {
      for (let node of this.workflow.nodes) {
        if (node.id === destination) {
          for (let input of node.inputs) {
            for (let origin of input.origins) {
              if (origin === source) {
                return {
                  service: node.service,
                  method: input.method
                }
              }
            }
          }
        }
      }

      return null
    },
    async handleRun(status, workflow) {
      console.log('status', status)
      this.workflow = workflow

      for (let node of workflow.nodes) {
        if (status) {
          this.$services[node.service]
            .workflowNodePreset(node).catch(err => console.log(err))
        } else {
          this.$services[node.service]
            .workflowNodeClearPreset(node).catch(err => console.log(err))
        }

        if (!node.outputs) continue
        for (let output of node.outputs) {
          switch (output.type) {
            case 'rpc':
              if (!output.destinations) continue
              for (let destination of output.destinations) {
                let binding = this._getDestBindingEndpoint(node.id, destination)

                if (status) {
                  if (binding) {
                    console.log(node.service, this.$services[node.service], output.method, binding)
                    this.$services[binding.service]
                      .bindMethods(binding.method,
                        node.service, output.method).catch(err => {
                          console.log('bind error', node.service, $j(output), err)
                        })
                  }
                } else {
                  if (binding) {
                    this.$services[binding.service]
                      .unbindMethods(binding.method,
                        node.service, output.method).catch(err => {
                          console.log('unbind error', node.service, $j(output), err)
                        })
                  }
                }
              }
              break
          }
        }
      }
    }
  },
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
