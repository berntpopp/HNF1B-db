<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12" sm="12">
        <v-sheet outlined>
          <v-overlay
            :absolute="absolute"
            :opacity="opacity"
            :value="loading"
            :color="color"
          >
            <v-progress-circular
              indeterminate
              color="primary"
            ></v-progress-circular>
          </v-overlay>

          <div class="text-lg-h6">
            {{ headerLabel }}
          </div>

          <p class="text-justify">
            {{ headerSubLabel }}
          </p>

          <div class="pa-2">
            <v-data-table
              dense
              :items="search"
              :headers="headers"
              hide-default-footer
              class="elevation-1"
              item-key="name"
            >
              <template v-slot:[`item.result`]="{ item }">
                <v-chip
                  :color="type_color[item.type]"
                  class="ma-2"
                  small
                  link
                  :to="item.link"
                >
                  {{ item.type.substring(0, 3) }}{{ item.result }}
                  <v-icon right> {{ type_symbol[item.type] }} </v-icon>
                </v-chip>
              </template>

              <template v-slot:[`item.searchdist`]="{ item }">
                <v-chip
                  :color="getVariant(item.searchdist)"
                  class="ma-2"
                  small
                  link
                  :to="item.link"
                >
                  {{ item.searchdist }}
                </v-chip>
              </template>

            </v-data-table>
          </div>
        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>


<script>
import urlParsingMixin from "@/assets/js/mixins/urlParsingMixin.js";
import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";

export default {
  name: "TableVariants",
  mixins: [urlParsingMixin, colorAndSymbolsMixin],
  props: {
    headerLabel: { type: String, default: "Search Results Table" },
    headerSubLabel: {
      type: String,
      default: "Explore the results of your search.",
    },
    termInput: { type: String, default: null },
  },
  data() {
    return {
      search: [],
      headers: [
        { text: "Result", value: "result" },
        { text: "Search", value: "search" },
        { text: "Match", value: "match" },
        { text: "Searchdist", value: "searchdist" },
      ],
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      loading: true,
    };
  },
  computed: {
  },
  watch: {
  },
  created() {
  },
  mounted() {
    this.loadSearchInfo();
  },
  methods: {
    async loadSearchInfo() {
      this.loading = true;
      const apiSearchURL = `${process.env.VUE_APP_API_URL
      }/api/search/${
        this.termInput
      }?helper=false`;
      try {
        const response_search = await this.axios.get(apiSearchURL);

        this.search = response_search.data;
      } catch (e) {
        console.error(e);
      }

      if (this.search.length === 1) {
        this.$router.push(this.search[0].link);
      } else {
        this.loading = false;
      }
    },
    getVariant(searchdist) {
      if (searchdist <= 0.1) {
        return 'success';
      } if (searchdist < 0.2) {
        return 'warning';
      }
      return 'danger';
    },
  },
};
</script>