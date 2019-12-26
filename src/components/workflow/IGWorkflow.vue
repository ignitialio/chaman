<template>
  <div class="workflow-layout"
    @mousewheel="handleMouseWheel">
    <ig-workflow-board ref="board" :data.sync="workflow"/>

    <v-speed-dial v-model="workflowMenu" class="workflow-sd" absolute
      direction="top">
      <v-btn slot="activator" v-model="workflowMenu" color="blue darken-2"
        small text fab>
        <v-icon v-if="!workflowMenu">menu</v-icon>
        <v-icon v-else>clear</v-icon>
      </v-btn>

      <ig-btn-confirm class="ig-error" :title="$t('New')"
        small text icon="settings_backup_restore" @click="handleReset"></ig-btn-confirm>

      <v-btn text icon small :title="$t('Load')"
        @click="handleLoadWorkflowDialog">
        <v-icon>open_in_browser</v-icon>
      </v-btn>

      <v-btn text icon small :title="$t('Save')"
        @click="handleSaveWorkflow">
        <v-icon>save</v-icon>
      </v-btn>

      <v-btn text icon small :title="$t('Copy')"
        @click="handleCopyWorkflow">
        <v-icon>filter_none</v-icon>
      </v-btn>
    </v-speed-dial>

    <ig-workflow-palette ref="toolsPalette" :families="families" :workflow="workflow"
      @blockType="blockType = $event">
    </ig-workflow-palette>

    <div class="workflow-title">
      <v-text-field v-if="titleEditing" class="workflow-title-input"
        :label="$t('Name')" v-model="workflow.name"
        @keyup.enter="titleEditing = false" @focusout="titleEditing = false">
      </v-text-field>

      <div class="workflow-title-label"
        v-if="!titleEditing" @click="titleEditing = true">{{ workflow.name }}</div>
    </div>

    <!-- Load workflows dialog -->
    <ig-dialog v-model="loadWorkflowDialog">
      <v-card class="workflow-dialog-card">
        <v-toolbar dark color="primary">
          <v-btn icon dark @click.native="loadWorkflowDialog = false">
            <v-icon>close</v-icon>
          </v-btn>
          <v-toolbar-title>{{ $t('Workflow load') }}</v-toolbar-title>
          <v-spacer></v-spacer>
          <v-toolbar-items>
          </v-toolbar-items>
        </v-toolbar>

        <v-card-text class="workflow-thumbnails">

          <v-list class="workflow-list">
            <v-list-item v-for="(workflow, index) in workflows" :key="index"
              @click="handleLoadWorkflow(workflow)">

              <v-list-item-content>
                <v-list-item-title v-text="workflow.name"></v-list-item-title>
              </v-list-item-content>

              <v-list-item-action>
                <ig-btn-confirm class="ig-error"
                  small text icon="clear" color="red"
                  @click="handleDeleteWorkflow(workflow)"></ig-btn-confirm>
              </v-list-item-action>
            </v-list-item>
          </v-list>
        </v-card-text>
      </v-card>
    </ig-dialog>
  </div>
</template>

<script>
import _ from 'lodash'
import * as d3 from 'd3'

import utils from './utils'

import IGWorkflowBoard from './IGWorkflowBoard.vue'
import IGWorkflowPalette from './IGWorkflowPalette.vue'

