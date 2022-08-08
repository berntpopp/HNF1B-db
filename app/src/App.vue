<template>
  <v-app id="hnf1b-db">
    <v-app-bar app>
      <v-toolbar-title>
        <v-btn x-large to="/">
          <v-img
            src="../public/HNF1B-db_logo.webp"
            max-width="184"
            max-height="40"
            alt="HNF1B database logo"
          >
            <template v-slot:placeholder>
              <v-row class="fill-height ma-0" align="center" justify="center">
                <v-progress-circular
                  indeterminate
                  color="grey lighten-5"
                ></v-progress-circular>
              </v-row>
            </template>
          </v-img>
        </v-btn>
      </v-toolbar-title>

      <v-toolbar-items class="hidden-sm-and-down">
        <v-menu offset-y>
          <template v-slot:activator="{ on }">
            <v-btn :ripple="false" text v-on="on"> Tables </v-btn>
          </template>

          <v-card>
            <v-list dense>
              <v-list-item
                v-for="table in tables"
                :key="`notification-key-${table.id}`"
                :to="table.to"
                link
              >
                <v-list-item-title>
                  {{ table.title }}
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>

        <v-menu offset-y>
          <template v-slot:activator="{ on }">
            <v-btn :ripple="false" text v-on="on"> Analyses </v-btn>
          </template>

          <v-card>
            <v-list dense>
              <v-list-item
                v-for="analysis in analyses"
                :key="`notification-key-${analysis.id}`"
                :to="analysis.to"
                link
              >
                <v-list-item-title>
                  {{ analysis.title }}
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>

        <v-btn
          :ripple="false"
          text
          v-for="item in items"
          :key="item.title"
          :to="item.to"
        >
          {{ item.title }}
        </v-btn>
      </v-toolbar-items>

      <v-spacer></v-spacer>

      <v-toolbar-items class="hidden-sm-and-down">
        <v-menu offset-y v-if="user">
          <template v-slot:activator="{ on }">
            <v-btn :ripple="false" text v-on="on">
              {{ user }}
            </v-btn>
          </template>

          <v-card>
            <v-list dense>
              <v-list-item to="User">
                <v-list-item-icon>
                  <v-icon> {{ icons.mdiAccount }} </v-icon>
                </v-list-item-icon>
                <v-list-item-content>
                  <v-list-item-title> View profile </v-list-item-title>
                </v-list-item-content>
              </v-list-item>

              <v-list-item @click="refreshWithJWT">
                <v-list-item-icon>
                  <v-icon> {{ icons.mdiRefresh }} </v-icon>
                </v-list-item-icon>
                <v-list-item-content>
                  <v-list-item-title>
                    Refresh token
                    <v-chip small>
                      {{ Math.floor(time_to_logout) }}m
                      {{
                        (
                          (time_to_logout - Math.floor(time_to_logout)) *
                          60
                        ).toFixed(0)
                      }}s
                    </v-chip>
                  </v-list-item-title>
                </v-list-item-content>
              </v-list-item>

              <v-list-item @click="doUserLogOut">
                <v-list-item-icon>
                  <v-icon> {{ icons.mdiLogout }} </v-icon>
                </v-list-item-icon>
                <v-list-item-content>
                  <v-list-item-title> Sign out </v-list-item-title>
                </v-list-item-content>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>

        <v-btn v-else :ripple="false" text key="Login" to="/login">
          Login
        </v-btn>
      </v-toolbar-items>

      <v-spacer class="hidden-md-and-up"></v-spacer>

      <!-- // collapsed toolbar for small screen devices //-->
      <v-toolbar-items class="hidden-md-and-up">
        <v-menu offset-y>
          <template v-slot:activator="{ on }">
            <v-btn :ripple="false" text v-on="on">
              <v-icon dark right> {{ icons.mdiDotsVertical }} </v-icon>
            </v-btn>
          </template>

          <v-card>
            <v-list dense>
              <v-list-item
                v-for="item in items_small"
                :key="`notification-key-${item.id}`"
                :to="item.to"
                link
              >
                <v-list-item-title>
                  {{ item.title }}
                </v-list-item-title>
              </v-list-item>
            </v-list>
          </v-card>
        </v-menu>
      </v-toolbar-items>
      <!-- // collapsed toolbar for small screen devices //-->
    </v-app-bar>

    <v-main class="grey lighten-3">
      <router-view></router-view>
    </v-main>

    <v-footer padless>
      <v-card-text class="text-center">
        <v-btn
          :ripple="false"
          v-for="footer_item in footer_items"
          :key="footer_item.icon"
          class="mx-4"
          icon
          :href="footer_item.to"
          :target="footer_item.target"
          :aria-label="footer_item.icon"
        >
          <v-icon aria-hidden="true" size="24px">
            {{ footer_item.icon }}
          </v-icon>
        </v-btn>
      </v-card-text>
    </v-footer>
  </v-app>
</template>


<script>
import { mdiAccount, mdiRefresh, mdiLogout, mdiDotsVertical, mdiGithub, mdiApi, mdiCopyright } from '@mdi/js';

