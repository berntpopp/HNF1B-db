import Vue from 'vue'
import VueRouter from 'vue-router'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Home',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/Home.vue')
  },
  {
    path: '/table_reports',
    name: 'TableReports',
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/TableReports.vue')
  },
  {
    path: '/table_individuals',
    name: 'TableIndividuals',
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/TableIndividuals.vue')
  },
  {
    path: '/table_publications',
    name: 'TablePublications',
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/TablePublications.vue')
  },
  {
    path: '/table_variants',
    name: 'TableVariants',
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/TableVariants.vue')
  },
  {
    path: '/analyses',
    name: 'Analyses',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/Analyses.vue')
  },
  {
    path: '/search',
    name: 'Search',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/Search.vue')
  },
  {
    path: '/scoring',
    name: 'Scoring',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/Scoring.vue')
  },
  {
    path: '/about',
    name: 'About',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/About.vue')
  }
]

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes
})

export default router