export default {
  data: () => {
    return {
      id: 'workflow_' + Math.random().toString(36).slice(2, 10),
      workflowMenu: false,
      families: {},
      titleEditing: false,
      workflow: {
        name: 'workflow_' + Math.random().toString(36).slice(2, 10),
        scale: 1,
        origin: { x: 0, y: 0 },
        gridSize: 40,
        nodes: []
      },
      workflows: [],
      loadWorkflowDialog: false
    }
  },
  watch: {
    workflow: {
      handler: function(val) {
        // console.log($j(val))
      },
      deep: true
    }
  },
  components: {
    'ig-workflow-board': IGWorkflowBoard,
    'ig-workflow-palette': IGWorkflowPalette
  },
  methods: {
    handleLoadWorkflowDialog() {
      this.$db.collection('workflows').then(workflows => {
        workflows.dFind({}).then(docs => {
          this.workflows = docs
          this.loadWorkflowDialog = true
        }).catch(err => {
          console.log(err)
        })
      }).catch(err => {
        this.$services.emit('app:notification', this.$t('Load failed'))
        console.log(err)
      })
    },
    handleLoadWorkflow(workflow) {
      this.workflow = _.cloneDeep(workflow)
      this.loadWorkflowDialog = false
      this.$refs.board.importWorkflow(this.workflow)
    },
    handleDeleteWorkflow(workflow) {
      this.$db.collection('workflows').then(workflows => {
        workflows.dDelete(workflow).then(() => {
          this.workflows = _.filter(this.workflows, e => { return e._id !== workflow._id })
          this.$services.emit('app:notification', this.$t('Modification done'))
        }).catch(err => {
          this.$services.emit('app:notification', this.$t('Modification failed'))
          console.log(err)
        })
      }).catch(err => {
        this.$services.emit('app:notification', this.$t('Modification failed'))
        console.log(err)
      })
    },
    handleCopyWorkflow() {
      this.workflow._id = undefined
      this.workflow.name += ' 2'
    },
    handleSaveWorkflow() {
      this.$db.collection('workflows').then(workflows => {
        if (this.workflow._id) {
          workflows.dUpdate({ _id: this.workflow._id }, this.workflow).then(result => {
            this.$services.emit('app:notification', this.$t('Modification done'))
          }).catch(err => {
            this.$services.emit('app:notification', this.$t('Modification failed'))
            console.log(err)
          })
        } else {
          workflows.dPut(this.workflow).then(result => {
            console.log(result)
            this.workflow._id = result._id
            this.$services.emit('app:notification', this.$t('Creation done'))
          }).catch(err => {
            this.$services.emit('app:notification', this.$t('Creation failed'))
            console.log(err)
          })
        }
      }).catch(err => {
        this.$services.emit('app:notification', this.$t('Modification failed'))
        console.log(err)
      })
    },
    handleReset() {
      this.workflow = {
        name: 'workflow_' + Math.random().toString(36).slice(2, 10),
        scale: 1,
        origin: { x: 0, y: 0 },
        nodes: []
      }

      this.$refs.board.importWorkflow(this.workflow)
    },
    handleMouseWheel(event) {
      if (event.ctrlKey) {
        event.preventDefault()
        event.stopImmediatePropagation()
        if (event.wheelDelta > 0) {
          if (this.workflow.scale < 1) {
            this.workflow.scale += 0.1
          } else {
            this.workflow.scale = 1
          }
        } else {
          if (this.workflow.scale > 0.4) {
            this.workflow.scale -= 0.1
          } else {
            this.workflow.scale = 0.3
          }
        }

        this.$refs.board.$el.style.transform =
          'scale(' + this.workflow.scale.toFixed(2) + ')'
      }
    }
  },
  async mounted() {
    if (this.value && JSON.stringify(this.value) !== '{}') {
      this.workflow = _.cloneDeep(this.value)
    }
  },
  beforeDestroy() {

  }
}
</script>

<style scoped>
.workflow-layout {
  width: 100%;
  position: relative;
  overflow: hidden;
}

.workflow-sd {
  z-index: 0!important;
  position: absolute;
  bottom: 8px;
  left: 8px;
}

.workflow-title {
  position: absolute;
  bottom: -4px;
  left: 96px;
}

.workflow-title-label {
  margin-bottom: 16px;
  min-width: 200px;
  min-height: 32px;
  border: 1px solid dodgerblue;
  background-color: rgba(255, 255, 255, 0.8);
  border-radius: 4px;
  display: flex;
  align-items: center;
  justify-content: center;
  color: dodgerblue;
}

.workflow-dialog-card {
  width: 100%;
  height: calc(100% - 0px);
  border-radius: 0!important;
}
</style>
