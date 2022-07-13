<template>
  <v-container fluid>
    <!-- Load Reports table component element -->
    <TableReports
      :sort-input="sort"
      :filter-input="filter"
      :fields-input="fields"
      :page-after-input="pageAfter"
      :page-size-input="pageSize"
    />
    <!-- Load Reports table component element -->
  </v-container>
</template>


<script>
import TableReports from "@/components/tables/TableReports.vue";

export default {
  name: "Reports",
  components: { TableReports },
  props: {
    sort: { type: String, default: "+report_id" },
    filter: { type: String, default: "filter=" },
    fields: { type: String, default: null },
    pageAfter: { type: Number, default: 0 },
    pageSize: { type: Number, default: 10 }
  },
};
</script>