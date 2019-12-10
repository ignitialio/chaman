<template>
  <div :id="id" class="imgsel-layout">
    <img class="imgsel-img" :src="fileURL" alt=""/>

    <input type="file" @change="handleFilesSelection" class="imgsel-input"/>
  </div>
</template>

<script>
import * as d3 from 'd3'
import ss from 'socket.io-stream'

export default {
  name: 'imgsel',

  props: {
    value: String,
    width: Number,
    height: Number,
    maxSize: {
      type: Number,
      default: 250
    },
    defaultImageUrl: String
  },

  data: () => ({
    id: 'imgsel_' + Math.random().toString(36).slice(2, 10),
    fileUploaderOptions: null,
    url: null
  }),

  computed: {
    fileURL() {
      if (this.url && this.url.match('api/uploads')) {
        return this.url + '&token=' + localStorage.token
      }

      return this.url
    }
  },

  methods: {
    handleFilesSelection(evt) {
      let files = evt.target.files

      this.filesToUpload = []
      let done = []

      let handler = result => {
        if (result.err) {
          console.log('error', result)
          this.fileContent = ''
        } else {
          done.push(result)

          if (done.length === this.filesToUpload.length) {
            this.$ws.socket.off('ws:file:upload:result', handler)
            // this.$services.$emit('service:si3:event:upload:done', done)
            let rest = this.$store.state.config.rest
            this.url = rest.context +
              '/uploads/' + this.$store.state.user._id + '/' + done[0].name +
              '?api_key=' + rest.apiKeys[0]

            this.$emit('input', this.url)

            console.log('all done every where', this.fileContent)
          } else {
            console.log('lenght issue', done.length, this.filesToUpload.length)
          }
        }
      }

      this.$ws.socket.on('ws:file:upload:result', handler)

      for (let file of files) {
        file.progress = 0

        this.filesToUpload.push(file)

        let stream = ss.createStream()

        // upload a file to the server.
        ss(this.$ws.socket).emit('ws:file:upload', stream, {
          name: file.name,
          size: file.size,
          bucket: this.$utils.bucket.name,
          userId: this.$store.state.user._id
        })

        let blobStream = ss.createBlobReadStream(file)

        let size = 0

        blobStream.on('data', chunk => {
          size += chunk.length
          file.progress = parseInt(size / file.size * 100)
          this.$forceUpdate()

          let loaded = []
          for (let f of this.filesToUpload) {
            if (f.progress === 100) {
              loaded.push(f)
            }
          }
        })

        blobStream.pipe(stream)
      }
    }
  },

  mounted() {
    let root = d3.select('#' + this.id)

    root.style('width', this.width + 'px')
      .style('height', this.height + 'px')

    root.select('.imgsel-input').style('width', this.width + 'px')
      .style('height', this.height + 'px')

    root.select('.imgsel-img')
      .style('height', (this.height - 4) + 'px')

    if (!this.url) {
      this.url = this.defaultImageUrl
    }
  }
}
</script>

<style scoped>
.imgsel-layout {
  margin: 4px;
  border: 1px solid gainsboro;
  display: flex;
  align-items: center;
  justify-content: center;
}

.imgsel-input {
  position: absolute;
  opacity: 0;
}

.imgsel-img {

}
</style>
