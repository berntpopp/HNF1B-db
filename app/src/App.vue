<template>
  <v-app id="HNF1B-db">

<v-app-bar
  flat
  app
>
  <v-toolbar-title>
    <v-tab
    to="/"
    >
      <img
        src="../public/HNF1B-db_logo.png"

      />
    </v-tab>
  </v-toolbar-title>

  <v-toolbar-items class="hidden-sm-and-down">

    <v-menu offset-y>
      <template v-slot:activator="{ on }">
        <v-btn
          text
          v-on="on"
        >
        Tables
        </v-btn>
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

    <v-btn text
      v-for="item in items"
      :key="item.title"
      :to="item.to"
    >
      {{ item.title }}
    </v-btn>

  </v-toolbar-items>
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
        {title: 'Analyses', to: '/analyses'},
        {title: 'Search', to: '/search'},
        {title: 'Scoring', to: '/scoring'},
        {title: 'About', to: '/about'},
      ],
      tables: [
        { title: 'Reports', to: '/table_reports', id: 'tabe 1' },
        { title: 'Individuals', to: '/table_individuals', id: 'tabe 2' },
        { title: 'Publications', to: '/table_publications', id: 'tabe 3' },
        { title: 'Variants', to: '/table_variants', id: 'tabe 4' },
      ],
      footer_items: [
        {icon: 'mdi-github', to: 'https://github.com/berntpopp/HNF1B-db', target: '_blank'},
        {icon: 'mdi-api', to: '/api', target: '_self'},
        {icon: 'mdi-copyright', to: 'https://creativecommons.org/licenses/by/4.0/', target: '_blank'}
      ],
    }),
  }
</script>
