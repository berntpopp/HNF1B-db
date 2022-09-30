// assets/js/mixins/colorAndSymbolsMixin.js
import { mdiPlusCircleOutline, mdiMinusCircleOutline, mdiHelpCircleOutline, mdiGenderFemale, mdiGenderMale, mdiCheckCircleOutline, mdiAccount, mdiAccountCowboyHat, mdiAccountSchool, mdiDna, mdiNewspaperVariant, mdiBookOpenBlankVariant, mdiRefresh, mdiDownload } from '@mdi/js';

export default {
    data() {
      return {
        icons: {
          mdiPlusCircleOutline,
          mdiMinusCircleOutline,
          mdiHelpCircleOutline,
          mdiGenderFemale,
          mdiGenderMale,
          mdiCheckCircleOutline,
          mdiAccountCowboyHat,
          mdiAccountSchool,
          mdiDna,
          mdiNewspaperVariant,
          mdiBookOpenBlankVariant,
          mdiRefresh,
          mdiDownload
        },
        type_color: {
          individual: "lime lighten-2",
          variant: "pink lighten-4",
          report: "deep-orange lighten-2",
          publication: "cyan accent-2"
        },
        cohort_color: {
          born: "success",
          fetus: "primary"
        },
        reported_phenotype_color: {
          yes: "teal lighten-1",
          no: "light-blue",
          "not reported": "white",
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
        type_symbol: {
          individual: mdiAccount,
          variant: mdiDna,
          report: mdiNewspaperVariant,
          publication: mdiBookOpenBlankVariant
        },
        reported_phenotype_symbol: {
          yes: mdiPlusCircleOutline,
          no: mdiMinusCircleOutline,
          "not reported": mdiHelpCircleOutline,
        },
        sex_symbol: {
          female: mdiGenderFemale,
          male: mdiGenderMale,
          unspecified: mdiHelpCircleOutline,
        },
        logical_symbol: {
          1: mdiCheckCircleOutline,
          0: mdiMinusCircleOutline,
        },
        user_symbol: {
          Administrator: mdiAccountCowboyHat,
          Reviewer: mdiAccountSchool,
        },
      };
    },
  }