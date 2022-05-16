<template>
       <v-container>
        <v-row>
          <v-col
            cols="12"
            sm="12"
          >

            <v-sheet
              min-height="70vh"
              outlined
            >
  
            <v-overlay
              :absolute="absolute"
              :opacity="opacity"
              :value="loading"
              :color="color"
            >
              <v-progress-circular
                indeterminate
                color="primary"
              ></v-progress-circular>
            </v-overlay>

<!-- Tabs section -->
            <v-tabs
              v-model="tab"
              background-color="transparent"
              color="basil"
              grow
            >
              <v-tab
                v-for="item in tab_items"
                :key="item"
              >
                {{ item }}
              </v-tab>
            </v-tabs>

            <v-tabs-items v-model="tab">

              <v-tab-item
                key="Publications over time"
              >
                <v-container fill-height>
                    <v-row justify="center" align="center">
                        <v-col cols="12" sm="4">

                        <!-- Content -->
                        <div id="my_dataviz" class="svg-container"></div>
                        <!-- Content -->

                        </v-col>
                    </v-row>
                </v-container>
              </v-tab-item>

              <v-tab-item
                key="Cohort characteristic"
              >
                <v-container fill-height>
                    <v-row justify="center" align="center">
                        <v-col cols="12" sm="4">

                          <v-img
                            :src="image_cohort"
                          ></v-img>

                        </v-col>
                    </v-row>
                </v-container>
              </v-tab-item>

              <v-tab-item
                key="Phenotypes reported"
              >
                <v-container fill-height>
                    <v-row justify="center" align="center">
                        <v-col cols="12" sm="4">

                            <v-img
                              :src="image_phenotype"
                            ></v-img>

                        </v-col>
                    </v-row>
                </v-container>
              </v-tab-item>
          
            </v-tabs-items>
<!-- Tabs section -->

            </v-sheet>
          </v-col>
        </v-row>
        
      </v-container>
</template>

