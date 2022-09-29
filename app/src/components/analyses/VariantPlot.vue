<template>
  <v-container fluid>
    <!-- Controls-->
    <v-select
      :items="items"
      v-model="variant_characteristics"
      label="Characteristic"
      dense
      outlined
    ></v-select>
    <!-- Controls-->

    <!-- Content variant plot-->
    <div id="variant_dataviz" class="svg-container"></div>
    <!-- Content variant plot-->
  </v-container>
</template>


<script>
import * as d3 from "d3";

export default {
  name: "VariantPlot",
  data() {
    return {
      itemsVariant: [],
      itemsVarianteMeta: [],
      variant_characteristics: "classification",
      items: [
        "detection_method",
        "segregation",
        "class",
        "impact",
        "effect",
        "classification",
      ],
    };
  },
  computed: {},
  mounted() {
    this.loadVariantData();
  },
  watch: {
    variant_characteristics(value) {
      this.generateDonutGraph();
    },
  },
  methods: {
    async loadVariantData() {
      let apiUrl =
        process.env.VUE_APP_API_URL + "/api/statistics/variant_characteristics";

      try {
        let response = await this.axios.get(apiUrl);

        this.itemsVariant = response.data.data;
        this.itemsVarianteMeta = response.data.meta;

        this.generateDonutGraph();
      } catch (e) {
        console.error(e);
      }
    },
    generateDonutGraph() {
      // set the dimensions and margins of the graph
      const width = 800,
        height = 500,
        margin = 50;

      // The radius of the pieplot is half the width or half the height (smallest one). I subtract a bit of margin.
      const radius = Math.min(width, height) / 2 - margin;

      // first remove svg
      d3.select("#variant_dataviz").select("svg").remove();

      d3.select("#variant_dataviz").select("div").remove();

      // append the svg object to the div called 'variant_dataviz'
      const svg = d3
        .select("#variant_dataviz")
        .append("svg")
        .attr("viewBox", `0 0 800 500`)
        .attr("preserveAspectRatio", "xMinYMin meet")
        .classed("svg-content", true)
        .append("g")
        .attr("transform", `translate(${width / 2},${height / 2})`);

      // load data
      const data = this.itemsVariant[this.variant_characteristics][0];
      const data_keys = Object.keys(data);

      // calculate total count in object
      const sumValues = Object.values(data).reduce((a, b) => a + b);

      // Compute the position of each group on the pie:
      const pie = d3
        .pie()
        .sort(null) // Do not sort group by size
        .value((d) => d[1]);

      const data_ready = pie(Object.entries(data));

      // set the color scale
      const color = d3.scaleOrdinal().domain(data_keys).range(d3.schemeDark2);

      // ----------------
      // Create a tooltip
      // ----------------
      const tooltip = d3
        .select("#variant_dataviz")
        .append("div")
        .style("opacity", 0)
        .attr("class", "tooltip")
        .style("background-color", "white")
        .style("border", "solid")
        .style("border-width", "1px")
        .style("border-radius", "5px")
        .style("padding", "10px");

      // Three function that change the tooltip when user hover / move / leave a cell
      const mouseover = function (event, d) {
        tooltip
          .html("Group: " + d.data[0] + ", Count: " + d.data[1])
          .style("opacity", 1);

        d3.select(this).style("stroke", "black");
      };

      const mousemove = function (event, d) {
        tooltip
          .style("transform", "translateY(-55%)")
          .style("left", event.clientX + 20 + "px")
          .style("top", event.clientY + 10 + "px");
      };

      const mouseleave = function (event, d) {
        tooltip
          .style("opacity", 0)
          .style("left", "-100px")
          .style("top", "-100px");

        d3.select(this).style("stroke", "white");
      };

      // The arc generator
      const arc = d3
        .arc()
        .innerRadius(radius * 0.5) // This is the size of the donut hole
        .outerRadius(radius * 0.8);

      // Another arc that won't be drawn. Just for labels positioning
      const outerArc = d3
        .arc()
        .innerRadius(radius * 0.9)
        .outerRadius(radius * 0.9);

      // Build the pie chart: Basically, each part of the pie is a path that we build using the arc function.
      svg
        .selectAll("allSlices")
        .data(data_ready)
        .join("path")
        .attr("d", arc)
        .attr("fill", (d) => color(d.data[1]))
        .attr("stroke", "white")
        .style("stroke-width", "2px")
        .style("opacity", 0.7)
        .on("mouseover", mouseover)
        .on("mousemove", mousemove)
        .on("mouseleave", mouseleave);

      // Add the polylines between chart and labels:
      svg
        .selectAll("allPolylines")
        .data(data_ready)
        .join("polyline")
        .attr("stroke", "black")
        .style("fill", "none")
        .attr("stroke-width", 1)
        .attr("points", function (d) {
          const posA = arc.centroid(d); // line insertion in the slice
          const posB = outerArc.centroid(d); // line break: we use the other arc generator that has been built only for that
          const posC = outerArc.centroid(d); // Label position = almost the same as posB
          const midangle = d.startAngle + (d.endAngle - d.startAngle) / 2; // we need the angle to see if the X position will be at the extreme right or extreme left
          posC[0] = radius * 0.95 * (midangle < Math.PI ? 1 : -1); // multiply by 1 or -1 to put it on the right or on the left
          return [posA, posB, posC];
        });

      // Add the polylines between chart and labels:
      svg
        .selectAll("allLabels")
        .data(data_ready)
        .join("text")
        .text((d) => d.data[0])
        .attr("transform", function (d) {
          const pos = outerArc.centroid(d);
          const midangle = d.startAngle + (d.endAngle - d.startAngle) / 2;
          pos[0] = radius * 0.99 * (midangle < Math.PI ? 1 : -1);
          return `translate(${pos})`;
        })
        .style("text-anchor", function (d) {
          const midangle = d.startAngle + (d.endAngle - d.startAngle) / 2;
          return midangle < Math.PI ? "start" : "end";
        });

      // Add total count as central label
      svg.append("svg:text")
          .attr("dy", ".35em")
          .attr("text-anchor", "middle")
          .attr("style","font-family:Ubuntu")
          .attr("font-size","40")
          .attr("fill","#5CB85C")
          .text(sumValues);
    },
  },
};
</script>


<style scoped>
.svg-container {
  max-width: 800px;
  width: 100%;
  margin: 0px auto;
  vertical-align: top;
  overflow: hidden;
}
.svg-content {
  display: inline-block;
  position: absolute;
  top: 0;
  left: 0;
}
</style>


<style>
.tooltip {
  display: inline;
  position: fixed;
}
</style>