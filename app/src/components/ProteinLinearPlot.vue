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

          const itemsDomains = response.data.data;

          this.generateLinearProteinGraph(itemsDomains);

        } catch (e) {
          console.error(e);
        }
      },
      generateLinearProteinGraph(domain_input) {

      // set the dimensions and margins of the graph
      const margin = {top: 20, right: 50, bottom: 0, left: 50},
          height = 120 ;

      // set height multiplicator
      const height_factor = 4;

      // set y shift
      const y_shift = 30;

      // set length multiplicator
      const length_factor = 1.3;

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


        // Parse the input data
        const domain_data = domain_input.map(obj => {
          return {...obj, 
            height: obj.height * height_factor,
            start: obj.start * length_factor,
            length: obj.length * length_factor,
          };
        });

        const maxLength = Math.max(...domain_input.map(o => o.length));
        const maxLengthScaled = Math.max(...domain_input.map(o => o.length)) * length_factor;

        // Add x axis
        const x = d3.scaleLinear()
          .domain([ 0, maxLength ])
          .range([ 0, maxLengthScaled ]);

        svg.append("g")
          .attr("transform", `translate(0,${height})`)
          .call(d3.axisBottom(x));

        // Add Y axis
        const y = d3.scaleLinear()
          .domain([0, 30])
          .range([ height, 0 ]);

        // Show the bars for the domains
        svg.selectAll("myBars")
          .data(domain_data)
          .join('g')
          .append("rect")
            .attr("x", d => d.start)
            .attr("y", d => -1 * (d.height / 2) - y_shift)
            .attr("height", d => d.height)
            .attr("width", d => d.length)
            .attr("stroke", "black")
            .attr("stroke-width", .5)
            .attr('fill', d => d.color)
          .attr("transform", `translate(0,${height})`);

        // add labels dor domain bars
        svg.selectAll("myLegend")
          .data(domain_data)
          .join('g')
          .append("text")
            .attr("x", d => (d.start + (d.length / 2)))
            .attr("y", 0 - y_shift)
            .attr("dy", ".35em")
            .style("font-size", "12px")
            .style("text-anchor", "middle")
            .text(function(d) { if (d.length / maxLengthScaled > 0.05 && d.length / maxLengthScaled != 1) {return d.description_short; } })
          .attr("transform", `translate(0,${height})`);

      },
      }
  }
</script>


<style scoped>
  .svg-container {
    display: inline-block;
    position: relative;
    width: 100%;
    max-width: 1400px;
    vertical-align: top;
    overflow: hidden;
}
.svg-content {
    display: inline-block;
    position: relative;
    top: 0;
    left: 0;
}
</style>