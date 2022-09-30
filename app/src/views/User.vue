<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-spacer></v-spacer>
            <v-badge
              avatar
              overlap
              color="error"
              :icon="user_symbol[user.user_role[0]]"
            >
              <v-avatar color="indigo" size="48">
                {{ user.abbreviation[0] }}
              </v-avatar>
            </v-badge>
            <v-spacer></v-spacer>
          </v-toolbar>

          <v-card-text>
            <v-list-item-group aria-label="User information">
              <v-list-item aria-label="User name">
                Username:
                <v-spacer></v-spacer>
                <v-chip variant="info">
                  {{ user.user_name[0] }}
                </v-chip>
              </v-list-item>

              <v-list-item
                v-for="(contribution, key) in user.contributions"
                :key="`contribution-list-${contribution}`"
                :aria-label="`Curation contribution for ${contribution}`"
              >
                {{ key }}:
                <v-spacer></v-spacer>
                <v-chip small class="ma-1">
                  {{ contribution }}
                </v-chip>
              </v-list-item>

              <v-list-item aria-label="Account creation date">
                Account created:
                <v-spacer></v-spacer>
                {{ user.user_created[0] }}
              </v-list-item>

              <v-list-item
                aria-label="Account E-mail"
              > E-Mail:
                <v-spacer></v-spacer>
                {{ user.email[0] }}
              </v-list-item>

              <v-list-item aria-label="Account ORCID">
                ORCID:
                <v-spacer></v-spacer>
                <a
                  :href="'https://orcid.org/' + user.orcid[0]"
                  aria-label="Link out to the ORCID of the user"
                  target="_blank"
                >
                  {{ user.orcid[0] }}
                </a>
              </v-list-item>

              <v-list-item aria-label="Token validity and refresh option">
                Token expires:
                <v-spacer></v-spacer>
                <v-chip class="ml-1" variant="info">
                  {{ Math.floor(time_to_logout) }} m
                  {{
                    (
                      (time_to_logout - Math.floor(time_to_logout)) *
                      60
                    ).toFixed(0)
                  }}
                  s
                </v-chip>
                <v-chip
                  class="ml-1"
                  href="#"
                  variant="success"
                  pill
                  aria-label="refresh the current JWT"
                  @click="refreshWithJWT"
                >
                  <v-icon> {{ icons.mdiRefresh }} </v-icon>
                </v-chip>
              </v-list-item>
            </v-list-item-group>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>
import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";

export default {
  name: "User",
  mixins: [colorAndSymbolsMixin],
  data() {
    return {
      user: {
        user_id: [],
        user_name: [],
        email: [],
        user_role: [],
        user_created: [],
        abbreviation: [],
        orcid: [],
        exp: [],
        contributions: {},
      },
      time_to_logout: 0,
      pass_change_visible: false,
      current_password: "",
      new_password_entry: "",
      new_password_repeat: "",
    };
  },
  mounted() {
    if (localStorage.user) {
      this.user = JSON.parse(localStorage.user);

      this.interval = setInterval(() => {
        this.updateDiffs();
      }, 1000);

      this.updateDiffs();
      this.getUserContributions();
    }
  },
  methods: {
    getValidationState({ dirty, validated, valid = null }) {
      return dirty || validated ? valid : null;
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
          if (expires - timestamp == 60) {
            console.log("Refresh token.", "Logout in 60 seconds", "danger");
          }
        } else {
          this.doUserLogOut();
        }
      }
    },
    async getUserContributions() {
      let apiContributionsURL =
        process.env.VUE_APP_API_URL +
        "/api/user/" +
        this.user.user_id[0] +
        "/contributions";

      try {
        let response_contributions = await this.axios.get(apiContributionsURL, {
          headers: {
            Authorization: "Bearer " + localStorage.getItem("token"),
          },
        });

        this.user.contributions = response_contributions.data[0];

        delete this.user.contributions.abbreviation;
        delete this.user.contributions.user_id;
        delete this.user.contributions.user_name;
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
    async changePassword() {
      let apiChangePasswordURL =
        process.env.VUE_APP_API_URL +
        "/api/user/password/update?user_id_pass_change=" +
        this.user.user_id[0] +
        "&old_pass=" +
        this.current_password +
        "&new_pass_1=" +
        this.new_password_entry +
        "&new_pass_2=" +
        this.new_password_repeat;
      try {
        let response_password_change = await this.axios.put(
          apiChangePasswordURL,
          {},
          {
            headers: {
              Authorization: "Bearer " + localStorage.getItem("token"),
            },
          }
        );
        console.log(
          response_password_change.data.message +
            " (status " +
            response_password_change.status +
            ")",
          "Success",
          "success"
        );
        this.pass_change_visible = false;
      } catch (e) {
        console.log(e, "Error", "danger");
        this.pass_change_visible = false;
      }
      this.resetPasswordForm();
    },
    resetPasswordForm() {
      this.current_password = "";
      this.new_password_entry = "";
      this.new_password_repeat = "";
    },
  },
};
</script>

<style scoped>
.btn-group-xs > .btn,
.btn-xs {
  padding: 0.25rem 0.4rem;
  font-size: 0.875rem;
  line-height: 0.5;
  border-radius: 0.2rem;
}
.centered {
  display: flex;
  align-items: center;
  justify-content: center;
  min-height: calc(100vh - 100px);
}
</style>