<template>
  <!-- Content publications plot-->
  <div id="publications_dataviz" class="svg-container"></div>
  <!-- Content publications plot-->
</template>


<script>
import * as d3 from "d3";

export default {
  name: "PublicationsPlot",
  data() {
    return {
      itemsPublication: [],
      itemsPublicationMeta: [],
    };
  },
  mounted() {
    this.loadPublicationData();
  },
  methods: {
    async loadPublicationData() {
      let apiUrl =
        process.env.VUE_APP_API_URL + "/api/statistics/publications_over_time";

      try {
        let response = await this.axios.get(apiUrl);

        this.itemsPublication = response.data.data;
        this.itemsPublicationMeta = response.data.meta;

        this.generatePublicationGraph();
      } catch (e) {
        console.error(e);
      }
    },
    generatePublicationGraph() {
      // based on https://d3-graph-gallery.com/graph/connectedscatter_legend.html and https://d3-graph-gallery.com/graph/connectedscatter_tooltip.html
      // resposnsive styling based on https://chartio.com/resources/tutorials/how-to-resize-an-svg-when-the-window-is-resized-in-d3-js/

      // set the dimensions and margins of the graph
      const margin = { top: 10, right: 50, bottom: 50, left: 50 },
        width = 750 - margin.left - margin.right,
        height = 300 - margin.top - margin.bottom;

      // first remove svg
      d3.select("#publications_dataviz").select("svg").remove();

      // append the svg object to the body of the page
      const svg = d3
        .select("#publications_dataviz")
        .append("svg")
        .attr("viewBox", `0 0 750 300`)
        .attr("preserveAspectRatio", "xMinYMin meet")
        .classed("svg-content", true)
        .append("g")
        .attr("transform", "translate(" + margin.left + "," + margin.top + ")");

      const data = this.itemsPublication.map((item) => {
        return {
          group: item.group,
          values: item.values.map((value) => {
            return {
              cumulative_count: value.cumulative_count,
              publication_date_text: value.publication_date,
              publication_date: d3.timeParse("%Y-%m-%d")(
                value.publication_date
              ),
            };
          }),
        };
      });

      // generate array of all categories
      const allCategories = this.itemsPublication.map((item) => item.group);
      const maxCount = this.itemsPublicationMeta[0].max_cumulative_count;

      // generate flat array of all timepoints to compute x axis exent
      const extent_date = [];

      for (let i = 0; i < data.length; i++) {
        for (let j = 0; j < data[i].values.length; j++) {
          extent_date.push(data[i].values[j]);
        }
      }

      // A color scale: one color for each group
      const myColor = d3
        .scaleOrdinal()
        .domain(allCategories)
        .range(d3.schemeSet2);

      // Add X axis --> it is a date format
      const x = d3
        .scaleTime()
        .domain(d3.extent(extent_date, (d) => d.publication_date))
        .range([0, width]);
      svg
        .append("g")
        .attr("transform", `translate(0,${height})`)
        .call(d3.axisBottom(x));

      // Add Y axis
      const y = d3.scaleLinear().domain([0, maxCount]).range([height, 0]);
      svg.append("g").call(d3.axisLeft(y));

      // Add the lines
      const line = d3
        .line()
        .x((d) => x(+d.publication_date))
        .y((d) => y(+d.cumulative_count));
      svg
        .selectAll("myLines")
        .data(data)
        .join("path")
        .attr("class", (d) => d.group)
        .attr("d", (d) => line(d.values))
        .attr("stroke", (d) => myColor(d.group))
        .style("stroke-width", 4)
        .style("fill", "none");

      // create a tooltip
      const tooltip = d3
        .select("#publications_dataviz")
        .append("div")
        .style("opacity", 0)
        .attr("class", "tooltip")
        .style("background-color", "white")
        .style("border", "solid")
        .style("border-width", "1px")
        .style("border-radius", "5px")
        .style("padding", "2px");

      // Three function that change the tooltip when user hover / move / leave a cell
      // layerX/Y replaced by clientX/Y
      const mouseover = function (event, d) {
        tooltip.style("opacity", 1);
        
        d3.select(this).style("stroke", "black");
      };

      const mousemove = function (event, d) {
        tooltip
          .html(
            "Count: " +
              d.cumulative_count +
              "<br>Date: " +
              d.publication_date_text
          )
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

      // Add the points
      svg
        // First we need to enter in a group
        .selectAll("myDots")
        .data(data)
        .join("g")
        .style("fill", (d) => myColor(d.group))
        .attr("class", (d) => d.group)
        // Second we need to enter in the 'values' part of this group
        .selectAll("myPoints")
        .data((d) => d.values)
        .join("circle")
        .attr("cx", (d) => x(d.publication_date))
        .attr("cy", (d) => y(d.cumulative_count))
        .attr("r", 5)
        .attr("stroke", "white")
        .on("mouseover", mouseover)
        .on("mousemove", mousemove)
        .on("mouseleave", mouseleave);

      // Add a legend (interactive)
      svg
        .selectAll("myLegend")
        .data(data)
        .join("g")
        .append("text")
        .attr("x", 30)
        .attr("y", (d, i) => 30 + i * 20)
        .text((d) => d.group)
        .style("fill", (d) => myColor(d.group))
        .style("font-size", 15)
        .on("click", function (event, d) {
          // is the element currently visible ?
          const currentOpacity = d3.selectAll("." + d.group).style("opacity");
          // Change the opacity: from 0 to 1 or from 1 to 0
          d3.selectAll("." + d.group)
            .transition()
            .style("opacity", currentOpacity == 1 ? 0 : 1);
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