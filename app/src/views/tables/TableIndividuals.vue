<template>
  <v-container fluid>
    <!-- Load Individuals table component element -->
    <TableIndividuals
      :sort-input="sort"
      :filter-input="filter"
      :fields-input="fields"
      :page-after-input="pageAfter"
      :page-size-input="pageSize"
    />
    <!-- Load Individuals table component element -->
  </v-container>
</template>


<script>
import TableIndividuals from "@/components/tables/TableIndividuals.vue";

export default {
  name: "Individuals",
  components: { TableIndividuals },
  props: {
    sort: { type: String, default: "+individual_id" },
    filter: { type: String, default: "filter=" },
    fields: { type: String, default: null },
    pageAfter: { type: Number, default: 0 },
    pageSize: { type: Number, default: 10 },
  },
};
</script>