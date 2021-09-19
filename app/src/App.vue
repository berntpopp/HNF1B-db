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

    <v-footer padless>
      <v-card-text class="text-center">
        <v-btn
          v-for="footer_item in footer_items"
          :key="footer_item.icon"
          class="mx-4"
          icon
        >
        <v-btn 
        icon 
        :href="footer_item.to" 
        :target="footer_item.target"
        >
          <v-icon size="24px">
            {{ footer_item.icon }}
          </v-icon>
        </v-btn>
        </v-btn>
      </v-card-text>
    </v-footer>
    
  </v-app>
</template>


<script>
  export default {
    data: () => ({
      items: [
        {title: 'Tables', to: '/tables'},
        {title: 'Analyses', to: '/analyses'},
        {title: 'Search', to: '/search'},
        {title: 'Scoring', to: '/scoring'},
        {title: 'About', to: '/about'},
      ],
      footer_items: [
        {icon: 'mdi-github', to: 'https://github.com/berntpopp/HNF1B-db', target: '_blank'},
        {icon: 'mdi-api', to: '/api', target: '_self'},
        {icon: 'mdi-copyright', to: 'https://creativecommons.org/licenses/by/4.0/', target: '_blank'}
      ],
    }),
  }
</script>
