<template>
  <div class="workflow-board"
    @mousedown="handleStartPan" @mouseup="handleEndPan" @mousemove="handlePan"
    @drop="handleNodeDrop" @dragover="handleNodeDragOver">

    <svg class="workflow-connectors">
      <g ref="grid" class="workflow-grid"></g>

      <ig-workworkflow-connector v-if="tempConnector" ref="dummyConnector"
        :line="tempConnector.geometry"
        class="workflow-connector-tmp"/>

      <ig-workworkflow-connector
        v-for="(connector, index) in connectors" :key="connector.id"
        :ref="'connector_' + index"
        :line="connector.geometry"
        class="workflow-connector"
        @click.stop.prevent="handleRemoveConnector(index)"/>
    </svg>

    <ig-workworkflow-node v-for="(node, index) in nodes" :key="node.id"
      :ref="node.id"
      @position="handleNodePosition"
      @delete="handleNodeDelete"
      @connectorStart="handleConnectorStart"
      @connectorEnd="handleConnectorEnd"
      @widget="handleWidgetDisplay"
      @settings="handleSettings"
      :data="node" @update:data="handleNodeUpdate(index, $event)" :scale="scale"/>

    <!-- Node settings dialog -->
    <ig-dialog v-model="settingsDialog" class="workflow-node-dialog"
      :title="$t('Node settings') + ' - ' + (selectedNode ? selectedNode.label : '')">
      <div v-if="selectedNode" class="workflow-node-dialog-content">
        <ig-form v-if="selectedNode && blockSchema" class="wfnode-form"
          :value="selectedNode" @input="handleSelectNodeUpdate"
          :schema="blockSchema" :root="selectedNode"/>

        <div v-if="selectedNode && selectedNode.service"
          class="wfnode-section">{{ $t('Options') }}</div>

        <component class="wfnode-form"
          v-if="selectedNode && selectedNode.service && $services[selectedNode.service]"
          :is="selectedNode.service"
          :node="selectedNode"
          :options="selectedNode.options"
          @update:options="handleOptions"/>

        <div v-if="selectedNode && selectedNode.service"
          class="wfnode-section">{{ $t('Test') }}</div>

        <div class="wfnode-output--test header">
          <div style="width: 200px">{{ $t('Name') }}</div>
          <div style="width: 200px">{{ $t('Type') }}</div>
          <div style="width: 200px">{{ $t('Method') }}</div>
          <div>{{ $t('Execute') }}</div>
        </div>

        <div class="wfnode-output--test"
          v-for="(output, index) in selectedNode.outputs" :key="index">
          <div style="width: 200px">{{ output.name }}</div>
          <div style="width: 200px">{{ output.type }}</div>
          <div style="width: 200px">{{ output.method }}</div>
          <v-btn icon text small color="blue lighten-1"
            @click="handleTestIO(output)">
            <v-icon>play_arrow</v-icon>
          </v-btn>
        </div>

        <div class="wfnode-output--test"
          v-for="(input, index) in selectedNode.inputs" :key="index">
          <div style="width: 200px">{{ input.name }}</div>
          <div style="width: 200px">{{ input.type }}</div>
          <div style="width: 200px">{{ input.method }}</div>
          <v-btn icon text small color="blue lighten-1"
            @click="handleTestIO(input)">
            <v-icon>play_arrow</v-icon>
          </v-btn>
        </div>

        <v-progress-linear :class="{ 'hidden': !testing }"
          indeterminate class="wfnode-progress-bar"></v-progress-linear>

        <ig-json-viewer class="wfnode-testzone" :data="testResult"/>
      </div>
    </ig-dialog>
  </div>
</template>

<script>
import find from 'lodash/find'
import findIndex from 'lodash/findIndex'
import filter from 'lodash/filter'
import range from 'lodash/range'
import cloneDeep from 'lodash/cloneDeep'
import includes from 'lodash/includes'

