<template>
  <v-container fluid>
    <!-- Load Publications table component element -->
    <TablePublications
      :sort-input="sort"
      :filter-input="filter"
      :fields-input="fields"
      :page-after-input="pageAfter"
      :page-size-input="pageSize"
    />
    <!-- Load Publications table component element -->
  </v-container>
</template>


<script>
import TablePublications from "@/components/tables/TablePublications.vue";

export default {
  name: "Publications",
  components: { TablePublications },
  props: {
    sort: { type: String, default: "+publication_id" },
    filter: { type: String, default: "filter=" },
    fields: { type: String, default: null },
    pageAfter: { type: Number, default: 0 },
    pageSize: { type: Number, default: 10 }
  },
};
</script>