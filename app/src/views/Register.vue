<template>
  <v-container fluid fill-height>
    <!-- container with registration form -->
    <v-container>
      <v-layout align-center justify-center>
        <v-flex xs12 sm8 md4>
          <v-card class="elevation-12">
            <v-toolbar dark color="primary">
              <v-toolbar-title>Register new HNF1B-db account</v-toolbar-title>
            </v-toolbar>
            <v-card-text>
              <v-form
                ref="form"
                v-model="valid"
                lazy-validation
                @submit.stop.prevent="onSubmit()"
              >
                <!-- text field for username -->
                <v-text-field
                  :rules="userNameRules"
                  :prepend-icon="icons.mdiAccount"
                  id="username"
                  name="username"
                  label="Username"
                  type="text"
                  v-model="registration_form.user_name"
                ></v-text-field>
                <!-- text field for username -->

                <!-- text field for email -->
                <v-text-field
                  :rules="emailRules"
                  :prepend-icon="icons.mdiEmail"
                  id="mail"
                  name="mail"
                  label="Email address"
                  type="text"
                  placeholder="mail@your-institution.com"
                  v-model="registration_form.email"
                ></v-text-field>
                <!-- text field for email -->

                <!-- text field for orcid -->
                <v-text-field
                  :rules="orcidRules"
                  :prepend-icon="icons.mdiAccountSchool"
                  id="orcid"
                  name="orcid"
                  label="Enter your ORCID"
                  type="text"
                  placeholder="NNNN-NNNN-NNNN-NNNX"
                  v-model="registration_form.orcid"
                ></v-text-field>
                <!-- text field for orcid -->

                <!-- text field for first name -->
                <v-text-field
                  :rules="nameRules"
                  :prepend-icon="icons.mdiFormTextbox"
                  id="firstname"
                  name="firstname"
                  label="Enter your first name"
                  type="text"
                  placeholder="Firstname"
                  v-model="registration_form.first_name"
                ></v-text-field>
                <!-- text field for first name -->

                <!-- text field for family name -->
                <v-text-field
                  :rules="nameRules"
                  :prepend-icon="icons.mdiFormTextbox"
                  id="familyname"
                  name="familyname"
                  label="Enter your family name"
                  type="text"
                  placeholder="Familyname"
                  v-model="registration_form.family_name"
                ></v-text-field>
                <!-- text field for family name -->

                <!-- text field for registration comment -->
                <v-text-field
                  :rules="commentRules"
                  :prepend-icon="icons.mdiFormTextbox"
                  id="comment"
                  name="comment"
                  label="Describe your interest in HNF1B-db"
                  type="text"
                  v-model="registration_form.comment"
                ></v-text-field>
                <!-- text field for registration comment -->

                <!-- checkbox for terms-->
                <v-checkbox
                  :rules="termsRules"
                  v-model="registration_form.terms_agreed"
                  label="I accept the terms and use"
                ></v-checkbox>
                <!-- checkbox for terms-->

                <!-- form buttons -->
                <v-btn class="mr-4" @click="reset"> Reset Form </v-btn>

                <v-btn
                  :disabled="button_disabled"
                  color="primary"
                  type="submit"
                  :class="{ shake: animated }"
                  @click="clickHandler()"
                >
                  Submit
                </v-btn>
                <!-- form buttons -->
              </v-form>
            </v-card-text>
          </v-card>
        </v-flex>
      </v-layout>
    </v-container>
    <!-- container with registration form -->
  </v-container>
</template>


<script>
import { mdiAccount, mdiEmail, mdiAccountSchool, mdiFormTextbox } from '@mdi/js';

