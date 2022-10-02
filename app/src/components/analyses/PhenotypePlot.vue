<template>
  <v-container fluid>
    <!-- Controls-->
    <v-container>
      <v-row no-gutters>
        <v-col cols="6" sm="6">
        </v-col>
        <v-col cols="6" md="6" class="d-flex flex-row-reverse">
          <v-btn
            id='saveButtonPhenotype'
            small
            class="px-2"
          >
            <v-icon> {{ icons.mdiDownload }} </v-icon> PNG
          </v-btn>
        </v-col>
      </v-row>
    </v-container>
    <!-- Controls-->

    <!-- Content publications plot-->
    <div id="phenotype_dataviz" class="svg-container"></div>
    <!-- Content publications plot-->
  </v-container>
</template>


<script>
import colorAndSymbolsMixin from "@/assets/js/mixins/colorAndSymbolsMixin.js";
import * as d3 from 'd3';
import saveAs from 'file-saver';
import svgString2Image from "@/assets/js/utilsSvgString2Image.js";
import getSVGString from "@/assets/js/utilsGetSVGString.js";

export default {
  name: "PhenotypePlot",
  mixins: [colorAndSymbolsMixin],
  data() {
    return {
      itemsPhenotype: [],
      itemsPhenotypeMeta: [],
    };
  },
  mounted() {
    this.loadPhenotypeData();
  },
  methods: {
    async loadPhenotypeData() {
      let apiUrl =
        process.env.VUE_APP_API_URL + "/api/statistics/phenotypes_in_cohort";

      try {
        let response = await this.axios.get(apiUrl);

        this.itemsPhenotype = response.data.data;
        this.itemsPhenotypeMeta = response.data.meta;

        this.generatePhenotypeGraph();
      } catch (e) {
        console.error(e);
      }
    },
    generatePhenotypeGraph() {
      // set the dimensions and margins of the graph
      const margin = { top: 10, right: 30, bottom: 150, left: 100 },
        width = 750 - margin.left - margin.right,
        height = 300 - margin.top - margin.bottom;

      // first remove svg
      d3.select("#phenotype_dataviz").select("svg").remove();

      // append the svg object to the body of the page
      const svg_raw = d3
        .select("#phenotype_dataviz")
        .append("svg")
        .attr("viewBox", `0 0 750 300`)
        .attr("preserveAspectRatio", "xMinYMin meet")
        .classed("svg-content", true);

      const svg = svg_raw
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      // Parse the Data
      const data = this.itemsPhenotype;

      // List of subgroups = header of the csv files
      const subgroups = ["yes", "no", "not reported"];

      // List of groups = species here = value of the first column called group -> I show them on the X axis
      const groups = data.map((d) => d.group);

      // Add X axis
      const x = d3.scaleBand().domain(groups).range([0, width]).padding([0.2]);
      svg
        .append("g")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x))
        .selectAll("text")
        .attr("transform", "translate(-10,0)rotate(-45)")
        .style("text-anchor", "end");

      // Add Y axis
      const y = d3.scaleLinear().domain([0, 1000]).range([height, 0]);
      svg.append("g").call(d3.axisLeft(y));

      // color palette = one color per subgroup
      const color = d3
        .scaleOrdinal()
        .domain(subgroups)
        .range(["#C7EFCF", "#FE5F55", "#EEF5DB"]);

      //stack the data? --> stack per subgroup
      const stackedData = d3.stack().keys(subgroups)(data);

      // ----------------
      // Create a tooltip
      // ----------------
      const tooltip = d3
        .select("#phenotype_dataviz")
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
        const subgroupName = d3.select(this.parentNode).datum().key;
        const subgroupValue = d.data[subgroupName];

        tooltip
          .html(
            "subgroup: " + subgroupName + "<br>" + "Value: " + subgroupValue
          )
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

        d3.select(this).style("stroke", "grey");
      };

      // Show the bars
      svg
        .append("g")
        .selectAll("g")
        // Enter in the stack data = loop key per key = group per group
        .data(stackedData)
        .join("g")
        .attr("fill", (d) => color(d.key))
        .selectAll("rect")
        // enter a second time = loop subgroup per subgroup to add all rectangles
        .data((d) => d)
        .join("rect")
        .attr("x", (d) => x(d.data.group))
        .attr("y", (d) => y(d[1]))
        .attr("height", (d) => y(d[0]) - y(d[1]))
        .attr("width", x.bandwidth())
        .attr("stroke", "grey")
        .on("mouseover", mouseover)
        .on("mousemove", mousemove)
        .on("mouseleave", mouseleave);

        // Set-up the export button
        d3.select('#saveButtonPhenotype').on('click', function(){
          var svgString = getSVGString(svg_raw.node());

          function save( dataBlob, filesize ){
            saveAs( dataBlob, 'plot.png' ); // FileSaver.js function
          };

          svgString2Image( svgString, 3*width, 3*height, 'png', save ); // passes Blob and filesize String to the callback

        });
    },
  },
};
</script>


<style scoped>
.svg-container {
  max-width: 1200px;
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