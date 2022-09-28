// src/router/routes.js
import Vue from "vue";

import VueAxios from "vue-axios";
import axios from "axios";

Vue.use(VueAxios, axios);

export const routes = [
    {
      path: '/',
      name: 'Home',
      component: () =>
        import(
            /* webpackChunkName: "Home" */ '@/views/Home.vue'
          ),
      meta: {
        sitemap: {
          priority: 1.0,
          changefreq: "monthly",
        },
      },
    },
    {
      path: '/table_reports',
      name: 'TableReports',
      component: () =>
        import(
          /* webpackChunkName: "Tables" */ '@/views/tables/TableReports.vue'
        ),
      props: (route) => ({
        sort: route.query.sort,
        filter: route.query.filter,
        fields: route.query.fields,
        page_after: route.query.page_after,
        page_size: route.query.page_size,
        fspec: route.query.fspec,
      }),
      meta: {
        sitemap: {
          priority: 0.6,
          changefreq: "monthly",
        },
      },
    },
    {
      path: '/table_individuals',
      name: 'TableIndividuals',
      component: () =>
        import(
          /* webpackChunkName: "Tables" */ '@/views/tables/TableIndividuals.vue'
        ),
      props: (route) => ({
        sort: route.query.sort,
        filter: route.query.filter,
        fields: route.query.fields,
        page_after: route.query.page_after,
        page_size: route.query.page_size,
        fspec: route.query.fspec,
      }),
      meta: {
        sitemap: {
          priority: 0.6,
          changefreq: "monthly",
        },
      },
    },
    {
      path: '/table_publications',
      name: 'TablePublications',
      component: () =>
        import(
          /* webpackChunkName: "Tables" */ '@/views/tables/TablePublications.vue'
        ),
      props: (route) => ({
        sort: route.query.sort,
        filter: route.query.filter,
        fields: route.query.fields,
        page_after: route.query.page_after,
        page_size: route.query.page_size,
        fspec: route.query.fspec,
      }),
      meta: {
        sitemap: {
          priority: 0.6,
          changefreq: "monthly",
        },
      },
    },
    {
      path: '/table_variants',
      name: 'TableVariants',
      component: () =>
        import(
          /* webpackChunkName: "Tables" */ '@/views/tables/TableVariants.vue'
        ),
      props: (route) => ({
        sort: route.query.sort,
        filter: route.query.filter,
        fields: route.query.fields,
        page_after: route.query.page_after,
        page_size: route.query.page_size,
        fspec: route.query.fspec,
      }),
      meta: {
        sitemap: {
          priority: 0.6,
          changefreq: "monthly",
        },
      },
    },
    {
      path: '/analysis_cohort',
      name: 'AnalysisCohort',
      component: () =>
        import(
          /* webpackChunkName: "Analyses" */ '@/views/analyses/AnalysisCohort.vue'
        ),
        meta: {
          sitemap: {
            priority: 0.7,
            changefreq: "monthly",
          },
        },
    },
    {
      path: '/analysis_genotype_phenotype',
      name: 'AnalysisGenotypePhenotype',
      component: () =>
        import(
          /* webpackChunkName: "Analyses" */ '@/views/analyses/AnalysisGenotypePhenotype.vue'
        ),
        meta: {
          sitemap: {
            priority: 0.7,
            changefreq: "monthly",
          },
        },
    },
    {
      path: '/about',
      name: 'About',
      component: () =>
        import(
          /* webpackChunkName: "Home" */ '@/views/About.vue'
        ),
        meta: {
          sitemap: {
            priority: 0.5,
            changefreq: "yearly",
          },
        },
    },
    {
      path: '/search',
      name: 'Search',
      component: () =>
        import(
          /* webpackChunkName: "Tables" */ '@/views/tables/TableSearch.vue'
        ),
        props: (route) => ({
          term: route.query.term,
        }),
        meta: { sitemap: { ignoreRoute: true } },
    },
    {
      path: '/login',
      name: 'Login',
      component: () =>
        import(
          /* webpackChunkName: "User" */ '@/views/Login.vue'
        ),
        meta: {
          sitemap: {
            priority: 0.5,
            changefreq: "yearly",
          },
        },
    },
    {
      path: '/individual/:individual_id',
      component: () =>
        import(
          /* webpackChunkName: "Pages" */ '@/views/pages/PageIndividual.vue'
        ),
        meta: { sitemap: { ignoreRoute: true } },
    },
    {
      path: '/publication/:publication_id',
      component: () =>
        import(
          /* webpackChunkName: "Pages" */ '@/views/pages/PagePublication.vue'
        ),
      meta: { sitemap: { ignoreRoute: true } },
    },
    {
      path: '/variant/:variant_id',
      component: () =>
        import(
          /* webpackChunkName: "Pages" */ '@/views/pages/PageVariant.vue'
        ),
      meta: { sitemap: { ignoreRoute: true } },
    },
    {
      path: '/report/:report_id',
      component: () =>
        import(
          /* webpackChunkName: "Pages" */ '@/views/pages/PageReport.vue'
        ),
      meta: { sitemap: { ignoreRoute: true } },
    },
    {
      path: "*",
      component: () =>
        import(
          /* webpackChunkName: "Pages" */ "@/views/PageNotFound.vue"
        ),
      meta: { sitemap: { ignoreRoute: true } },
    },
    {
      path: "/API",
      name: "API",
      component: () =>
        import(
          /* webpackChunkName: "API" */ "@/views/API.vue"
        ),
      meta: {
        sitemap: {
          priority: 0.6,
          changefreq: "monthly",
        },
      },
    },
    {
      path: "/User",
      name: "User",
      component: () => import(/* webpackChunkName: "User" */ "@/views/User.vue"),
      meta: { sitemap: { ignoreRoute: true } },
      beforeEnter: (to, from, next) => {
        const allowed_roles = ["Administrator", "Reviewer"];
        let expires = 0;
        let timestamp = 0;
        let user_role = "Viewer";
  
        if (localStorage.token) {
          expires = JSON.parse(localStorage.user).exp;
          user_role = JSON.parse(localStorage.user).user_role;
          timestamp = Math.floor(new Date().getTime() / 1000);
        }
  
        if (
          !localStorage.user ||
          timestamp > expires ||
          !allowed_roles.includes(user_role[0])
        )
          next({ name: "Login" });
        else next();
      },
    },
    {
      path: "/PasswordReset/:request_jwt?",
      name: "PasswordReset",
      component: () =>
        import(/* webpackChunkName: "User" */ "@/views/PasswordReset.vue"),
      meta: { sitemap: { ignoreRoute: true } },
    },
    {
      path: "/Register",
      name: "Register",
      component: () =>
        import(/* webpackChunkName: "User" */ "@/views/Register.vue"),
      meta: {
        sitemap: {
          priority: 0.5,
          changefreq: "yearly",
        },
      },
    },
  ];