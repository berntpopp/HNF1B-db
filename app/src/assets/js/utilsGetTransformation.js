// assets/js/utilsGetTransformation.js
// based on https://bl.ocks.org/martinjc/e46f38d44a049a61ab1c2d97a2413439

export default function getTransformation(transform) {
    /*
     * This code comes from a StackOverflow answer to a question looking
     * to replace the d3.transform() functionality from v3.
     * http://stackoverflow.com/questions/38224875/replacing-d3-transform-in-d3-v4
     */
    let g = document.createElementNS("http://www.w3.org/2000/svg", "g");

    g.setAttributeNS(null, "transform", transform);
    let matrix = g.transform.baseVal.consolidate()
        .matrix;

    let {
        a,
        b,
        c,
        d,
        e,
        f
    } = matrix;
    let scaleX, scaleY, skewX;
    if (scaleX = Math.sqrt(a * a + b * b)) a /= scaleX, b /= scaleX;
    if (skewX = a * c + b * d) c -= a * skewX, d -= b * skewX;
    if (scaleY = Math.sqrt(c * c + d * d)) c /= scaleY, d /= scaleY, skewX /= scaleY;
    if (a * d < b * c) a = -a, b = -b, skewX = -skewX, scaleX = -scaleX;
    return {
        translateX: e,
        translateY: f,
        rotate: Math.atan2(b, a) * Math.PI / 180,
        skewX: Math.atan(skewX) * Math.PI / 180,
        scaleX: scaleX,
        scaleY: scaleY
    };
};