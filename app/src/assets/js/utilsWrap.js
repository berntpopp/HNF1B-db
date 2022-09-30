// assets/js/utilsWrap.js
// based on https://bl.ocks.org/martinjc/e46f38d44a049a61ab1c2d97a2413439

import * as d3 from "d3";

export default function wrap(text, width) {
    text.each(function() {
        var text = d3.select(this);
        var words = text.text()
            .split(/ |\,|_/)
            .reverse();
        var word;
        var line = [];
        var lineHeight = 1;
        var y = 0 //text.attr("y");
        var x = 0;
        var dy = parseFloat(text.attr("dy"));
        var dx = parseFloat(text.attr("dx"));
        var tspan = text.text(null)
            .append("tspan")
            .attr("x", x)
            .attr("y", y);
        while (word = words.pop()) {
            line.push(word);
            tspan.text(line.join(" "));
            if (tspan.node()
                .getComputedTextLength() > width - x) {
                line.pop();
                tspan.text(line.join(" "));
                line = [word];
                tspan = text.append("tspan")
                    .attr("x", x)
                    .attr("dy", lineHeight + "em")
                    .attr("dx", dx + "em")
                    .text(word);
            }
        }
    });
};