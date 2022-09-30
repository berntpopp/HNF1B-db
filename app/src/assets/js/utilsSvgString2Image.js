// assets/js/utilsSvgString2Image.js
// based on http://bl.ocks.org/rokotyan/0556f8facbaf344507cdc45dc3622177

const dataURLtoBlob = require('blueimp-canvas-to-blob');

// Below are the functions that handle actual exporting:
// svgString2Image( svgString, width, height, format, callback ))
export default function svgString2Image( svgString, width, height, format, callback ) {
	var format = format ? format : 'png';

	var imgsrc = 'data:image/svg+xml;base64,'+ btoa( unescape( encodeURIComponent( svgString ) ) ); // Convert SVG string to data URL
	var canvas = document.createElement("canvas");
	var context = canvas.getContext("2d");

	canvas.width = width;
	canvas.height = height;

	var image = new Image();
	image.onload = function() {
		context.fillStyle = "white";
		context.fillRect ( 0, 0, width, height );
		context.drawImage(image, 10, 10, width, height);

		canvas.toBlob( function(blob) {
			var filesize = Math.round( blob.length/1024 ) + ' KB';
			if ( callback ) callback( blob, filesize );
		});
	};

	image.src = imgsrc;
};