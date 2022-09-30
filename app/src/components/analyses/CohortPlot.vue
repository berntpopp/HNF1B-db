<template>
  <v-container fluid>
    <!-- Controls-->
    <v-select
      :items="items"
      v-model="cohort_characteristics"
      label="Characteristic"
      dense
      outlined
    ></v-select>
    <!-- Controls-->

    <!-- Content cohort plot-->
    <div id="cohort_dataviz" class="svg-container"></div>
    <!-- Content cohort plot-->
  </v-container>
</template>


<script>
import * as d3 from "d3";
import getTransformation from "@/assets/js/utilsGetTransformation.js";
import arrangeLabels from "@/assets/js/utilsArrangeLabels.js";
import wrap from "@/assets/js/utilsWrap.js";

export default {
  name: "CohortPlot",
  data() {
    return {
      itemsCohort: [],
      itemsCohorteMeta: [],
      cohort_characteristics: "cohort",
      items: ["cohort", "sex", "reported"],
    };
  },
  computed: {},
  mounted() {
    this.loadCohortData();
  },
  watch: {
    cohort_characteristics(value) {
      this.generateDonutGraph();
    },
  },
  methods: {
    async loadCohortData() {
      let apiUrl =
        process.env.VUE_APP_API_URL + "/api/statistics/cohort_characteristics";

      try {
        let response = await this.axios.get(apiUrl);

        this.itemsCohort = response.data.data;
        this.itemsCohorteMeta = response.data.meta;

        this.generateDonutGraph();
      } catch (e) {
        console.error(e);
      }
    },
    generateDonutGraph() {
      // set the type of data plotted used for assigning IDs
      const dataType = 'cohort'

      // set the dimensions and margins of the graph
      const width = 600,
        height = 500,
        margin = 50;

      // The radius of the pieplot is half the width or half the height (smallest one). I subtract a bit of margin.
      const radius = Math.min(width, height) / 2 - margin;

      // first remove svg
      d3.select("#cohort_dataviz").select("svg").remove();

      d3.select("#cohort_dataviz").select("div").remove();

      // append the svg object to the div called 'cohort_dataviz'
      const svg = d3
        .select("#cohort_dataviz")
        .append("svg")
        .attr("viewBox", `0 0 600 500`)
        .attr("preserveAspectRatio", "xMinYMin meet")
        .classed("svg-content", true)
        .append("g")
        .attr("transform", `translate(${width / 2},${height / 2})`);

      // load data
      const data = this.itemsCohort[this.cohort_characteristics][0];
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
        .select("#cohort_dataviz")
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

      // define function to compute mid angle
      function midAngle(d) {
          return d.startAngle + (d.endAngle - d.startAngle) / 2;
      }

      // add the labels
      svg
        .selectAll("allLabels")
        .data(data_ready)
        .join("text")
        .attr('class', 'label')
        .attr('id', function(d, j) {
            return dataType + '-' + j;
        })
        .text((d) => d.data[0])
        .attr("transform", function (d) {
          const pos = outerArc.centroid(d);
          const midangle = d.startAngle + (d.endAngle - d.startAngle) / 2;
          pos[0] = radius * 0.99 * (midangle < Math.PI ? 1 : -1);
          return `translate(${pos})`;
        })
        .style("text-anchor", function(d) {
            return midAngle(d) < Math.PI ? "start" : "end";
        })
        .attr("dy", ".35em")
        .attr("dx", ".35em")
        .attr("fill", "#111")
        .call(wrap, 100);

      // arrange labels
      arrangeLabels(svg, ".label");

      // define arc label radius
      let labelArc = d3.arc()
        .outerRadius(radius * 0.4)
        .innerRadius(radius);

      // add the polylines between chart and labels:
      svg
        .selectAll("allPolylines")
        .data(data_ready)
        .join("polyline")
        .attr("stroke", "black")
        .style("fill", "none")
        .attr("stroke-width", 1)
        .attr("points", function(d, j) {
            const offset = midAngle(d) < Math.PI ? 0 : 10;
            const label = d3.select('#' + dataType + '-' + j);
            const transform = getTransformation(label.attr("transform"));
            const pos = labelArc.centroid(d);
            pos[0] = transform.translateX + offset;
            pos[1] = transform.translateY;
            const mid = labelArc.centroid(d);
            mid[1] = transform.translateY;
            return [arc.centroid(d), mid, pos];
        });

      // add total count as central label
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
  max-width: 600px;
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