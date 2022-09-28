<template>
  <v-container fluid>
    <!-- Load Variants table component element -->
    <TableSearch
      :term-input="term"
    />
    <!-- Load Variants table component element -->
  </v-container>
</template>


<script>
import TableSearch from "@/components/tables/TableSearch.vue";

export default {
  name: "Variants",
  components: { TableSearch },
  props: {
    term: { type: String, default: "" },
  },
};
</script>