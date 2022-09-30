// assets/js/utilsArrangeLabels.js
// based on https://bl.ocks.org/martinjc/e46f38d44a049a61ab1c2d97a2413439

import * as d3 from "d3";
import getTransformation from "@/assets/js/utilsGetTransformation.js";

export default function arrangeLabels(selection, label_class) {
    let move = 1;
    while (move > 0) {
        move = 0;
        selection.selectAll(label_class)
            .each(function() {
                let that = this;
                let a = this.getBoundingClientRect();
                selection.selectAll(label_class)
                    .each(function() {
                        if (this != that) {
                            let b = this.getBoundingClientRect();
                            if ((Math.abs(a.left - b.left) * 2 < (a.width + b.width)) && (Math.abs(a.top - b.top) * 2 < (a.height + b.height))) {
                                let dx = (Math.max(0, a.right - b.left) + Math.min(0, a.left - b.right)) * 0.01;
                                let dy = (Math.max(0, a.bottom - b.top) + Math.min(0, a.top - b.bottom)) * 0.02;
                                let tt = getTransformation(d3.select(this)
                                    .attr("transform"));
                                let to = getTransformation(d3.select(that)
                                    .attr("transform"));
                                move += Math.abs(dx) + Math.abs(dy);

                                to.translate = [to.translateX + dx, to.translateY + dy];
                                tt.translate = [tt.translateX - dx, tt.translateY - dy];
                                d3.select(this)
                                    .attr("transform", "translate(" + tt.translate + ")");
                                d3.select(that)
                                    .attr("transform", "translate(" + to.translate + ")");
                                a = this.getBoundingClientRect();
                            }
                        }
                    });
            });
    }
};