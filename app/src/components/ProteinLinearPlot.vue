<template>
  <v-container fluid>

    <!-- Controls-->
    <v-row v-if="show_controls">
      <v-col>

        <v-select
          :items="classification_options"
          v-model="classification_select"
          label="Classification"
          outlined
          multiple
          chips
        ></v-select>

      </v-col>
      <v-col>

        <v-select
          :items="variant_class_options"
          v-model="variant_class_select"
          label="Variant class"
          outlined
          multiple
          chips
        ></v-select>

      </v-col>
    </v-row>
    <!-- Controls-->

    <!-- Content linear protein plot -->
    <div id="protein_linear_dataviz" class="svg-container"></div>
    <!-- Content linear protein plot -->
  </v-container>
</template>


<script>
  import * as d3 from 'd3';

  export default {
    name: 'ProteinLinearPlot',
    props: {
      show_controls:  {type: Boolean,  default: false},
      variant_filter:  {type: String,  default: ''},
    },
  data() {
        return {
          classification_select: ['Pathogenic', 'Likely Pathogenic', 'Uncertain Significance', 'Likely Benign'],
          classification_options: ['Pathogenic', 'Likely Pathogenic', 'Uncertain Significance', 'Likely Benign'],
          variant_class_select: ['SNV', 'deletion', 'insertion', 'indel'],
          variant_class_options: ['SNV', 'deletion', 'insertion', 'indel'],
        }
      },
      mounted() {
          this.loadDomainData();
      },
      watch: {
        classification_select(value) {
          this.loadDomainData();
        },
        variant_class_select(value) {
          this.loadDomainData();
        },
      },
      methods: {
        async loadDomainData() {

        // compute the filter string by joining the filter object
        const filter_variant_class = 'any(variant_class,' + this.variant_class_select.join(',') + ')';
        const filter_classification = 'any(verdict_classification,' + this.classification_select.join(',') + ')';
        const filter_expression = '&filter=' + filter_variant_class + ',' + filter_classification + ',' + this.variant_filter;
        console.log(this.variant_filter);

        // define API URLs
        let apiUrlDomains = process.env.VUE_APP_API_URL + '/api/domains';
        let apiUrlVariants = process.env.VUE_APP_API_URL + '/api/variants?sort=variant_id&fields=variant_id,variant_class,FEATUREID,HGVS_C,HGVS_P,IMPACT,EFFECT,Protein_position,CADD_PHRED,verdict_classification&page[after]=0&page[size]=all' + filter_expression;

        try {
          let responseDomains = await this.axios.get(apiUrlDomains);
          let responseVariants = await this.axios.get(apiUrlVariants);

          const itemsDomains = responseDomains.data.data;
          const itemsVariants = responseVariants.data.data;

          this.generateLinearProteinGraph(itemsDomains, itemsVariants);

        } catch (e) {
          console.error(e);
        }
      },
      generateLinearProteinGraph(domain_input, variant_input) {

      // set the dimensions and margins of the graph
      const margin = {top: 50, right: 50, bottom: 0, left: 50},
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

        const variant_data = variant_input.map(obj => {
          return {...obj, 
            Protein_position: obj.Protein_position,
          };
        });

        // Add x axis
        const x = d3.scaleLinear()
          .domain([ 0, maxLength ])
          .range([ 0, maxLengthScaled ]);

        svg.append("g")
          .attr("transform", `translate(0,${height})`)
          .call(d3.axisBottom(x));

        // Add Y axis
        const y = d3.scaleLinear()
          .domain([0, 50])
          .range([ height, 0 ]);


// create a tooltip
const tooltip = d3.select("#protein_linear_dataviz")
  .append("div")
  .attr('id', 'tooltip')
  .attr("class", "tooltip")
  .style("opacity", 0)
  .style("background-color", "white")
  .style("border", "solid")
  .style("border-width", "1px")
  .style("border-radius", "5px")
  .style("padding", "2px");

// Three function that change the tooltip when user hover / move / leave a cell
// layerX/Y replaced by clientX/Y
const mouseover = function(event,d) {
  tooltip
    .style("opacity", 1);
  
  d3.select(this)
      .style("stroke-width", 2)
      .style("stroke", "black");
}
const mousemove = function(event,d) {
  tooltip
    .html(d.FEATUREID + ": " +d.HGVS_C + ", " + d.HGVS_P + "<br /> [CADD: " + d.CADD_PHRED + "]" + "<br /> [Classification: " + d.verdict_classification + "]")
    .style("left", (event.clientX + 20 ) + 'px')
    .style("top", (event.clientY + 10 ) + 'px');
}
const mouseleave = function(event,d) {
  tooltip
    .style("opacity", 0);
  
  d3.select(this)
      .style("stroke-width", 1)
      .style("stroke", "grey");
}

// color palette = one color per subgroup
const color = d3.scaleOrdinal()
  .domain(["HIGH", "MODERATE", "LOW", "MODIFIER"])
  .range(['#FE5F55','#90CAF9','#C7EFCF','#FFFFFF'])

// Lolli lines
svg.selectAll("myLines")
  .data(variant_data)
  .enter()
  .append("line")
    .attr("x1", function(d) { return x(d.Protein_position); })
    .attr("x2", function(d) { return x(d.Protein_position); })
    .attr("y1", function(d) { return y(d.CADD_PHRED + 15); })
    .attr("y2", y(15))
    .attr("stroke", "grey")

// Lolli circles
svg.selectAll("myCircles")
  .data(variant_data)
  .enter()
  .append("a")
  .attr("xlink:href", function(d) { return "/variant/" + d.variant_id; })
  .append("circle")
    .attr("cx", function(d) { return x(d.Protein_position); })
    .attr("cy", function(d) { return y(d.CADD_PHRED + 15); })
    .attr("r", "4")
    .style("fill", function(d) { return color(d.IMPACT); })
    .attr("stroke", "grey")
  .on("mouseover", mouseover)
  .on("mousemove", mousemove)
  .on("mouseleave", mouseleave)


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

        // add labels for domain bars
        svg.selectAll("myLabels")
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


<style>
.tooltip {
  display: inline;
  position: fixed;
}
</style>