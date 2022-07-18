<template>
  <v-container fluid fill-height>
    <v-layout align-center justify-center>
      <v-flex xs12 sm8 md4>
        <v-card class="elevation-12">
          <v-toolbar dark color="primary">
            <v-toolbar-title>Sign in</v-toolbar-title>
          </v-toolbar>
          <v-card-text>
            <v-form
              ref="form"
              v-model="valid"
              lazy-validation
              @submit.stop.prevent="onSubmit()"
            >
              <v-text-field
                prepend-icon="mdi-account"
                name="login"
                label="Login"
                type="text"
                v-model="user_name"
              ></v-text-field>
              <v-text-field
                id="password"
                prepend-icon="mdi-lock"
                name="password"
                label="Password"
                type="password"
                v-model="password"
              ></v-text-field>

              Don't have an account yet and want to help?
              <a 
                href="/Register"
              >
                Register now.
              </a>
              <br>

              Forgot your password?
              <a 
                href="/PasswordReset"
              >
                Reset now.
              </a>
              <br>
              <br>

              <v-btn class="mr-4" @click="reset"> Reset Form </v-btn>

              <v-btn
                color="primary"
                type="submit"
                :class="{ shake: animated }"
                @click="clickHandler()"
              >
                Login
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
  name: "Login",
  metaInfo: {
    // if no subcomponents specify a metaInfo.title, this title will be used
    title: "Login",
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
          "The Login view allows users and curators to log into their HNF1B-db account.",
      },
    ],
  },
  data() {
    return {
      valid: true,
      user_name: "",
      password: "",
      ywt: "",
      user: [],
      loading: true,
      animated: false,
    };
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
    async loadJWT() {
      let apiAuthenticateURL =
        process.env.VUE_APP_API_URL +
        "/api/auth/authenticate?user_name=" +
        this.user_name +
        "&password=" +
        this.password;

      try {
        let response_authenticate = await this.axios.get(apiAuthenticateURL);
        localStorage.setItem("token", response_authenticate.data[0]);
        console.log(
          "You have logged in  " +
            "(status " +
            response_authenticate.status +
            " (" +
            response_authenticate.statusText +
            ").",
          "Success",
          "success"
        );
        this.signinWithJWT();
      } catch (e) {
        console.log(e);
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
        this.user = response_signin.data;
        localStorage.setItem("user", JSON.stringify(response_signin.data));
        this.$router.push("/");
      } catch (e) {
        console.log(e);
      }
    },
    resetForm() {
      this.user_name = "";
      this.password = "";

      this.$nextTick(() => {
        this.$refs.observer.reset();
      });
    },
    onSubmit(event) {
      this.loadJWT();
    },
    doUserLogOut() {
      if (localStorage.user || localStorage.token) {
        localStorage.removeItem("user");
        localStorage.removeItem("token");
        this.user = null;
        this.$router.push("/");
      }
    },
    clickHandler() {
      const self = this;
      self.animated = true;
      setTimeout(() => {
        self.animated = false;
      }, 1000);
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
  color: #0502a0;
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
