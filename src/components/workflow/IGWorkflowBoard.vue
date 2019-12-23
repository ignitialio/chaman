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
      @position="handleNodePostion"
      @delete="handleNodeDelete"
      @connectorStart="handleConnectorStart"
      @connectorEnd="handleConnectorEnd"
      :data.sync="node" :scale="scale"/>
  </div>
</template>

<script>
import * as d3 from 'd3'
import _ from 'lodash'

import IGWorkflowNode from './IGWorkflowNode.vue'
import IGWorkflowConnector from './IGWorkflowConnector.vue'

export default {
  name: 'ig-workworkflow-board-board',
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
      scale: 1
    }
  },
  watch: {
    'data.scale': function(val) {
      this.scale = val
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

        let node = this.nodes[_.findIndex(this.nodes, e => e.id === origin.id)]
        this.handleConnectorUpdate(node.geometry, connector, 'origin')
        node = this.nodes[_.findIndex(this.nodes, e => e.id === destination.id)]
        this.handleConnectorUpdate(node.geometry, connector, 'destination')
      } catch (err) {
        console.log('connector add failed', err)
      }
    },
    importWorkflow(data) {
      // console.log($j(data))
      this.connectors = []
      this.nodes = data.nodes

      for (let n of this.nodes) {
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
            let destNode = _.find(this.nodes, e => destIndex === e.id)
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
    handleNodeDrop(event) {
      if (event.dataTransfer.getData('text/plain')) {
        let node = JSON.parse(event.dataTransfer.getData('text/plain'))

        if (node.id) {
          let index = _.findIndex(this.nodes, e => e.id === node.id)
          this.nodes[index] = _.cloneDeep(this.nodes[index])
          // console.log(index, this.nodes[index])
        } else {
          // that's a new node
          let helpers = {
            id: 'node_' + this.$utils.uuid(),
            selected: false,
            geometry: {
              x: event.x - 48,
              y: event.y - 100
            }
          }

          node = { ...node, ...helpers}
          // copy schema for UI generation and generate empty data
          node.optionsSchema = {
            type: 'object',
            properties: _.cloneDeep(node.options)
          }

          node.options = this.$utils.generateDataFormJSONSchema(node.optionsSchema).json

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
    handleNodePostion(position, node) {
      for (let connector of this.connectors) {
        if (connector.origin.id === node.id) {
          this.handleConnectorUpdate(position, connector, 'origin')
        }

        if (connector.destination.id === node.id) {
          this.handleConnectorUpdate(position, connector, 'destination')
        }
      }

      let index = _.findIndex(this.nodes, e => e.id === node.id)
      this.nodes[index] = node
    },
    handleRemoveConnector(index) {
      let connector = this.connectors[index]
      let dest = _.find(this.nodes, e => e.id === connector.destination.id)
      let origin = _.find(this.nodes, e => e.id === connector.origin.id)

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
      let node

      for (let n of this.nodes) {
        if (n.id === connector[type].id) {
          node = n
          break
        }
      }

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
    handleNodeDelete(node) {
      let index = _.findIndex(this.nodes, e => e.id === node.id)
      this.nodes.splice(index, 1)
      let connectorsToRemove = []

      for (let i = 0; i < this.connectors.length; i++) {
        if (this.connectors[i].origin.id === node.id ||
          this.connectors[i].destination.id === node.id) {
          connectorsToRemove.push(i)
        }
      }

      this.connectors = _.filter(this.connectors,
        (e, i) => !_.includes(connectorsToRemove, i))

      console.log(this.nodes[index].id, $j(this.connectors))
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
        this.tempConnector.geometry.x2 = initWidth + (event.x - initPosX)
        this.tempConnector.geometry.y2 = initHeight + (event.y - 48 - initPosY)
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

      let connector = _.cloneDeep(this.tempConnector)
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
    }
  },
  mounted() {
    this.workflow = _.cloneDeep(this.data)

    let grid = ''
    let bb = this.$el.getBoundingClientRect()
    let aX = _.range(0, bb.width, this.data.gridSize || 40)
    let aY = _.range(0, bb.height, this.data.gridSize || 40)

    for (let x of aX) {
      for (let y of aY) {
        grid += '<circle cx="' + x + '" cy="' + y +
          '" r="1" stroke="black" stroke-width="1" fill="lightgrey" opacity="0.2"/>'
      }
    }

    this.$refs.grid.innerHTML = grid

    this._listeners = {
      onCtrl: this.handleCtrlKey.bind(this)
    }

    document.addEventListener('keydown', this._listeners.onCtrl)
    document.addEventListener('keyup', this._listeners.onCtrl)
  },
  beforeDestroy() {
    document.removeEventListener('keydown', this._listeners.onCtrl)
    document.removeEventListener('keyup', this._listeners.onCtrl)
  }
}
</script>

<style scoped>
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
</style>
