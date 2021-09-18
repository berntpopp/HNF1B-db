<template>
  <v-app id="HNF1B-db">
    <v-app-bar
      app
      color="white"
      flat
      dense
    >

      <v-tabs
        class="ml-n9"
        color="grey darken-1"
      >

        <v-tab
        >
          <img
            src="../public/HNF1B-db_logo.png"
            height="40px"
          />
        </v-tab>

        <v-tab
          v-for="link in links"
          :key="link"
        >
          {{ link }}
        </v-tab>
      </v-tabs>

    </v-app-bar>

    <v-main class="grey lighten-3">
      <v-container>
        <v-row>
          <v-col
            cols="12"
            sm="2"
          >
            <v-sheet
              rounded="lg"
              min-height="70vh"
            >
              <!--  -->
            </v-sheet>
          </v-col>

          <v-col
            cols="12"
            sm="10"
          >
            <v-sheet
              min-height="70vh"
              rounded="lg"
            >
              <!--  -->
            </v-sheet>
          </v-col>

        </v-row>
      </v-container>
    </v-main>
  </v-app>
</template>


<script>
  export default {
    data: () => ({
      links: [
        'Tables',
        'Analyses',
        'Search',
        'About',
      ],
    }),
  }
</script>

<style>
.v-app-bar-title__content{
  width: 200px !important;
}
</style>