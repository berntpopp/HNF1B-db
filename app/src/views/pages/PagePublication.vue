<template>
  <v-container fluid>
    <v-row>
      <v-col cols="12" sm="12">
        <v-sheet min-height="80vh" outlined>
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
            <h3>
              Publication:
              <v-chip color="cyan accent-2" class="ma-2">
                pub{{ $route.params.publication_id }}
                <v-icon right> mdi-book-open-blank-variant </v-icon>
              </v-chip>
            </h3>
          </div>

          <v-card class="mx-auto my-2" max-width="800">
            <v-list-item>
              <v-list-item-content>
                <v-list-item>
                  PMID:
                  <a
                    :href="
                      'https://pubmed.ncbi.nlm.nih.gov/' + publication[0].PMID
                    "
                    target="_blank"
                  >
                    {{ publication[0].PMID }}
                  </a>
                </v-list-item>

                <v-list-item>
                  DOI:
                  <a
                    :href="'https://doi.org/' + publication[0].DOI"
                    target="_blank"
                  >
                    {{ publication[0].DOI }}
                  </a>
                </v-list-item>

                <v-divider inset> </v-divider>

                <v-list-item>
                  Review date:
                  {{ publication[0].publication_entry_date }}
                </v-list-item>

                <v-list-item>
                  <b>Title:</b> {{ publication[0].title }}
                </v-list-item>

                <v-list-item>
                  <b>Abstract:</b> {{ publication[0].abstract }}
                </v-list-item>
              </v-list-item-content>
            </v-list-item>
          </v-card>

          <!-- Load Individuals table component element -->
          <template v-if="!loading">
          <TableIndividuals
            :show-filter-controls="false"
            :show-pagination-controls="false"
            :filter-input="individuals_in_publication_filter"
            header-label="Individuals"
            header-sub-label="described in this publication"
          />
          </template>
          <!-- Load Individuals table component element -->

        </v-sheet>
      </v-col>
    </v-row>
  </v-container>
</template>


<script>
import TableIndividuals from "@/components/tables/TableIndividuals.vue";

import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";

export default {
  name: "PagePublication",
  mixins: [colorAndSymbolsMixin],
  components: {
    TableIndividuals
  },
  data() {
    return {
      publication: [
        {
          publication_id: null,
          publication_alias: null,
          publication_type: null,
          publication_user_id: null,
          publication_entry_date: null,
          PMID: null,
          DOI: null,
          PDF: null,
          title: null,
          abstract: null,
          publication_date: null,
          journal_abbreviation: null,
          journal: null,
          keywords: null,
          firstauthor_lastname: null,
          firstauthor_firstname: null,
          update_date: null,
        },
      ],
      absolute: true,
      opacity: 1,
      color: "#FFFFFF",
      loading: true,
      individuals_in_publication: [],
      individuals_in_publication_filter: "",
    };
  },
  computed: {},
  created() {
    this.loadPublicationData();
  },
  mounted() {},
  methods: {
    async loadPublicationData() {
      this.loading = true;

      let apiUrl =
        process.env.VUE_APP_API_URL +
        "/api/publications?filter=equals(publication_id," +
        this.$route.params.publication_id +
        ")";

      try {
        let response = await this.axios.get(apiUrl);
        this.publication = response.data.data;

        this.individuals_in_publication = [...new Set(response.data.data[0].reports.map(item => item.individual_id))];
        this.individuals_in_publication_filter = "contains(individual_id," + this.individuals_in_publication.join("|") + ")";

      } catch (e) {
        console.error(e);
      }
      this.loading = false;
    },
  },
};
</script>