export default {
  name: "hnf1b-db",
  metaInfo: {
    // if no subcomponents specify a metaInfo.title, this title will be used
    title: "HNF1B-db",
    // all titles will be injected into this template
    titleTemplate:
      "%s | HNF1B-db - The curated database for the HNF1B gene and associated diseases",
    htmlAttrs: {
      lang: "en",
    },
    meta: [
      {
        vmid: "description",
        name: "description",
        content:
          "HNF1B-db is a web-based application for comprehensive data input and analysis from patient histories or published literature specifically designed to investigate the genotypes and phenotypes in HNF1B-associated disease.",
      },
    ],
  },
  data: () => ({
    icons: {
      mdiAccount,
      mdiRefresh,
      mdiLogout,
      mdiDotsVertical,
      mdiGithub,
      mdiApi,
      mdiCopyright
    },
    user: null,
    review: false,
    admin: false,
    time_to_logout: 0,
    items: [{ title: "About", to: "/about", id: "about" }],
    items_small: [
      { title: "Individuals", to: "/table_individuals", id: "table 1" },
      { title: "Reports", to: "/table_reports", id: "table 2" },
      { title: "Publications", to: "/table_publications", id: "table 3" },
      { title: "Variants", to: "/table_variants", id: "table 4" },
      { title: "Cohort", to: "/analysis_cohort", id: "analysis 1" },
      {
        title: "Individuals",
        to: "/analysis_genotype_phenotype",
        id: "analysis 2",
      },
      { title: "About", to: "/about", id: "about" },
      { title: "Login", to: "/login", id: "login" },
    ],
    tables: [
      { title: "Individuals", to: "/table_individuals", id: "table 1" },
      { title: "Reports", to: "/table_reports", id: "table 2" },
      { title: "Publications", to: "/table_publications", id: "table 3" },
      { title: "Variants", to: "/table_variants", id: "table 4" },
    ],
    analyses: [
      {
        title: "Cohort characteristics",
        to: "/analysis_cohort",
        id: "analysis 1",
      },
      {
        title: "Genotype phenotype",
        to: "/analysis_genotype_phenotype",
        id: "analysis 2",
      },
    ],
    footer_items: [
      {
        icon: mdiGithub,
        to: "https://github.com/berntpopp/HNF1B-db",
        target: "_blank",
      },
      { icon: mdiApi, to: "/API", target: "_self" },
      {
        icon: mdiCopyright,
        to: "https://creativecommons.org/licenses/by/4.0/",
        target: "_blank",
      },
    ],
  }),
  watch: {
    // used to refresh navbar on login push
    $route(to, from) {
      if (to !== from) {
        this.isUserLoggedIn();
      }
    },
  },
  mounted() {
    this.isUserLoggedIn();

    this.interval = setInterval(() => {
      this.updateDiffs();
    }, 1000);

    this.updateDiffs();
  },
  methods: {
    isUserLoggedIn() {
      if (localStorage.user && localStorage.token) {
        this.checkSigninWithJWT();
      } else {
        localStorage.removeItem("user");
        localStorage.removeItem("token");
      }
    },
    async checkSigninWithJWT() {
      let apiAuthenticateURL = process.env.VUE_APP_API_URL + "/api/auth/signin";

      try {
        let response_signin = await this.axios.get(apiAuthenticateURL, {
          headers: {
            Authorization: "Bearer " + localStorage.getItem("token"),
          },
        });

        this.user_from_jwt = response_signin.data;

        if (
          this.user_from_jwt.user_name[0] ==
          JSON.parse(localStorage.user).user_name[0]
        ) {
          const allowed_roles = ["Administrator", "Reviewer"];
          const allowence_navigation = [
            ["Admin", "Curate", "Review"],
            ["Review"],
          ];

          this.user = JSON.parse(localStorage.user).user_name[0];

          let user_role = JSON.parse(localStorage.user).user_role[0];
          let allowence =
            allowence_navigation[allowed_roles.indexOf(user_role)];

          this.review = allowence.includes("Review");
          this.curate = allowence.includes("Curate");
          this.admin = allowence.includes("Admin");
        } else {
          localStorage.removeItem("user");
          localStorage.removeItem("token");
        }
      } catch (e) {
        console.log(e, "Error", "danger");
      }
    },
    async refreshWithJWT() {
      let apiAuthenticateURL =
        process.env.VUE_APP_API_URL + "/api/auth/refresh";

      try {
        let response_refresh = await this.axios.get(apiAuthenticateURL, {
          headers: {
            Authorization: "Bearer " + localStorage.getItem("token"),
          },
        });

        localStorage.setItem("token", response_refresh.data[0]);
        this.signinWithJWT();
      } catch (e) {
        console.log(e, "Error", "danger");
      }
    },
    async signinWithJWT() {
      let apiAuthenticateURL = process.env.VUE_APP_API_URL + "/api/auth/signin";

      try {
        let response_signin = await this.axios.get(apiAuthenticateURL, {
          headers: {
            Authorization: "Bearer " + localStorage.getItem("token"),
          },
        });

        localStorage.setItem("user", JSON.stringify(response_signin.data));
      } catch (e) {
        console.log(e, "Error", "danger");
      }
    },
    doUserLogOut() {
      if (localStorage.user || localStorage.token) {
        localStorage.removeItem("user");
        localStorage.removeItem("token");
        this.user = null;

        // based on https://stackoverflow.com/questions/57837758/navigationduplicated-navigating-to-current-location-search-is-not-allowed
        // to avoid double nvigation
        const path = `/`;
        if (this.$route.path !== path) this.$router.push({ name: "Home" });
      }
    },
    updateDiffs() {
      if (localStorage.token) {
        let expires = JSON.parse(localStorage.user).exp;
        let timestamp = Math.floor(new Date().getTime() / 1000);

        if (expires > timestamp) {
          this.time_to_logout = ((expires - timestamp) / 60).toFixed(2);
          if ([60, 180, 300].includes(expires - timestamp)) {
            console.log(
              "Refresh token.",
              "Logout in " + (expires - timestamp) + " seconds",
              "danger"
            );
          }
        } else {
          this.doUserLogOut();
        }
      }
    },
  },
};
</script>