export default {
  name: "Register",
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
        content: "The Register view allows to appy for a new HNF1B-db account.",
      },
    ],
  },
  data() {
    return {
      icons: {
        mdiAccount,
        mdiEmail,
        mdiAccountSchool,
        mdiFormTextbox,
      },
      valid: false,
      button_disabled: true,
      userNameRules: [
        (v) => !!v || "Username is required",
        (v) => v.length >= 5 || "Min 5 characters",
        (v) => v.length <= 20 || "Max 20 characters",
        (v) => /[A-z]/.test(v) || "Only upper and lower characters",
      ],
      emailRules: [
        (v) => !!v || "E-mail is required",
        (v) => /.+@.+\..+/.test(v) || "E-mail must be valid",
      ],
      orcidRules: [
        (v) => !!v || "ORCID is required",
        (v) =>
          /^(([0-9]{4})-){3}[0-9]{3}[0-9X]$/.test(v) || "ORCID must be valid",
      ],
      nameRules: [
        (v) => !!v || "Name is required",
        (v) => v.length >= 2 || "Min 2 characters",
        (v) => v.length <= 50 || "Max 50 characters",
      ],
      commentRules: [
        (v) => !!v || "Comment is required",
        (v) => v.length >= 20 || "Min 20 characters",
        (v) => v.length <= 250 || "Max 250 characters",
      ],
      termsRules: [
        (v) => !!v || "Terms are required",
        (v) => v === true || "Terms need to be acknowledged",
      ],
      registration_form: {
        user_name: "",
        email: "",
        orcid: "",
        first_name: "",
        family_name: "",
        comment: "",
        terms_agreed: false,
      },
      animated: false,
      show_overlay: false,
      loading: true,
    };
  },
  watch: {
    valid() {
      this.button_disabled = !this.$refs.form.validate();
    },
  },
  mounted() {
    if (localStorage.user) {
      this.doUserLogOut();
    }
    this.loading = false;
  },
  methods: {
    reset() {
      this.$refs.form.reset();
    },
    async sendRegistration() {
      let apiUrl =
        process.env.VUE_APP_API_URL + "/api/auth/signup?signup_data=";

      try {
        let registration_form_copy = this.registration_form;
        registration_form_copy.terms_agreed =
          registration_form_copy.terms_agreed ? "accepted" : "not_accepted";

        let submission_json = JSON.stringify(registration_form_copy);
        let response = await this.axios.get(apiUrl + submission_json, {});

        console.log(
          "Your registration request has been send " +
            "(status " +
            response.status +
            " (" +
            response.statusText +
            ").",
          "Success",
          "success"
        );
        this.successfulRegistration();
      } catch (e) {
        console.log(e, "Error", "danger");
      }
    },
    successfulRegistration() {
      this.show_overlay = true;
      setTimeout(() => {
        this.$router.push("/");
      }, 2000);
    },
    onSubmit(event) {
      this.sendRegistration();
    },
    clickHandler() {
      const self = this;
      self.animated = true;
      setTimeout(() => {
        self.animated = false;
      }, 1000);
    },
    doUserLogOut() {
      if (localStorage.user || localStorage.token) {
        localStorage.removeItem("user");
        localStorage.removeItem("token");
        this.user = null;
        this.$router.push("/");
      }
    },
  },
};
</script>

<!-- Add "scoped" attribute to limit CSS to this component only -->
<!-- Shake based on https://codepen.io/aut0maat10/pen/ExaNZNo -->
<style scoped>
h3 {
  margin: 40px 0 0;
}
ul {
  list-style-type: none;
  padding: 0;
}
li {
  display: inline-block;
  margin: 0 10px;
}
a {
  color: #42b983;
}

.shake {
  animation: shake 0.82s cubic-bezier(0.36, 0.07, 0.19, 0.97) both;
  transform: translate3d(0, 0, 0);
}
@keyframes shake {
  10%,
  90% {
    transform: translate3d(-1px, 0, 0);
  }
  20%,
  80% {
    transform: translate3d(2px, 0, 0);
  }
  30%,
  50%,
  70% {
    transform: translate3d(-4px, 0, 0);
  }
  40%,
  60% {
    transform: translate3d(4px, 0, 0);
  }
}
</style>