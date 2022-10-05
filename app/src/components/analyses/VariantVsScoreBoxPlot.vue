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
    <div id="boxplot_dataviz" class="svg-container"></div>
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
  name: "VariantVsScoreBoxPlot",
  mixins: [colorAndSymbolsMixin],
  data() {
    return {
      itemsVPS: [],
      itemsVPSMeta: [],
    };
  },
  mounted() {
    this.loadData();
  },
  methods: {
    async loadData() {
      let apiUrl =
        process.env.VUE_APP_API_URL + "/api/statistics/variantattributes_vs_phenotypescore";

      try {
        let response = await this.axios.get(apiUrl);

        this.itemsVPS = response.data.data;
        this.itemsVPSMeta = response.data.meta;

        this.generateVPSGraph();
      } catch (e) {
        console.error(e);
      }
    },
    generateVPSGraph() {
      // based on https://d3-graph-gallery.com/graph/boxplot_horizontal.html
      // TODO: clean up code below
      // TODO: adapt y-axis hight based on selected score

      // set the dimensions and margins of the graph
      const margin = {top: 10, right: 30, bottom: 50, left: 30},
        width = 400 - margin.left - margin.right,
        height = 400 - margin.top - margin.bottom;

      // first remove svg
      d3.select("#boxplot_dataviz").select("svg").remove();

      d3.select("#boxplot_dataviz").select("div").remove();

      // append the svg object to the body of the page
      const svg_raw = d3
        .select("#boxplot_dataviz")
        .append("svg")
        .attr("viewBox", `0 0 400 400`)
        .attr("preserveAspectRatio", "xMinYMin meet")
        .classed("svg-content", true);

      const svg = svg_raw
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      // Parse the Data
      const data = this.itemsVPS;
      const data_keys = this.itemsVPS.map((item) => item.key);
      const data_individuals = this.itemsVPS
        .map((item) => {
          return [
            item.value[0].individuals.map((value) => {
              return {
                group: item.key,
                individual_id: value.individual_id,
                score: value.score,
              };
            }),
          ]
        })
        .flat(2);

      // Show the X scale
      const x = d3.scaleBand()
        .range([ height, 0 ])
        .domain(data_keys)
        .padding(.4);

      svg.append("g")
        .attr("transform", "translate(0," + height + ")")
        .call(d3.axisBottom(x).ticks(5))
        .select(".domain")
        .remove();

      const y = d3.scaleLinear()
        .domain([5,0])
        .range([0, width]);

      svg.append("g")
        .call(d3.axisLeft(y)
        .tickSize(0))
        .select(".domain")
        .remove();

    // Show the main vertical line
    svg
      .selectAll("vertLines")
      .data(data)
      .enter()
      .append("line")
        .attr("y1", function(d){return(y(d.value[0].lower))})
        .attr("y2", function(d){return(y(d.value[0].upper))})
        .attr("x1", function(d){return(x(d.key) + x.bandwidth()/2)})
        .attr("x2", function(d){return(x(d.key) + x.bandwidth()/2)})
        .attr("stroke", "black")
        .style("width", 40)

    // rectangle for the main box
    svg
      .selectAll("boxes")
      .data(data)
      .enter()
      .append("rect")
        .attr("y", function(d){return(y(d.value[0].q3))})
        .attr("height", function(d){ ; return(y(d.value[0].q1) - y(d.value[0].q3))})
        .attr("x", function(d) { return x(d.key); })
        .attr("width", x.bandwidth())
        .attr("stroke", "black")
        .style("fill", "#69b3a2")
        .style("opacity", 0.7)

    // Show the median
    svg
      .selectAll("medianLines")
      .data(data)
      .enter()
      .append("line")
        .attr("x1", function(d){return(x(d.key))})
        .attr("x2", function(d){return(x(d.key) + x.bandwidth())})
        .attr("y1", function(d){return(y(d.value[0].median))})
        .attr("y2", function(d){return(y(d.value[0].median))})
        .attr("stroke", "black")
        .style("width", 80)

      // Color scale
      const myColor = d3.scaleSequential()
        .interpolator(d3.interpolateInferno)
        .domain([5,0])

      // ----------------
      // Create a tooltip
      // ----------------
      const tooltip = d3
        .select("#boxplot_dataviz")
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
          .html("Individual: " + d.individual_id + ", Score: " + d.score)
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

      // Add individual points with jitter
      const jitterWidth = 30;

      svg
        .selectAll("indPoints")
        .data(data_individuals)
        .enter()
        .append('a')
        .attr('xlink:href', (d) => `/individual/${d.individual_id}`) // <- add links to the filtered phenotype table to the bars
        .attr('aria-label', (d) => `Link to respective individual page`)
        .append("circle")
          .attr("cy", function(d){ return(y(d.score))})
          .attr("cx", function(d){ return(x(d.group) + (x.bandwidth()/2) - jitterWidth/2 + Math.random() * jitterWidth )})
          .attr("r", 2.5)
          .style("fill", function(d){ return(myColor(+d.score)) })
          .attr("stroke", "grey")
        .on("mouseover", mouseover)
        .on("mousemove", mousemove)
        .on("mouseleave", mouseleave)

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