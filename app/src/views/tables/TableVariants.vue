<template>
  <v-container fluid>
    <!-- Load Variants table component element -->
    <TableVariants
      :sort-input="sort"
      :filter-input="filter"
      :fields-input="fields"
      :page-after-input="pageAfter"
      :page-size-input="pageSize"
    />
    <!-- Load Variants table component element -->
  </v-container>
</template>


<script>
import TableVariants from "@/components/tables/TableVariants.vue";

export default {
  name: "Variants",
  components: { TableVariants },
  props: {
    sort: { type: String, default: "+publication_id" },
    filter: { type: String, default: "filter=" },
    fields: { type: String, default: null },
    pageAfter: { type: Number, default: 0 },
    pageSize: { type: Number, default: 10 },
  },
};
</script>