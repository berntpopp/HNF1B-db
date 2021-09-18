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
        to="/"
        >
          <img
            src="../public/HNF1B-db_logo.png"
            height="40px"
          />
        </v-tab>

        <v-tab
          v-for="item in items"
          :key="item.title"
          :to="item.to"
        >
          {{ item.title }}
        </v-tab>
      </v-tabs>

    </v-app-bar>

    <v-main class="grey lighten-3">
      <router-view></router-view>
    </v-main>
  </v-app>
</template>


<script>
  export default {
    data: () => ({
      items: [
        {title: 'Tables', to: '/tables'},
        {title: 'Analyses', to: '/analyses'},
        {title: 'Search', to: '/search'},
        {title: 'About', to: '/about'},
      ],
    }),
  }
</script>