<script>
  import * as d3 from 'd3';

  export default {
    name: 'CohortCharacteristics',
  data() {
        return {
          tab: null,
          tab_items: [ 'Publications over time', 'Cohort characteristic', 'Phenotypes reported' ],
          absolute: true,
          opacity: 1,
          color: "#FFFFFF",
          image_publications: '',
          image_cohort: '',
          image_phenotype: '',
          reports_count: 0,
          reports_count: 0,
          reports_count: 0,
          reports_count: 0,
          loading: true
        }
      },
      computed: {
      },
      mounted() {
        this.loadImages();
        this.loadPublicationData();
      },
      methods: {
        async loadImages() {
          this.loading = true;
          let apiPublicationsPlot = process.env.VUE_APP_API_URL + '/api/statistics/publications_plot';
          let apiCohortPlot = process.env.VUE_APP_API_URL + '/api/statistics/cohort_plot';
          let apiPhenotypePlot = process.env.VUE_APP_API_URL + '/api/statistics/phenotype_plot';

          try {
            let response_publications_plot = await this.axios.get(apiPublicationsPlot);
            let response_cohort_plot = await this.axios.get(apiCohortPlot);
            let response_phenotype_plot = await this.axios.get(apiPhenotypePlot);

            this.image_publications = 'data:image/png;base64,'.concat(this.image_publications.concat(response_publications_plot.data));
            this.image_cohort = 'data:image/png;base64,'.concat(this.image_cohort.concat(response_cohort_plot.data));
            this.image_phenotype = 'data:image/png;base64,'.concat(this.image_phenotype.concat(response_phenotype_plot.data));
            } catch (e) {
            console.error(e);
            }
          this.loading = false;
        },
        async loadPublicationData() {

        let apiUrl = process.env.VUE_APP_API_URL + '/api/statistics/publications_over_time';

        try {
          let response = await this.axios.get(apiUrl);

          this.items = response.data.data;
          this.itemsMeta = response.data.meta;

          this.generatePublicationGraph();

        } catch (e) {
          console.error(e);
        }
      },
      generatePublicationGraph() {
      // based on https://d3-graph-gallery.com/graph/connectedscatter_legend.html and https://d3-graph-gallery.com/graph/connectedscatter_tooltip.html
      // resposnsive styling based on https://chartio.com/resources/tutorials/how-to-resize-an-svg-when-the-window-is-resized-in-d3-js/

      // set the dimensions and margins of the graph
      const margin = {top: 50, right: 50, bottom: 50, left: 50},
          width = 600 - margin.left - margin.right,
          height = 400 - margin.top - margin.bottom;

      // first remove svg
      d3.select("#my_dataviz")
        .select("svg")
        .remove();

      // append the svg object to the body of the page
      const svg = d3.select("#my_dataviz")
        .append("svg")
        .attr("viewBox", `0 0 600 400`)
        .attr("preserveAspectRatio", "xMinYMin meet")
        .classed("svg-content", true)
        .append("g")
          .attr("transform",
                "translate(" + margin.left + "," + margin.top + ")");

      const data = this.items.map(item => {
              return { 
                group: item.group, 
                values: item.values.map(value => {
                    return { cumulative_count: value.cumulative_count, publication_date_text: value.publication_date, publication_date: d3.timeParse("%Y-%m-%d")(value.publication_date) };
                  })
              };
            });

      // generate array of all categories
      const allCategories = this.items.map(item => item.group);
      const maxCount = this.itemsMeta[0].max_cumulative_count;

      // A color scale: one color for each group
      const myColor = d3.scaleOrdinal()
        .domain(allCategories)
        .range(d3.schemeSet2);

      // Add X axis --> it is a date format
      const x = d3.scaleTime()
        .domain(d3.extent(data[0].values, d => d.publication_date))
        .range([ 0, width ]);
        svg.append("g")
          .attr("transform", `translate(0,${height})`)
          .call(d3.axisBottom(x));

      // Add Y axis
      const y = d3.scaleLinear()
        .domain([0, maxCount])
        .range([ height, 0 ]);
        svg.append("g")
          .call(d3.axisLeft(y));

      // Add the lines
      const line = d3.line()
        .x(d => x(+d.publication_date))
        .y(d => y(+d.cumulative_count))
      svg.selectAll("myLines")
        .data(data)
        .join("path")
          .attr("class", d => d.group)
          .attr("d", d => line(d.values))
          .attr("stroke", d => myColor(d.group))
          .style("stroke-width", 4)
          .style("fill", "none")

      // create a tooltip
      const tooltip = d3.select("#my_dataviz")
        .append("div")
        .style("opacity", 0)
        .attr("class", "tooltip")
        .style("background-color", "white")
        .style("border", "solid")
        .style("border-width", "1px")
        .style("border-radius", "5px")
        .style("padding", "2px")

      // Three function that change the tooltip when user hover / move / leave a cell
      // layerX/Y replaced by clientX/Y
      const mouseover = function(event,d) {
        tooltip
          .style("opacity", 1)
      }
      const mousemove = function(event,d) {
        tooltip
          .html("Count: " + d.cumulative_count + "<br>Date: " + d.publication_date_text)
          .style("left", `${event.layerX+20}px`)
          .style("top", `${event.layerY+20}px`)
      }
      const mouseleave = function(event,d) {
        tooltip
          .style("opacity", 0)
      }

      // Add the points
      svg
        // First we need to enter in a group
        .selectAll("myDots")
        .data(data)
        .join('g')
          .style("fill", d => myColor(d.group))
          .attr("class", d => d.group)
        // Second we need to enter in the 'values' part of this group
        .selectAll("myPoints")
        .data(d => d.values)
        .join("circle")
          .attr("cx", d => x(d.publication_date))
          .attr("cy", d => y(d.cumulative_count))
          .attr("r", 5)
          .attr("stroke", "white")
        .on("mouseover", mouseover)
        .on("mousemove", mousemove)
        .on("mouseleave", mouseleave)

      // Add a legend (interactive)
      svg
        .selectAll("myLegend")
        .data(data)
        .join('g')
          .append("text")
            .attr('x', 30)
            .attr('y', (d,i) => 30 + i*20)
            .text(d => d.group)
            .style("fill", d => myColor(d.group))
            .style("font-size", 15)
          .on("click", function(event,d){
            // is the element currently visible ?
            const currentOpacity = d3.selectAll("." + d.group).style("opacity")
            // Change the opacity: from 0 to 1 or from 1 to 0
            d3.selectAll("." + d.group).transition().style("opacity", currentOpacity == 1 ? 0:1)
          })
      }
        
      }

  }
</script>


<style scoped>
  .svg-container {
    display: inline-block;
    position: relative;
    width: 100%;
    max-width: 1000px;
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