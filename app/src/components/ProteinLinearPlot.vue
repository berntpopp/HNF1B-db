<template>
    <!-- Content linear protein plot -->
    <div id="protein_linear_dataviz" class="svg-container"></div>
    <!-- Content linear protein plot -->
</template>


<script>
  import * as d3 from 'd3';

  export default {
    name: 'ProteinLinearPlot',
  data() {
        return {
          itemsDomains: [],
        }
      },
      mounted() {
          this.loadDomainData();
      },
      methods: {
        async loadDomainData() {

        let apiUrl = process.env.VUE_APP_API_URL + '/api/domains';

        try {
          let response = await this.axios.get(apiUrl);

          this.itemsDomains = response.data.data;

console.log(this.itemsDomains);

          this.generateLinearProteinGraph();

        } catch (e) {
          console.error(e);
        }
      },
      generateLinearProteinGraph() {

      // set the dimensions and margins of the graph
      const margin = {top: 100, right: 50, bottom: 50, left: 50},
          width = 800 - margin.left - margin.right,
          height = 200 - margin.top - margin.bottom;

      // set height multiplicator
      const height_factor = 4;

      // first remove svg
      d3.select("#protein_linear_dataviz")
        .select("svg")
        .remove();

      // append the svg object to the body of the page
      const svg = d3.select("#protein_linear_dataviz")
        .append("svg")
        .attr("viewBox", `0 0 800 200`)
        .attr("preserveAspectRatio", "xMinYMin meet")
        .classed("svg-content", true)
        .append("g")
          .attr("transform",
                "translate(" + margin.left + "," + margin.top + ")");



        // Parse the Data
        const data = this.itemsDomains;
        const maxLength = Math.max(...this.itemsDomains.map(o => o.length))

        // Add Y axis
        const x = d3.scaleLinear()
            .domain([0, maxLength])
            .range([ 0, maxLength ]);
        svg.append("g")
                .call(d3.axisBottom(x))
          //to do: make this dependent on height/ margins etc
          .attr("transform",
                "translate(0,50)");

        // Show the bars for the domains
        svg.selectAll("myBars")
            .data(data)
            .join('g')
            .append("rect")
              .attr("x", d => d.start)
              .attr("y", d => -1 * (d.height * height_factor / 2))
              .attr("height", d => d.height * height_factor)
              .attr("width", d => d.length)
              .attr("stroke", "black")
              .attr("stroke-width", .5)
              .attr('fill', d => d.color);

        svg.selectAll("myLegend")
          .data(data)
          .join('g')
          .append("text")
            .attr("x", d => (d.start + (d.length / 2)))
            .attr("y", 0)
            .attr("dy", ".35em")
            // constant dx has to be replaced with some function calculating string size to center it properly
            .attr("dx", "-15")
            .text(function(d) { if (d.length / maxLength > 0.05 && d.length / maxLength != 1) {return d.description_short; } });

      },
      }
  }
</script>


<style scoped>
  .svg-container {
    display: inline-block;
    position: relative;
    width: 100%;
    overflow: hidden;
}
.svg-content {
    display: inline-block;
    position: absolute;
    top: 0;
    left: 0;
}
</style>