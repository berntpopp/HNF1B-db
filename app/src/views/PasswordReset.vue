<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>Reset Password</v-toolbar-title>
          </v-toolbar>
          <v-card-text>
            <v-form
              ref="form"
              v-model="valid"
              lazy-validation
              @submit.stop.prevent="requestPasswordReset()"
            >
              <v-text-field
                prepend-icon="mdi-email"
                name="mail"
                label="Email address"
                type="text"
                placeholder="mail@your-institution.com"
                v-model="email_entry"
              ></v-text-field>

              <v-btn
                color="primary"
                type="submit"
              >
                Submit
              </v-btn>
            </v-form>
          </v-card-text>
        </v-card>
      </v-flex>
    </v-layout>
  </v-container>
</template>

<script>

export default {
  name: "PasswordReset",
  data() {
    return {
      show_change_container: false,
      show_request_container: true,
      email_entry: "",
      new_password_entry: "",
      new_password_repeat: "",
      loading: true,
    };
  },
  mounted() {
    this.checkURLParameter();
  },
  methods: {
    getValidationState({ dirty, validated, valid = null }) {
      return dirty || validated ? valid : null;
    },
    async checkURLParameter() {
      this.loading = true;

      let decode_jwt = this.parseJwt(this.$route.params.request_jwt);
      let timestamp = Math.floor(new Date().getTime() / 1000);

      if (decode_jwt == null) {
        this.show_change_container = false;
        this.show_request_container = true;
      } else if (decode_jwt.exp < timestamp) {
        setTimeout(() => {
          this.$router.push("/");
        }, 1000);
      } else {
        this.show_change_container = true;
        this.show_request_container = false;
      }
      this.loading = false;
    },
    parseJwt(token) {
      // based on https://stackoverflow.com/questions/51292406/check-if-token-expired-using-this-jwt-library
      try {
        return JSON.parse(atob(token.split(".")[1]));
      } catch (e) {
        return null;
      }
    },
    async requestPasswordReset() {
      let apiUrl =
        process.env.VUE_APP_API_URL +
        "/api/user/password/reset/request?email_request=" +
        this.email_entry;

      try {
        let response_reset_request = await this.axios.get(
          apiUrl,
          {}
        );
        console.log(
          "If the mail exists your request has been send " +
            "(status " +
            response_reset_request.status +
            " (" +
            response_reset_request.statusText +
            ").",
          "Success",
          "success"
        );
      } catch (e) {
        console.log(e, "Error", "danger");
      }
      this.resetRequestForm();
    },
    resetRequestForm() {
      this.email_entry = "";
      setTimeout(() => {
        this.$router.push("/");
      }, 1000);
    },
    async doPasswordChange() {
      let apiUrl =
        process.env.VUE_APP_API_URL +
        "/api/user/password/reset/change?new_pass_1=" +
        this.new_password_entry +
        "&new_pass_2=" +
        this.new_password_repeat;
      try {
        let response = await this.axios.get(apiUrl, {
          headers: {
            Authorization: "Bearer " + this.$route.params.request_jwt,
          },
        });
      } catch (e) {
        console.log(e, "Error", "danger");
      }
      this.resetChangeForm();
    },
    resetChangeForm() {
      this.new_password_entry = "";
      this.new_password_repeat = "";
      setTimeout(() => {
        this.$router.push("/");
      }, 1000);
    },
  },
};
</script>