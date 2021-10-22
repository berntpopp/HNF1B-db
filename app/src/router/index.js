import Vue from 'vue'
import VueRouter from 'vue-router'
import Home from '../views/Home.vue'
import TableReports from '../views/TableReports.vue'
import TableIndividuals from '../views/TableIndividuals.vue'
import TablePublications from '../views/TablePublications.vue'
import TableVariants from '../views/TableVariants.vue'
import Analyses from '../views/Analyses.vue'
import Search from '../views/Search.vue'
import Scoring from '../views/Scoring.vue'
import About from '../views/About.vue'

Vue.use(VueRouter)

const routes = [
  {
    path: '/',
    name: 'Home',
    component: Home
  },
  {
    path: '/table_reports',
    name: 'TableReports',
    component: TableReports
  },
  {
    path: '/table_individuals',
    name: 'TableIndividuals',
    component: TableIndividuals
  },
  {
    path: '/table_publications',
    name: 'TablePublications',
    component: TablePublications
  },
  {
    path: '/table_variants',
    name: 'TableVariants',
    component: TableVariants
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
    path: '/scoring',
    name: 'Scoring',
    component: Scoring
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