import IGWorkflowNode from './IGWorkflowNode.vue'
import IGWorkflowConnector from './IGWorkflowConnector.vue'

export default {
  name: 'ig-workworkflow-board',
  components: {
    'ig-workworkflow-node': IGWorkflowNode,
    'ig-workworkflow-connector': IGWorkflowConnector
  },
  props: {
    data: {
      type: Object,
      required: true
    }
  },
  data() {
    return {
      nodes: [],
      connectors: [],
      tempConnector: null,
      scale: 1,
      selectedNode: null,
      blockSchema: null,
      testing: false,
      testResult: null,
      settingsDialog: false
    }
  },
  watch: {
    'data.scale': function(val) {
      this.scale = val
    },
    settingsDialog: function(val) {
      this.testResult = null
    }
  },
  methods: {
    async _createConnector(origin, destination) {
      let connector =  {
        id: this.$utils.uuid(),
        origin: {
          id: origin.id,
          slot: origin.index
        },
        geometry: {
          x1: 0,
          y1: 0,
          x2: 0,
          y2: 0,
        },
        destination: {
          id: destination.id,
          slot: destination.index
        }
      }

      this.connectors.push(connector)

      try {
        await this.$utils.waitForProperty(this.$refs,
          'connector_' + (this.connectors.length - 1))

        let node = this.nodes[findIndex(this.nodes, e => e.id === origin.id)]
        this.handleConnectorUpdate(node.geometry, connector, 'origin')
        node = this.nodes[findIndex(this.nodes, e => e.id === destination.id)]
        this.handleConnectorUpdate(node.geometry, connector, 'destination')
      } catch (err) {
        console.log('connector add failed', err)
      }
    },
    importWorkflow(data) {
      this.connectors = []
      this.nodes = data.nodes

      for (let n of this.nodes) {
        this.$services[n.service].addInstance(n.instance).catch(err => {
          console.log(err)
        })

        /*
        .then(() => {
          console.log('instance created for node [%s].[%s]', n.label, n.id)
        })
        */

        if (!n.outputs) continue
        for (let o = 0; o < n.outputs.length; o++) {
          let origin = {
            id: n.id,
            index: o
          }

          if (!n.outputs[o].destinations) {
            console.log('WARNING: no destination for that output', n.name, o)
            continue
          }

          for (let destIndex of n.outputs[o].destinations) {
            let destNode = find(this.nodes, e => destIndex === e.id)
            let destSlotIndex

            for (let i = 0; i < destNode.inputs.length; i++) {
              if (destNode.inputs[i].origins.indexOf(n.id) !== -1) {
                destSlotIndex = i
                break
              }
            }

            let dest = {
              id: destNode.id,
              index: destSlotIndex
            }

            this._createConnector(origin, dest)
            // console.log($j(origin), $j(dest))
          }
        }
      }
    },
    handleNodeDragOver(event) {
      event.preventDefault()
    },
    handleNodeUpdate(index, val) {
      this.nodes[index] = val
      let workflow = {
        ...this.data,
        ...{
          nodes: this.nodes
        }
      }

      this.$emit('update:data', workflow)
      this.$forceUpdate()
    },
    async handleNodeDrop(event) {
      if (event.dataTransfer.getData('text/plain')) {
        let node = JSON.parse(event.dataTransfer.getData('text/plain'))

        if (node.id) {
          let index = findIndex(this.nodes, e => e.id === node.id)
          this.nodes[index] = cloneDeep(this.nodes[index])
          // console.log(index, this.nodes[index])
        } else {
          // that's a new node
          let helpers = {
            id: this.$utils.uuid(),
            selected: false,
            geometry: {
              x: event.x - 48,
              y: event.y - 100
            }
          }

          node = { ...node, ...helpers }
          // copy schema for UI generation and generate empty data

          try {
            await this.$services[node.service].addInstance(helpers.id)
            node.instance = helpers.id
            node.options = await this.$services[node.service].getDefaultSettings()
          } catch (err) {
            // silently fails: no multinstance
            console.log(err, 'no multiinstance for service [%s]', node.service)
          }

          // console.log($j(node))
          this.nodes.push(node)
        }
      }

      this.$emit('update:data', {
        ...this.data,
        ...{
          nodes: this.nodes
        }
      })
    },
    handleNodePosition(position, node) {
      for (let connector of this.connectors) {
        if (connector.origin.id === node.id) {
          this.handleConnectorUpdate(position, connector, 'origin')
        }

        if (connector.destination.id === node.id) {
          this.handleConnectorUpdate(position, connector, 'destination')
        }
      }

      let index = findIndex(this.nodes, e => e.id === node.id)
      this.nodes[index] = node
    },
    handleRemoveConnector(index) {
      let connector = this.connectors[index]
      let dest = find(this.nodes, e => e.id === connector.destination.id)
      let origin = find(this.nodes, e => e.id === connector.origin.id)

      for (let output of origin.outputs) {
        if (output.destinations) {
          let oi = output.destinations.indexOf(dest.id)
          if (oi !== -1) {
            output.destinations.splice(oi, 1)
          }
        }
      }

      for (let input of dest.inputs) {
        if (input.origins) {
          let ii = input.origins.indexOf(origin.id)
          if (ii !== -1) {
            input.origins.splice(ii, 1)
          }
        }
      }

      this.connectors.splice(index, 1)

      this.$emit('update:data', {
        ...this.data,
        ...{
          nodes: this.nodes
        }
      })
    },
    handleConnectorUpdate(nodePosition, connector, type) {
      /* let node

      for (let n of this.nodes) {
        if (n.id === connector[type].id) {
          node = n
          break
        }
      } */

      let nodeEl = this.$refs[connector[type].id][0]
      let slotEl = nodeEl.getSlotElement(type === 'origin' ? 'output' : 'input',
        connector[type].slot)
      let bbSlot = slotEl.getBoundingClientRect()
      let bbNode = nodeEl.$el.getBoundingClientRect()
      let dy = nodePosition.y + connector[type].slot * 21 + 4

      if (type === 'origin') {
        connector.geometry.x1 = nodePosition.x + bbNode.width
        connector.geometry.y1 = dy + bbSlot.height
      } else {
        connector.geometry.x2 = nodePosition.x
        connector.geometry.y2 = dy + bbSlot.height
      }
    },
    async handleNodeDelete(node) {
      let index = findIndex(this.nodes, e => e.id === node.id)
      this.nodes.splice(index, 1)
      let connectorsToRemove = []

      for (let i = 0; i < this.connectors.length; i++) {
        if (this.connectors[i].origin.id === node.id ||
          this.connectors[i].destination.id === node.id) {
          connectorsToRemove.push(i)
        }
      }

      this.connectors = filter(this.connectors,
        (e, i) => !includes(connectorsToRemove, i))

      try {
        await this.$services[node.service].removeInstance(node.instance)
      } catch (err) {
        // silently fails: no multinstance
        console.log(err, 'no multiinstance for service [%s]', node.service)
      }

      console.log('deleted', node.id, $j(this.connectors))
    },
    handleConnectorStart(nodeId, nodeEl, index, startPosition) {
      this.tempConnector = {
        id: this.$utils.uuid(),
        origin: {
          id: nodeId,
          slot: index
        },
        geometry: {
          x1: startPosition.x,
          y1: startPosition.y - 48,
          x2: startPosition.x,
          y2: startPosition.y - 48,
        },
        destination: {
          id: null,
          slot: null
        }
      }

      let initPosX = this.tempConnector.geometry.x1
      let initPosY = this.tempConnector.geometry.y1
      let initWidth = this.tempConnector.geometry.x2
      let initHeight = this.tempConnector.geometry.y2

      this.handleOnConnectorMouseMove = event => {
        if (this.tempConnector) {
          this.tempConnector.geometry.x2 = initWidth + (event.x - initPosX)
          this.tempConnector.geometry.y2 = initHeight + (event.y - 48 - initPosY)
        } else {
          this.$el.removeEventListener('mousemove', this.handleOnConnectorMouseMove)
        }
      }

      this.$el.addEventListener('mousemove', this.handleOnConnectorMouseMove)
    },
    handleConnectorEnd(nodeId, nodeEl, index, startPosition) {
      if (nodeId === undefined) {
        this.tempConnector = null
        return
      } // connector cancelled

      this.tempConnector.destination = {
        id: nodeId,
        slot: index
      }

      let connector = cloneDeep(this.tempConnector)
      this.connectors.push(connector)

      let node
      for (let n of this.nodes) {
        if (n.id === connector.destination.id) {
          n.inputs[connector.destination.slot].origins =
            n.inputs[connector.destination.slot].origins || []

          n.inputs[connector.destination.slot].origins.push(connector.origin.id)
          node = n
        }

        if (n.id === connector.origin.id) {
          n.outputs[connector.origin.slot].destinations =
            n.outputs[connector.origin.slot].destinations || []
          n.outputs[connector.origin.slot].destinations.push(connector.destination.id)
        }
      }

      this.handleConnectorUpdate(node.geometry, connector, 'destination')

      this.$el.removeEventListener('mousemove', this.handleOnConnectorMouseMove)
      this.handleOnConnectorMouseMove = null
      this.tempConnector = null

      this.$emit('update:data', {
        ...this.data,
        ...{
          nodes: this.nodes
        }
      })
    },
    handleCtrlKey(event) {
      if (event.ctrlKey) {
        this.$el.style.cursor = 'grab'
      } else {
        this.$el.style.cursor = 'auto'
      }
    },
    handleStartPan(event) {
      if (event.ctrlKey) {
        this.panInitX = event.x
        this.panInitY = event.y
        this.panning = true

        this.bbInit = this.$el.getBoundingClientRect()
      }
    },
    handlePan(event) {
      if (event.ctrlKey && this.panning) {
        let dx = event.x - this.panInitX
        let dy = event.y - this.panInitY
        let wh = window.innerWidth
        let vh = window.innerHeight - 48
        if (this.bbInit.x + dx <= 0) {
          if (wh <= this.bbInit.width + (this.bbInit.x + dx)) {
            this.$el.style.left = (this.bbInit.x + dx) + 'px'
          } else {
            this.$el.style.left = (wh - this.bbInit.width) + 'px'
          }
        } else {
          this.$el.style.left = 0
        }

        if (this.bbInit.y + dy <= 0) {
          if (vh <= this.bbInit.height + (this.bbInit.y + dy)) {
            this.$el.style.top = (this.bbInit.y + dy) + 'px'
          } else {
            this.$el.style.top = (vh - this.bbInit.height) + 'px'
          }
        } else {
          this.$el.style.top = 0
        }
      }
    },
    handleEndPan(event) {
      this.panning = false
    },
    handleWidgetDisplay(node) {
      this.$emit('widget', node)
    },
    handleTestIO(io) {
      this.testResult = undefined
      this.testing = true

      switch (io.type) {
        case 'rpc':
          this.$services[this.selectedNode.service]
            .callEventuallyBoundMethod(io.method).then(result => {
              this.testResult = result
              this.testing = false
            }).catch(err => {
              this.testResult = { err: '' + err }
              this.testing = false
            })
          break
      }
    },
    handleSelectNodeUpdate(val) {
      let idx = findIndex(this.nodes, e => e.id === this.selectedNode.id)
      this.handleNodeUpdate(idx, val)
      this.selectedNode = this.nodes[idx]
    },
    handleOptions(val) {
      let idx = findIndex(this.nodes, e => e.id === this.selectedNode.id)
      this.nodes[idx].options = val
      this.handleNodeUpdate(idx, this.nodes[idx])
      this.selectedNode = this.nodes[idx]
    },
    handleSettings(node) {
      this.selectedNode = node
      this.settingsDialog = true
    },
    handleInputDataRequest(token) {
      for (let input of this.selectedNode.inputs) {
        switch (input.type) {
          case 'rpc':
            this.$services[this.selectedNode.service]
              .callEventuallyBoundMethod(input.method).then(result => {
                console.log('send data', result, input.method, input.name)
                this.$services.emit('json-picker:data:' + token, result)
              }).catch(err => {
                console.log(err)
              })
            break
        }
      }
    }
  },
  mounted() {
    fetch('data/schemas/block.schema.json').then(function(response) {
      return response.json()
    }).then(data => {
      this.blockSchema = data
    }).catch(err => console.log(err))

    this.workflow = cloneDeep(this.data)

    let grid = ''
    let bb = this.$el.getBoundingClientRect()
    let aX = range(0, bb.width, this.data.gridSize || 40)
    let aY = range(0, bb.height, this.data.gridSize || 40)

    for (let x of aX) {
      for (let y of aY) {
        grid += '<circle cx="' + x + '" cy="' + y +
          '" r="1" stroke="black" stroke-width="1" fill="lightgrey" opacity="0.2"/>'
      }
    }

    this.$refs.grid.innerHTML = grid

    this._listeners = {
      onCtrl: this.handleCtrlKey.bind(this),
      onInputDataRequest: this.handleInputDataRequest.bind(this)
    }

    document.addEventListener('keydown', this._listeners.onCtrl)
    document.addEventListener('keyup', this._listeners.onCtrl)

    // manage data path selection with json-picker
    this.$services.on('json-picker:data', this._listeners.onInputDataRequest)
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this._listeners.onCtrl)
    document.removeEventListener('keyup', this._listeners.onCtrl)

    this.$services.off('json-picker:data', this._listeners.onInputDataRequest)
  }
}
</script>

