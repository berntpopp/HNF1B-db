// based on https://www.npmjs.com/package/vue-cli-plugin-sitemap#installation
require = require("esm")(module);
const { routes } = require("./src/router/routes.js");

module.exports = {
  transpileDependencies: [
    'vuetify'
  ],
  pluginOptions: {
    sitemap: {
      baseURL: "https://hnf1b.uni-leipzig.de",
      outputDir: "./public",
      pretty: true,
      routes,
    },
    webpackBundleAnalyzer: {
      openAnalyzer: false,
    },
  },
};
