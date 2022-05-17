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
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/tables/TableReports.vue')
  },
  {
    path: '/table_individuals',
    name: 'TableIndividuals',
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/tables/TableIndividuals.vue')
  },
  {
    path: '/table_publications',
    name: 'TablePublications',
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/tables/TablePublications.vue')
  },
  {
    path: '/table_variants',
    name: 'TableVariants',
    component: () => import(/* webpackChunkName: "Tables" */ '@/views/tables/TableVariants.vue')
  },
  {
    path: '/analyses',
    name: 'Analyses',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/Analyses.vue')
  },
  {
    path: '/analysis_cohort',
    name: 'AnalysisCohort',
    component: () => import(/* webpackChunkName: "Analyses" */ '@/views/analyses/AnalysisCohort.vue')
  },
  {
    path: '/analysis_genotype_phenotype',
    name: 'AnalysisGenotypePhenotype',
    component: () => import(/* webpackChunkName: "Analyses" */ '@/views/analyses/AnalysisGenotypePhenotype.vue')
  },
  {
    path: '/search',
    name: 'Search',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/Search.vue')
  },
  {
    path: '/about',
    name: 'About',
    component: () => import(/* webpackChunkName: "Home" */ '@/views/About.vue')
  },
  {
    path: '/individual/:individual_id',
    component: () => import(/* webpackChunkName: "Pages" */ '@/views/pages/PageIndividual.vue')
  },
  {
    path: '/publication/:publication_id',
    component: () => import(/* webpackChunkName: "Pages" */ '@/views/pages/PagePublication.vue')
  },
  {
    path: '/variant/:variant_id',
    component: () => import(/* webpackChunkName: "Pages" */ '@/views/pages/PageVariant.vue')
  },
  {
    path: '/report/:report_id',
    component: () => import(/* webpackChunkName: "Pages" */ '@/views/pages/PageReport.vue')
  },
]

const router = new VueRouter({
  mode: 'history',
  base: process.env.BASE_URL,
  routes
})

export default router
