<template>
  <v-app class="app-layout"
    :class="{ 'login': $router.currentRoute.name === 'Sign in' }"
    :dark="$store.state.ui.darkTheme">

    <div>
      <v-app-bar dense dark
        :flat="$store.state.ui.flatToolbar"
        :color="$store.state.ui.toolbarColor ">

        <v-app-bar-nav-icon v-if="$router.currentRoute.name !== 'Sign in'"
          @click="leftSidenav = !leftSidenav">
          <img class="app-logo" src="assets/chaman-32.png"/>
        </v-app-bar-nav-icon>

        <v-toolbar-title v-if="$router.currentRoute.name !== 'Sign in'"
          class="app-title">
          {{ $t($router.currentRoute.name) }}</v-toolbar-title>

        <div  v-if="$router.currentRoute.name !== 'Sign in'"
          class="app-divider"></div>

        <div  v-if="$router.currentRoute.name !== 'Sign in'"
          class="app-ctx flex-grow-1">
          <!-- Show where we are - app section -->
          <component v-if="contextComponent" :is="contextComponent"></component>
        </div>

        <div v-if="user" class="ig-clickable app-avatar-small"
          @click="showNotifications = !showNotifications">
          <v-badge overlap color="rgba(205, 133, 63, 0.8)">
            <span slot="badge" v-if="userNotifications.length > 0">
              {{ userNotifications ? userNotifications.length : 0 }}</span>

            <v-avatar :size="32" style="border: 1px solid slategrey!important;">
              <img :src="user ? $utils.fileUrl(user.picture.thumbnail) :
                'assets/user.png'" alt=""/>
            </v-avatar>
         </v-badge>
        </div>

        <div v-if="!user && $router.currentRoute.name !== 'Sign in'">
          <v-btn icon color="green" @click.stop="$router.push('/login')">
            <v-icon>open_in_browser</v-icon>
          </v-btn>
        </div>

        <v-progress-circular style="margin-left: 8px"
          v-show="!offline && !connected && user"
          indeterminate :size="20" :width="1" color="primary">
        </v-progress-circular>

        <v-icon v-show="offline && !connected && user"
          color="red">cloud_off</v-icon>
      </v-app-bar>
    </div>

    <v-navigation-drawer app dark
      :mini-variant.sync="mini"
      temporary
      ref="leftSideNav" v-model="leftSidenav">

      <v-list-item>
        <v-list-item-avatar>
          <v-img v-if="user" :src="user && user.picture && user.picture.thumbnail ?
            $utils.fileUrl(user.picture.thumbnail) :
            'assets/user.png'" alt=""></v-img>
          <v-img v-if="!user" class="app-logo" src="assets/chaman-32.png"></v-img>
        </v-list-item-avatar>

        <v-list-item-title>
          <span v-if="user">{{ $t(user.name.first + ' ' + user.name.last) }}</span>
          <v-icon v-if="user && user.role === 'admin'" color="orange">star_border</v-icon>
        </v-list-item-title>

        <v-btn icon @click.stop="mini = !mini">
          <v-icon>chevron_left</v-icon>
        </v-btn>
      </v-list-item>

      <v-divider></v-divider>

      <v-list dense>
        <template v-for="(section, key) in menuSections">
          <v-divider v-if="key !== ''"></v-divider>

          <v-subheader v-if="key !== '' && !mini && (section.anonymousAccess || !!user)"
            :key="key">
            {{ $t(key) }}</v-subheader>

          <v-list-item v-for="item in section" :key="item.index"
            v-if="(item.title && !item.hidden && (!!user && !item.hideIfLogged))
              || (item.anonymousAccess && item.title && !item.hidden && !user)"
            @click="item.event ? $services.emit(item.event) :
              $router.push({ path: item.route.path, query: item.route.query })">
              <v-list-item-action class="app-menu-item-icon">
                <v-icon v-if="!item.svgIcon">{{ item.icon }}</v-icon>
                <img :ref="'menuIcon_' + item.index" v-if="item.svgIcon"
                  class="app-menu-icon"
                  :src="$utils.fileUrl(item.svgIcon, null, $refs['menuIcon_' + item.index] ? $refs['menuIcon_' + item.index][0] : null)"
                  alt=""/>
              </v-list-item-action>

              <v-list-item-content>
                <v-list-item-title
                  :class="{ 'app-menu-item-selected':
                    $store.state.route.path === (item && item.route ? item.route.path : null) }">
                  {{ $t(item.title) }}</v-list-item-title>
              </v-list-item-content>
          </v-list-item>
        </template>
      </v-list>

      <v-list v-if="!mini" dense>
        <v-divider></v-divider>
        <v-subheader>{{ $t('Version') }}</v-subheader>

        <v-list-item v-if="packageInfo" @click="$router.push('/status')">
          <v-list-item-action>
            <img style="width: 24px; height: 24px;"
              src="assets/chaman-32.png" alt=""/>
          </v-list-item-action>
          <v-list-item-content>
            {{ packageInfo.name }} v{{ packageInfo.version }}
          </v-list-item-content>
        </v-list-item>
      </v-list>
    </v-navigation-drawer>

    <v-content class="app-view">
      <transition name="fade">
        <router-view class="app-router"></router-view>
      </transition>

      <v-snackbar v-model="notificationSnack"
        :timeout="5000">
        {{ notification }}
      </v-snackbar>

      <!-- Confirm dialog -->
      <v-dialog v-model="confirmDialog" max-width="500px"
        @close="handleConfirmClose">
        <v-card>
          <v-card-title>
            <div v-if="confirmationPrompt !== null">
              {{ confirmationPrompt }}
            </div>
          </v-card-title>

          <v-card-text>
          </v-card-text>

          <v-card-actions>
            <v-btn color="primary" flat
              @click="handleConfirm('ok')">
              {{ $t('Apply') }}
            </v-btn>

            <v-btn color="error" flat
              @click="handleConfirm('cancel')">
              {{ $t('Cancel') }}
            </v-btn>
          </v-card-actions>
        </v-card>
      </v-dialog>

      <v-bottom-sheet v-model="showNotifications">
        <v-list>
          <v-subheader>{{ $t('Notifications') }}</v-subheader>
          <v-list-item
            v-for="notification in userNotifications" :key="notification._id"
            @click="ackNotification(notification)">

            <v-list-item-avatar>
              <img :src="notification.image" alt=""/>
            </v-list-item-avatar>

            <v-list-item-title>
              <span>{{ notification.message }}</span>
              <span class="app-notification-date">
                {{ $utils.fromNow(notification._lastModified) }}</span>
            </v-list-item-title>
          </v-list-item>
        </v-list>
      </v-bottom-sheet>
    </v-content>
  </v-app>
