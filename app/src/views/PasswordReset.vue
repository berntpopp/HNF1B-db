<template>
  <v-container fluid fill-height>
    <!-- container with email input to request the password reset link -->
    <v-container v-if="show_request_container">
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
                  :rules="emailRules"
                  prepend-icon="mdi-email"
                  name="mail"
                  label="Email address"
                  type="text"
                  placeholder="mail@your-institution.com"
                  v-model="email_entry"
                ></v-text-field>

                <v-btn color="primary" type="submit"> Submit </v-btn>
              </v-form>
            </v-card-text>
          </v-card>
        </v-flex>
      </v-layout>
    </v-container>
    <!-- container with email input to request the password reset link -->


    <!-- container with password change inputs -->
    <v-container v-if="show_change_container">
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
                @submit.stop.prevent="doPasswordChange()"
              >
                <v-text-field
                  prepend-icon="mdi-lock"
                  :append-icon="show_pass_1 ? 'mdi-eye' : 'mdi-eye-off'"
                  :type="show_pass_1 ? 'text' : 'password'"
                  :rules="[passRules.required, passRules.min, passRules.upperChar, passRules.lowerChar, passRules.digit, passRules.special]"
                  name="password_1"
                  label="Enter your new password"
                  v-model="new_password_entry"
                  @click:append="show_pass_1 = !show_pass_1"
                ></v-text-field>

                <v-text-field
                  prepend-icon="mdi-lock"
                  :append-icon="show_pass_2 ? 'mdi-eye' : 'mdi-eye-off'"
                  :type="show_pass_2 ? 'text' : 'password'"
                  :rules="[passRules.required, passRules.min, passRules.upperChar, passRules.lowerChar, passRules.digit, passRules.special]"
                  name="password_2"
                  label="Repeat new password"
                  v-model="new_password_repeat"
                  @click:append="show_pass_2 = !show_pass_2"
                ></v-text-field>

                <v-btn color="primary" type="submit"> Submit change </v-btn>
              </v-form>
            </v-card-text>
          </v-card>
        </v-flex>
      </v-layout>
    </v-container>
    <!-- container with password change inputs -->

  </v-container>
</template>

<script>
export default {
  name: "PasswordReset",
  data() {
    return {
      valid: true,
      show_change_container: false,
      show_request_container: true,
      show_pass_1: false,
      show_pass_2: false,
      passRules: {
        required: value => !!value || 'Field is required.',
        min: v => v.length >= 8 || 'Min 8 characters',
        upperChar: v => /[A-Z]/.test(v) || 'Must contain upper characters',
        lowerChar: v => /[a-z]/.test(v) || 'Must contain lower characters',
        digit: v => /\d/.test(v) || 'Must contain digits',
        special: v => /[!@#$%^&*]/.test(v) || 'Must contain special character (!@#$%^&*)',
      },
      emailRules: [
        v => !!v || 'E-mail is required',
        v => /.+@.+\..+/.test(v) || 'E-mail must be valid',
      ],
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
        let response_reset_request = await this.axios.get(apiUrl, {});
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