<style lang="scss" scoped>
.workflow-board {
  position: absolute;
  top: 0;
  bottom: 0;
  width: 4000px;
  height: 3000px;
  overflow: hidden;
  box-sizing: border-box;
  transform-origin: top left;
  border: 1px solid rgba(231, 231, 231, 1);
}

.workflow-grid {
  width: 100%;
  height: calc(100% - 0px);
}

.workflow-connectors {
  width: 100%;
  height: calc(100% - 0px);
}

.workflow-connector {
  cursor: url('~/assets/cursors/delete.png'), auto;
  fill: none;
  stroke: grey;
  stroke-width: 2;
}

.workflow-connector:hover {
  stroke: tomato;
}

.workflow-connector-tmp {
  fill: none;
  stroke: grey;
  stroke-width: 2;
}

.workflow-node-dialog {
  .workflow-node-dialog-content {
    padding: 16px 15% 0 15%;

    .wfnode-section {
      width: 100%;
      margin: 32px 0;
      padding-left: 8px;
      font-weight: bold;
      border-bottom: 1px solid dodgerblue;
    }

    .wfnode-form {
      height: auto!important;
    }

    .wfnode-output--test {
      margin: 2px 16px;
      width: calc(100% - 32px);
      display: flex;
      justify-content: space-between;
      align-items: center;
    }

    .wfnode-output--test.header {
      background-color: rgba(0, 191, 255, 0.05);
      border-bottom: 1px solid deepskyblue;
      font-weight: bold;
    }

    .wfnode-progress-bar {
      margin: 16px 16px 0 16px;
      width: calc(100% - 32px);
    }

    .wfnode-progress-bar.hidden {
      opacity: 0;
    }

    .wfnode-testzone {
      margin: 0 16px 16px 16px;
      width: calc(100% - 32px);
      height: 300px;
      border: 1px solid gainsboro;
      background-color: rgba(191, 191, 255, 0.05);
      overflow-y: auto;

      .wfnode-error {
        color: red;
      }
    }
  }
}
</style>
