// assets/js/mixins/colorAndSymbolsMixin.js
export default {
    data() {
      return {
        cohort_color: {
          born: "success",
          fetus: "primary"
        },
        reported_phenotype_color: {
          yes: "teal lighten-1",
          no: "light-blue",
          "not reported": "white",
        },
        reported_phenotype_symbol: {
          yes: "mdi-plus-circle-outline",
          no: "mdi-minus-circle-outline",
          "not reported": "mdi-help-circle-outline",
        },
        sex_symbol: {
          female: "mdi-gender-female",
          male: "mdi-gender-male",
          unspecified: "mdi-help-circle-outline",
        },
        logical_symbol: {
          1: "mdi-check-circle-outline",
          0: "mdi-minus-circle-outline",
        },
        variant_class_color: {
          copy_number_gain: "#3466C8",
          copy_number_loss: "#DB3B1F",
          SNV: "#17962A",
          insertion: "#FE9A2B",
          deletion: "#FE9A2B",
          indel: "#FE9A2B"
        },
        impact_color: {
          HIGH: "#FE5F55",
          MODERATE: "#90CAF9",
          LOW: "#C7EFCF",
          MODIFIER: "#FFFFFF"
        },
        classification_color: {
            Pathogenic: "deep-orange darken-3",
            'Likely Pathogenic': "deep-orange darken-1",
            'Uncertain Significance': "orange lighten-1",
            'Likely Benign': "green lighten-2",
            Benign: "green darken-4",
        },
        criteria_color: {
          P: {
            VeryStrong: "deep-orange darken-3",
            Strong: "deep-orange darken-1",
            Moderate: "orange darken-2",
            Supporting: "orange lighten-1",
          },
          B: {
            VeryStrong: "green darken-4",
            Strong: "green darken-2",
            Moderate: "green lighten-2",
            Supporting: "green lighten-4",
          }
        },
        cohort_style: {
          born: "success",
          fetus: "primary"
        },
      };
    },
  }