import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import Tables from '../views/Tables.vue'
import Analyses from '../views/Analyses.vue'
import Search from '../views/Search.vue'
import About from '../views/About.vue'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/tables',
    name: 'Tables',
    component: Tables
  },
  {
    path: '/analyses',
    name: 'Analyses',
    component: Analyses
  },
  {
    path: '/search',
    name: 'Search',
    component: Search
  },
  {
    path: '/about',
    name: 'About',
    component: About
  }
]

const router = new VueRouter({
  routes
})

export default router