</template>

<script>
import findIndex from 'lodash/findIndex'
import map from 'lodash/map'
import sortBy from 'lodash/sortBy'
import uniq from 'lodash/uniq'
import filter from 'lodash/filter'

import LoginView from '../views/LoginView.vue'
import MainView from '../views/MainView.vue'
import ServicesView from '../views/ServicesView.vue'
import AccessControlView from '../views/AccessControlView.vue'
import SupervisionView from '../views/SupervisionView.vue'
import ListView from '../views/ListView.vue'
import ItemView from '../views/ItemView.vue'
import BlocksView from '../views/BlocksView.vue'

import ListContextBar from '../views/context/ListContextBar.vue'
import ItemContextBar from '../views/context/ItemContextBar.vue'
import BlocksContextBar from '../views/context/BlocksContextBar.vue'

export default {
  data: () => {
    return {
      mini: true,
      showMenu: false,
      showProgressBar: false,
      notification: null,
      contextComponent: null,
      progress: 50,
      userNotifications: [],
      lastNotification: null,
      showNotifications: false,
      packageInfo: {},
      dataInfo: {},
      leftSidenav: false,
      notificationSnack: false,
      confirmDialog: false,
      confirmationPrompt: null,
      menuSections: {}
    }
  },
  watch: {
    // dev: hot reload info management
    $route(to, from) {
      let hrPath = localStorage.getItem('HR_PATH')
      if (from === hrPath) {
        localStorage.setItem('HR_PATH', undefined)
      }
    }
  },
  computed: {
    offline() {
      return this.$config.offline ? this.$config.offline.activated : false
    },
    user() {
      return this.$store.state.user
    },
    connected() {
      return this.$store.state.connected
    }
  },
  components: {
    'list-ctx': ListContextBar,
    'item-ctx': ItemContextBar,
    'blocks-ctx': BlocksContextBar
  },
  methods: {
    /*
      Shows Snack (app) notification (used from any where with this.$root)
    */
    showAppNotification(msg) {
      this.notification = msg
      this.notificationSnack = true
    },
    handleConfirmClose() {
      this.$services.emit('app:confirmation:response', 'cancel')
    },
    handleConfirm(what) {
      if (this.confirmDialog) {
        this.confirmDialog = false

        this.$services.emit('app:confirmation:response', what)
      }
    },
    handleMenuItemsAdd(items) {
      let routes = []
      let menuItems = this.$store.state.menuItems

      for (let item of items) {
        let idx = findIndex(menuItems, e => e.title === item.title)

        if (idx === -1) {
          item.selected = false
          if (item.index === undefined) {
            let indexes = map(menuItems, e => e.index)
            let maxIndex = Math.max(...indexes)
            item.index = maxIndex + 1
          }

          if (item.service) {
            let sectionHeader = findIndex(this.menuItems, e => e.service && e.header)

            if (sectionHeader >= 0) {
              menuItems.push({
                index: 200,
                header: 'Services'
              })
            }
          }

          menuItems.push(item)

          if (item.route) {
            if (!item.anonymousAccess) {
              item.route.beforeEnter = (to, from, next) => {
                let token = localStorage.getItem('token')

                if (token) {
                  next()
                } else {
                  next({ path: '/login' })
                }
              }
            }

            routes.push(item.route)
          }
        }

        let sections =
          filter(uniq(map(menuItems,
            e => e && (e.section !== undefined) ? e.section : null)), e => e !== null)

        for (let section of sections) {
          this.menuSections[section] = filter(menuItems, e => {
            return e.section === section
          })
        }
      }

      menuItems = sortBy(menuItems, 'index')
      this.$store.commit('menuItems', menuItems)

      if (routes.length > 0) {
        this.$router.addRoutes(routes)
      }

      this.$forceUpdate()

      setTimeout(this.$forceUpdate.bind(this), 500)
    },
    handleMenuItemsRemove(items) {
      let menuItems = this.$store.state.menuItems

      menuItems = filter(menuItems,
        e => findIndex(items, ee => {
          if (ee.route) {
            return e.route && e.route.path === ee.path
          } else if (ee.path) {
            return e.route && e.route.path === ee.path
          } else {
            return -1
          }
        }) < 0)

      this.$store.commit('menuItems', menuItems)

      for (let section in this.menuSections) {
        this.menuSections[section] = filter(menuItems, e => {
          return e.section === section
        })

        if (this.menuSections[section].length === 0) {
          delete this.menuSections[section]
        }
      }

      setTimeout(this.$forceUpdate.bind(this), 500)
    },
    handleNotification(data) {
      console.log('notification', data)
    },
    checkIfAdminRole() {
      this.$utils.waitForProperty(this.$store.state, 'user').then(user => {
        this.$services.waitForService(this.$config.auth.service).then(auth => {
          auth.role(user.login.username).then(role => {
            user.role = role
            this.$store.commit('user', user)
          }).catch(err => console.log('failed to get user\'s role', err))
        }).catch(err => console.log('auth service not available', err))
      }).catch(err => console.log('not connected user', err))
    }
  },
  mounted() {
    // set RPC timeout client side in accordance with config file
    this.$services.rpcTimeout = this.$config.unified.settings.rpcTimeout

    console.log('rpc timeout= ', this.$services.rpcTimeout)

    // reset menu
    this.$store.commit('menuItems', [])

    // base menu
    this.handleMenuItemsAdd([
      /* main section */
      {
        index: 0,
        title: 'Dashboard',
        icon: 'dashboard',
        anonymousAccess: true,
        section: '',
        route: {
          name: 'Dashboard',
          path: '/',
          component: MainView
        }
      },
      {
        index: 1,
        title: 'Users',
        icon: 'supervisor_account',
        anonymousAccess: true,
        section: '',
        route: {
          name: 'Users',
          path: '/users',
          component: ListView,
          query: {
            collection: 'users'
          }
        }
      },
      {
        index: 5,
        title: 'Blocks',
        svgIcon: 'assets/icons/lego-brick.png',
        anonymousAccess: false,
        section: 'Settings',
        route: {
          name: 'Blocks',
          path: '/blocks',
          component: BlocksView,
          query: {
            collection: 'myitems'
          }
        }
      },
      /* utils section */
      {
        index: 10,
        title: 'Services',
        icon: 'view_module',
        anonymousAccess: false,
        section: 'Utilities',
        route: {
          name: 'Services',
          path: '/services',
          component: ServicesView
        }
      },
      {
        index: 11,
        title: 'Access control',
        icon: 'explore',
        anonymousAccess: false,
        section: 'Utilities',
        route: {
          name: 'Access control',
          path: '/accesscontrol',
          component: AccessControlView
        }
      },
      {
        index: 12,
        title: 'Schemas',
        icon: 'device_hub',
        anonymousAccess: false,
        section: 'Utilities',
        route: {
          name: 'Schemas',
          path: '/schemas',
          component: ListView,
          query: {
            collection: 'schemas'
          }
        }
      },
      {
        index: 13,
        title: 'Status',
        icon: 'airplay',
        anonymousAccess: false,
        section: 'Utilities',
        hidden: true, /* do not show it in the menu */
        route: {
          name: 'Status',
          path: '/status',
          component: SupervisionView
        }
      },
      {
        index: 101,
        title: 'Sign out',
        icon: 'lock_open',
        anonymousAccess: false,
        section: 'Connection',
        event: 'app:signout'
      },
      {
        index: 102,
        title: 'Sign in',
        icon: 'open_in_browser',
        anonymousAccess: true,
        hideIfLogged: true,
        section: 'Connection',
        route: {
          name: 'Sign in',
          path: '/login',
          component: LoginView
        }
      },
      {
        index: 103,
        title: 'Sign up',
        icon: 'person_pin',
        anonymousAccess: true,
        hideIfLogged: true,
        section: 'Connection',
        route: {
          name: 'Sign up',
          path: '/signup',
          component: LoginView
        }
      },
      /* no menu display section */
      {
        index: 200,
        /* List route, no menu */
        title: 'List view',
        icon: 'list',
        hidden: true, /* do not show it in the menu */
        anonymousAccess: false,
        route: {
          path: '/list',
          component: ListView
        }
      },
      {
        index: 201,
        /* Item route, no menu */
        title: 'Item view',
        icon: 'view_column',
        hidden: true, /* do not show it in the menu */
        anonymousAccess: false,
        route: {
          path: '/item',
          component: ItemView
        }
      },
    ])

    // menu items registering
    this.$services.on('app:menu:add', this.handleMenuItemsAdd)
    this.$services.on('app:menu:remove', this.handleMenuItemsRemove)

    // update router with redirection
    this.$router.addRoutes([
      {
        path: '*',
        redirect: '/'
      }
    ])

    // app sign in event
    this.$services.on('app:signin', info => {
      this.$store.commit('user', info.user)
      localStorage.setItem('token', info.token)
      // determine if admin role when login
      this.checkIfAdminRole()

      this.$router.push('/')
    })

    // app sign out event
    this.$services.on('app:signout', () => {
      this.$ws.resetLocalCredentials()
    })

    // user notifications handle
    this.$ws.socket.on('service:event:dlake:notifications:add',
      this.handleNotification)

    // determine if admin role when authentication without login
    this.checkIfAdminRole()

    // context bar management
    this.$services.on('app:context:bar', ctxComponent => {
      // use null to disable
      this.contextComponent = ctxComponent
    })

    // application notifications
    this.$services.on('app:notification', message => {
      this.notification = message
      this.notificationSnack = true
    })

    // progress bar events
    this.$services.on('app:progress:show', show => {
      this.showProgressBar = show
      this.$forceUpdate()
    })

    this.$services.on('app:progress', val => {
      this.progress = val
    })

    this.$modules.waitForModule('utils').then(utils => {
      utils.appInfo().then(packageJson => {
        this.packageInfo = packageJson
      }).catch(err => console.log('failed to get app info', err))
    }).catch(err => console.log('utils service module not available', err))

    if (this.$store.state.user) {
      this.$db.collection('users').then(users => {
        this.$utils.waitForProperty(this.$store.state, 'user').then(async () => {
          let nu = await users.dGet({ 'login.username': this.$store.state.user.username })
          this.$store.commit('user', nu)
          // BUG: persisted state b*ing -> no more persisted state: to be tested
          /* setTimeout(() => {
            this.$store.commit('user', nu)
          }, 1000) */
        })
      }).catch(err => console.log(err))
    }

    // inform services about ready status
    // now services can add their stuff like menus, for example
    this.$services.appReady = true
    this.$services.emit('app:ready')

    // dev Hot Reload
    setTimeout(() => {
      let hrPath = localStorage.getItem('HR_PATH')
      if (hrPath) {
        localStorage.setItem('HR_PATH', '')
        this.$router.push(hrPath)
      }
    }, 500)
  }
}
</script>

<style scoped>
.app-layout {
  background: white!important;
}

.app-layout.login {
  background-image: url(~/assets/bk_aerial.jpg)!important;
  background-size: cover!important;
  background-position: center!important;
  background-repeat: no-repeat!important;
}

.app-view {
  height: 100vh!important;
}

.app-ctx {
  height: calc(100% - 0px);
  overflow: hidden;
}

.app-title {
  user-select: none;
  color: dimgray;
}

.app-divider {
  height: 32px;
  border-left: 1px solid gainsboro;
  margin: 0 32px;
}

.app-router {
  top: 48px;
  height: calc(100% - 48px);
}

.app-avatar-small {
  margin-left: 8px;
}

.app-menu-icon {
  width: 24px;
  height: 24px;
}

@media screen and (max-width: 800px) {

}
</style>
