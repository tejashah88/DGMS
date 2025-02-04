#!/bin/bash

function check {
	programs="$@"
	for p in ${programs}; do
		if ! type $p >/dev/null 2>&1; then
			echo "This program needs \"$p\" but it's not installed, Aborting."
			exit 1
		fi
	done
}

check tor wget ls cp cat xmllint sed echo printf read bc touch export nc awk grep sleep rm basename sort head identify mkdir cut jobs

function gen_html {
	long=$1
	lat=$2
	mz=$3
	Mz=$4
	name=$5
cat <<HTML > $name.html
<html>
	<head>
		<meta charset=utf-8 />
		<title>$name</title>
		<meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, minimum-scale=1.0, user-scalable=0" />
		<script src="./tiles/js/jquery-1.12.4.min.js"></script>
		<script src="./tiles/js/jquery-ui-1.12.1.min.js"></script>
		<script src="./tiles/js/jquery.ui.touch-punch.min.js"></script>
		<style type="text/css">
			body {
				margin: 0;
				overflow:hidden;
			}
			*::selection {
				background: transparent;
			}
			table {
				padding: 0; margin: 0;
				border-collapse: collapse;
				background-color: gray;
				table-layout: fixed;
				width: 100px;
			}
			table tr {
				padding: 0; margin: 0;
			}
			table td {
				padding: 0; margin: 0;
				background-image: url('./tiles/img/blank.jpg');
				width: 256px;
				height: 256px;
				text-align: center;
				vertical-align: middle;
				/*border-width:1px;
				border-style:solid;
				border-color:red;*/
			}
			.draggable {
				position: absolute;
			}
			#overlay {
				position: fixed;
				top: 0;
				left: 0;
				width: 100%;
				height: 80px;
				background:rgba(255,255,255,0.3);
				z-index: 10000;
				border-bottom: 1px solid #000;
			}
			.top {
				z-index: 10001;
			}
			#cross {
				z-index: 10002;
				position: fixed;
			}
			#coords {
				padding: 5px;
				padding-left: 25px;
			}
			#current_zoom {

				font-family: Roboto,Arial,sans-serif;
				color: #222;
				text-shadow: 0px 2px 3px #555;
				font-size: 70px;
				padding-left: 25px;
			}
			.coords {
				font-family: Roboto,Arial,sans-serif;
				color: #222;
				text-shadow: 0px 2px 3px #555;
				font-size: 30px;
			}
		</style>
	</head>
	<body>
		<div class="top" style="display: inline; float: left; width: 160px; height: 100%" id="zoom">
			<img class="top" src="./tiles/img/zp.png" id="plus" style="height: 70px; width: 70px; margin: 5px"/><img class="top" src="./tiles/img/zm.png" id="minus" style="height: 70px; width: 70px; margin: 5px"/>
		</div>
		<img src="./tiles/img/cross.png" width="50px" height="50px" id="cross">
		<table class="draggable" id="map">
			<tr>
				<td id="alpha">
				</td>
			</tr>
		</table>
	</body>
	<script type="text/javascript">

		/*******************************************== SECTION MODIFIED BY THE BASH SCRIPT ==*******************************************************/

		var default_zoom = $Mz,										// the default zoom given to the bash script
			init_coords = {'lat': $lat, 'long': $long},				// the initial coordinates given to the bash script
			MAX_ZOOM = 23,											// the zoom interval given (or set by default) to the bash script
			MIN_ZOOM = 2;

		/*******************************************************************************************************************************************/

		function latlong2XY(z, lat, long) {							// convert latitude and longitude to X and Y Google coordinates (int)
			return {
				'X': Math.floor(Math.pow(2, z-1)*((long/180)+1)),
				'Y': Math.pow(2,z)-Math.ceil((Math.pow(2,z-1)/Math.PI)*(Math.log(Math.tan((90+lat)*(Math.PI/360)))+Math.PI))
			}
		}

		function latlong2PureXY(z, lat, long) {						// convert latitude and longitude to X and Y (hacked) Google coordinates (float)
			return {
				'X': Math.pow(2, z-1)*((long/180)+1),
				'Y': Math.pow(2,z)-(Math.pow(2,z-1)/Math.PI)*(Math.log(Math.tan((90+lat)*(Math.PI/360)))+Math.PI)
			}
		}

		function pureXY2latlong(z, pureX, pureY) {					// convert pure X and Y (float) coordinates to latitude and logitude coordinates
			var long = 180*(Math.pow(2, 1-z)*pureX-1);
			var lat = ((360/Math.PI)*Math.atan(Math.exp(Math.pow(2,1-z)*Math.PI*(Math.pow(2,z)-pureY)-Math.PI)))-90;
			return {'lat': lat, 'long': long}
		}

		function zoom(z, first_time) {
			first_time = first_time || false;
			if (z < MIN_ZOOM || z > MAX_ZOOM) {
				$.zooming = false;
				return true;									// do not exceed max and min zoom, return true to say that no zoom has happened
			}

			var long = \$("#long").html();						// read lat and long from SPAN tags
			var lat = \$("#lat").html();
			old_coords = {'lat': lat, 'long': long};			// store theses coords, we'll need them when zoom finishes, to return to them
			if (!lat && !long) {								// if there is nothing in SPAN tags, affect the default coordinates
				lat = init_coords.lat;
				long = init_coords.long;
			}

			lat = parseFloat(lat);
			long = parseFloat(long);
			var pureOldX = latlong2PureXY(z, lat, long).X;		// pure means get the float number of the tile (it's number + fraction of the next one)
			var pureOldY = latlong2PureXY(z, lat, long).Y;
			var X = latlong2XY(z, lat, long).X;					// get only the entire part (in this case the number of the tile -- VERY IMPORTANT)
			var Y = latlong2XY(z, lat, long).Y;
			\$("#map").html("<tr><td id='alpha'></td></tr>");	// reset the map
			\$("#alpha").attr('coord', X).append("<img style='background:url(./tiles/s/" + default_zoom + "/" + X + "/" + Y + ".jpg)' src='./tiles/h/" + default_zoom + "/" + X + "/" + Y + ".png' onerror='this.src = \"./tiles/img/transparent.png\"'>").parent().attr('coord', Y);	// put the first (landmark) tile
			\$("#map").center().grow();							// center the table (with a single tile) then expand it until it reaches or exceeds the window borders
			\$("#cross").center();
			\$("#current_zoom").html(z);
			/*
			 * when zooming, the geographic position at the center of
			 * the screen (on the cross) changes, for user comfort we'll
			 * move the table (the map) until this position returns at the center of the screen
			 */
			if (first_time) return false;						// if it's the first zoom (i.e. when the page loads) no need to slide!

			setTimeout(function() {
				new_coords = compute_coords(z);					// compute new coordinates, and store them to compare to the old ones
				var long = new_coords.long;
				var lat = new_coords.lat;
				var pureNewX = Math.pow(2, z-1)*((long/180)+1);
				var pureNewY = Math.pow(2,z)-(Math.pow(2,z-1)/Math.PI)*(Math.log(Math.tan((90+lat)*(Math.PI/360)))+Math.PI);
				\$("#map").animate({							// change the position of the map, by comparing the pure old offsets and the pure new ones
					top: "-=" + 256*(pureOldY - pureNewY),
					left: "-=" + 256*(pureOldX - pureNewX)
				}, 600, 'easeOutBounce', function() {
					compute_coords(z);							// recompute coordinates
					\$("#map").grow();							// expand the table in case some borders entered the screen
					$.zooming = false;							// now you can zoom
				});
			}, 200);
			return false										// return false to confirm that a zoom has happened
		}

		function compute_coords(z) {
			/*
			 * function that compute the new coordinates
			 * at the center of the window
			 */
			var xcenter = \$("#cross").offset().left + \$("#cross").width() / 2;		// get the position of the cross (by default at the center)
			var ycenter = \$("#cross").offset().top + \$("#cross").height() / 2;
			\$("#cross").hide();										// hide it a short time to be able to get the element that
			var tile = document.elementFromPoint(xcenter, ycenter);		// is at the center of the window (other than the cross
			\$("#cross").show();
			\$("#cross").center();										// make sure to re-center the cross after a drag event

			if (tile == null) {											// if the cursor has gone out of bounds, there no valid tile behind
				\$("#lat").html("N/A");									// so just pass the initial coordinates as the output
				\$("#long").html("N/A");
				return init_coords;
			} else if (tile.tagName == "IMG") {							// a little hack to handle what happens when the window loads (there is no IMG yet)
				var X = \$(tile).parent().attr('coord');
				var Y = \$(tile).parent().parent().attr('coord');
			} else {
				var X = \$(tile).attr('coord');
				var Y = \$(tile).parent().attr('coord');
			}

			var x = \$(tile).offset().left;
			var y = \$(tile).offset().top;
			var dx = xcenter - x;
			var dy = ycenter - y;
			var pureX = parseFloat(X) + (dx/256);						// to get the pure X and Y (the true coordinates), add to the X and Y
			var pureY = parseFloat(Y) + (dy/256);						// a fraction of 1 representing the position of the cross on the (center) tile
			var latlong = pureXY2latlong(z,pureX,pureY);
			var long = latlong.long;									// get the current latitude and longitude coordinates on the center
			var lat = latlong.lat;
			long = Math.round(long*1000000)/1000000;					// round them to float with 6 digits
			lat = Math.round(lat*1000000)/1000000;
			\$("#lat").html(lat.format(6));								// format them to float with 6 digits and display them at the top of screen
			\$("#long").html(long.format(6));
			return {'lat': lat, 'long': long};							// return them for convenience
		}

		if (typeof Number.prototype.format === 'undefined') {			// a "format" method
			Number.prototype.format = function (precision) {
				if (!isFinite(this)) {
					return this.toString();
				}

				var a = this.toFixed(precision).split('.');
				a[0] = a[0].replace(/\d(?=(\d{3})+$)/g, '$&,');
				return a.join('.');
			}
		}

		\$(document).ready(function() {

			document.body.addEventListener('touchstart', function(e){ e.preventDefault(); });			// forgot what it does :-p (for mobiles)

			$.fn.center = function () {
				this.css("position","absolute");
				this.css("top", Math.max(0, ((\$(window).height() - \$(this).outerHeight()) / 2) + \$(window).scrollTop()) + "px");
				this.css("left", Math.max(0, ((\$(window).width() - \$(this).outerWidth()) / 2) + \$(window).scrollLeft()) + "px");
				return this;
			}

			$.fn.allOffsets = function () {			// get the four offsets
				return {
					left: this.offset().left,
					top: this.offset().top,
					bottom: \$(window).height() - this.height() - this.offset().top,
					right: \$(window).width() - this.width() - this.offset().left
				}
			}

			$.fn.grow = function () {				// important piece of code, it expands the table whenever moved and some borders enter the screen
				var ltbr = this.allOffsets();
				var l = ltbr.left;
				var t = ltbr.top;
				var r = ltbr.right;
				var b = ltbr.bottom;
				/*
				 * will test all four borders, if one of them is inside the screen
				 * expand the table on that side
				 */
				if (l > 0) {
					/*
					 * get the table height (number of TR) then APPEND to
					 * each TR a TD with the coord of the FIRST
					 * TD in the first TR MINUS 1
					 */
					var dy = this.find('tr').length;
					var xcoord = this.find('tr:first-child').find('td:first-child').attr('coord');
					for (var i = 1; i <= dy; i++) {
						this.find('tr:nth-child(' + i + ')')
							.prepend("<td coord='" + (parseInt(xcoord) - 1) + "'></td>");
						this.find('tr:nth-child(' + i + ')')
							.find("td[coord=" + (parseInt(xcoord) - 1) + "]")
							.append(\$("<img style='background:url(./tiles/s/" + default_zoom + '/' + (parseInt(xcoord) - 1) + "/" + this.find('tr:nth-child(' + i + ')').attr('coord') + ".jpg)' src='./tiles/h/" + default_zoom + '/' + (parseInt(xcoord) - 1) + "/" + this.find('tr:nth-child(' + i + ')').attr('coord') + ".png' onerror='this.src = \"./tiles/img/transparent.png\"'>").hide().fadeIn());
					}
					this.offset({left: this.offset().left - 256});	// when expanding to the left the tiles will shift to the right by 256px, move the table to the left by 256 px
				} else if (l < -2048) {
					var dy = this.find('tr').length;
					for (var i = 1; i <= dy; i++) {
						this.find('tr:nth-child(' + i + ')').find("td:first-child").remove();
					}
					this.offset({left: this.offset().left + 256});	// when croping on the left the tiles will shift to the left by 256px, move the table to the right by 256 px
				}
				if (r > 0) {
					/*
					 * get the table height (number of TR) then PREPEND to
					 * each TR a TD with the coord of the LAST
					 * TD in the first TR PLUS 1
					 */
					var dy = this.find('tr').length;
					var xcoord = this.find('tr:first-child').find('td:last-child').attr('coord');
					for (var i = 1; i <= dy; i++) {
						this.find('tr:nth-child(' + i + ')')
							.append("<td coord='" + (parseInt(xcoord) + 1) + "'></td>");
						this.find('tr:nth-child(' + i + ')')
							.find("td[coord=" + (parseInt(xcoord) + 1) + "]")
							.append(\$("<img style='background:url(./tiles/s/" + default_zoom + '/' + (parseInt(xcoord) + 1) + "/" + this.find('tr:nth-child(' + i + ')').attr('coord') + ".jpg)' src='./tiles/h/" + default_zoom + '/' + (parseInt(xcoord) + 1) + "/" + this.find('tr:nth-child(' + i + ')').attr('coord') + ".png' onerror='this.src = \"./tiles/img/transparent.png\"'>").hide().fadeIn());
					}

				} else if (r < -2048) {
					var dy = this.find('tr').length;
					for (var i = 1; i <= dy; i++) {
						this.find('tr:nth-child(' + i + ')').find("td:last-child").remove();
					}
				}
				if (t > 0) {
					/*
					 * get the table width (number of TD on the first TR)
					 * then APPEND a TR with this length and the
					 * appropriate coordinate, then fill
					 * it with TD's with the given coordinates (by incrementation)
					 */
					var dx = this.find('tr:first-child').find('td').length;
					var ycoord = this.find('tr:first-child').attr("coord");
					var xcoord = this.find('tr:first-child').find('td:first-child').attr("coord");
					this.prepend("<tr coord='" + (parseInt(ycoord) - 1) + "'></tr>");
					for (var i = 0; i < dx; i++) {
						\$("tr[coord=" + (parseInt(ycoord) - 1) + "]")
							.append("<td coord=" + xcoord + "></td>");
						\$("tr[coord=" + (parseInt(ycoord) - 1) + "]")
							.find("td[coord=" + xcoord + "]")
							.append(\$("<img style='background:url(./tiles/s/" + default_zoom + '/' + xcoord + "/" + (parseInt(ycoord) - 1) + ".jpg)' src='./tiles/h/" + default_zoom + '/' + xcoord + "/" + (parseInt(ycoord) - 1) + ".png' onerror='this.src = \"./tiles/img/transparent.png\"'>").hide().fadeIn());
						xcoord++;
					}
					this.offset({top: this.offset().top - 256});	// when expanding to the top the tiles will shift to the bottom by 256px, move the table to the top by 256 px
				} else if (t < -2048) {
					var dx = this.find('tr:first-child').find('td').length;
					this.find("tr:first-child").remove();
					this.offset({top: this.offset().top + 256});	// when croping on the top the tiles will shift to the top by 256px, move the table to the bottom by 256 px
				}
				if (b > 0) {
					/*
					 * get the table width (number of TD on the first TR)
					 * then PREPEND a TR with this length and the
					 * appropriate coordinate, then fill
					 * it with TD's with the given coordinates (by incrementation)
					 */
					var dx = this.find('tr:first-child').find('td').length;
					var ycoord = this.find('tr:last-child').attr("coord");
					var xcoord = this.find('tr:first-child').find('td:first-child').attr("coord");
					this.append("<tr coord='" + (parseInt(ycoord) + 1) + "'></tr>");
					for (var i = 0; i < dx; i++) {
						\$("tr[coord=" + (parseInt(ycoord) + 1) + "]")
							.append("<td coord=" + xcoord + "></td>");
						\$("tr[coord=" + (parseInt(ycoord) + 1) + "]")
							.find("td[coord=" + xcoord + "]")
							.append(\$("<img style='background:url(./tiles/s/" + default_zoom + '/' + xcoord + "/" + (parseInt(ycoord) + 1) + ".jpg)' src='./tiles/h/" + default_zoom + '/' + xcoord + "/" + (parseInt(ycoord) + 1) + ".png' onerror='this.src = \"./tiles/img/transparent.png\"'>").hide().fadeIn());
						xcoord++;
					}
				} else if (b < -2048) {
					var dx = this.find('tr:first-child').find('td').length;
					this.find("tr:last-child").remove();
				}
				var ltbr = this.allOffsets();
				var l = ltbr.left;
				var t = ltbr.top;
				var r = ltbr.right;
				var b = ltbr.bottom;
				if (l > 0 || t > 0 || r > 0 || b > 0) this.grow();	// if the table borders are still inside the screen expand it once again...
			}

			\$("#map").draggable({						// make the map (the TABLE) draggable both on PC's and mobiles
				drag: function( event, ui ) {
					cursor: "hand",
					compute_coords(default_zoom);		// permanently compute and display the coordinates of the center of the map
				},
				stop: function( event, ui) {
					\$(this).grow();						// once the drag has finished, expand the TABLE
				}
			});

			var overlay = \$('<div id="overlay"></div>');	// add an overlay at the top of the screen, with two buttons and two spans
			overlay
				.append(\$("#zoom"))
				.append('<div id="coords" style="display: inline; float: left; width: auto; height: 100%"><span class="coords" id="lat"></span><br/><span class="coords" id="long"></span></div><div style="display: inline; float: left; width: auto; height: 100%"><span id="current_zoom" id="lat">$Mz</span></div>');

			/*
			 * THE FIRST ZOOM WICH WILL DISPLAY THE CENTER TILE
			 * (THE ONE COORDINATES YOU CHOOSE IN BASH SCRIPT BELONG TO)
			 * THEN EXPAND IT, PASS THE TRUE ARGUMENT SO NO SLIDING
			 * (CORRECTION OF COORDINATES) WILL BE DONE (NO NEED TO IT!)
			 */

			zoom(default_zoom, true);
			overlay.appendTo(document.body);
			compute_coords(default_zoom);

			/*
			 * bind zoom() function to the PLUS/MINUS buttons
			 */

			\$("#plus")
				.click(function() {
					if ($.zooming) return false;
					$.zooming = true;
					zoom(++default_zoom) && default_zoom--;		// if no more zoom possible, revert the incrementation
				})
				.bind('touchstart',function() {					// BUG IN THE jquery.ui.touch-punch LIBRARY, CLICK IS
					if ($.zooming) return false;
					$.zooming = true;
					zoom(++default_zoom) && default_zoom--;		// NOT BINDED TO TOUCH EVENTS, MUST DO IT PROGRAMATICALLY
				});
			\$("#minus")
				.click(function() {
					if ($.zooming) return false;
					$.zooming = true;
					zoom(--default_zoom) && default_zoom++;
				})
				.bind('touchstart',function() {
					if ($.zooming) return false;
					$.zooming = true;
					zoom(--default_zoom) && default_zoom++;
				});

			/*
			 * handle arrow/+/- key presses
			 * to avoid repetitions, lock the
			 * process using local variables
			 */

			$.going_left = $.going_right = $.going_top = $.going_bottom = $.zooming = false;		// variables needed to avoid keypress repetitions

			\$(document).keydown(function(e){
				if (e.keyCode == 37) {
					if ($.going_left) return false;
					$.going_left = true;
					\$("#map").animate({left: "+=200"}, 300, function() {
						\$("#map").grow();
						compute_coords(default_zoom);
						$.going_left = false;
					});
					return false;
				} else if (e.keyCode == 38) {
					if ($.going_top) return false;
					$.going_top = true;
					\$("#map").animate({top: "+=200"}, 300, function() {
						\$("#map").grow();
						compute_coords(default_zoom);
						$.going_top = false;
					});
					return false;
				} else if (e.keyCode == 39) {
					if ($.going_right) return false;
					$.going_right = true;
					\$("#map").animate({left: "-=200"}, 300, function() {
						\$("#map").grow();
						compute_coords(default_zoom);
						$.going_right = false;
					});
					return false;
				} else if (e.keyCode == 40) {
					if ($.going_bottom) return false;
					$.going_bottom = true;
					\$("#map").animate({top: "-=200"}, 300, function() {
						\$("#map").grow();
						compute_coords(default_zoom);
						$.going_bottom = false;
					});
					return false;
				} else if (e.keyCode == 109) {
					if ($.zooming) return false;
					$.zooming = true;
					zoom(--default_zoom) && default_zoom++;
					return false;
				} else if (e.keyCode == 107) {
					if ($.zooming) return false;
					$.zooming = true;
					zoom(++default_zoom) && default_zoom--;
					return false;
				}
			});

			\$(window).resize(function() {
				\$("#cross").center();			// make sure to re-center the cross after a resize event
			});
		});
	</script>
</html>
HTML
}

function help {
cat <<HELP
USAGE ./dgms [--longitude ... --latitude ... | --address ... [--lucky]]
	[--zoom ... | --min-zoom ... --max-zoom] [--name ...]
	[--longitude-deviation ...] [--latitude-deviation ...]
	[--use-tor --start-port ... --end-port ... [--max-connections ...]]
	[--only-sat] [--language ...]

Distributed Google Maps Scraper is a tool that let you download maps  from
Google either directly (not recommended) or using Tor.

  -n,	--name 			HTML file name, if not set, coordinates will be
  				  used to create a filename.
  -ad,	--address 		If set, the script will attempt to find
  				  coordinates of that address, if multiple
  				  results are found, an interactive screen will
  				  be displayed.
  -lk,	--lucky			Works with --address and makes the script choose
  				  the first result by default.
  -la,	--latitude 		Latitude of the center of map.
  -lo,	--longitude 		Longitude of the center of the map.
  -z,	--zoom 			Zoom of the map.
  -lod,	--longitude-deviation 	The deviation from the center of the map to the
  				  west and east sides, if not set the value 0.01
  				  will be taken.
  -lad,	--latitude-deviation 	The deviation from the center of the map to the
  				  south and nord sides, if not set the value 0.01
  				  will be taken.
  -mz,	--min-zoom 		The minimum zoom that will be scraped (used with
  				  -Mz).
  -Mz,	--max-zoom 		The maximum zoom that will be scraped (used with
  				  -mz).
  -T,	--use-tor 		Use Tor proxy (used with -ep and -sp)
  -sp,	--start-port 		If -T is chosen, affects the starting port of
  				  the range of ports that will be used by the
  				  multiple instances of Tor (used with -ep).
  -ep,	--end-port 		If -T is chosen, affects the ending port of
  				  the range of ports that will be used by the
  				  multiple instances of Tor (used with -sp).
  -mc,	--max-connections 	The number of simultaneous parallel instances
  				  of downloads, if not set a default value of 4
  				  will be chosen.
  -os,	--only-sat 		Do not download address layers.
  -l,	--language 		Choose the language of addresses in layers, if
  				  not set the system language will be used, if
  				  not available EN will be used.
  -h,	--help 			Print this help.


HELP
}

function search {
	address="$@"
	res=$(wget -qO- "http://maps.googleapis.com/maps/api/geocode/xml?address=$address")
	addresses=$(xmllint --xpath "//result/formatted_address" <(echo "$res") 2>/dev/null | sed 's/<formatted_address>//g' | sed 's/<\/formatted_address>/|/g' | sed 's/|$//g')
	IFS="|"
	addresses=($addresses)
	K=0
	for key in "${!addresses[@]}"; do
		((K++))
		i=$( echo "$key+1" | bc )
		echo "[$i] ${addresses[$key]}"
	done
	if ! $lucky; then
		echo "[R] Retry"
		echo "[A] Abort"
		printf "Enter a choose: "
		read addr
	else
		addr=1
	fi
	if [[ "$addr" == 'R' ]]; then
		printf "Enter a new address\nAddress: "
		read addr
		search "$addr"
	elif [[ "$addr" == 'A' ]]; then
		echo "Aborting ..."
		exit 1
	elif [[ $addr -le $K ]]; then
		latitudes=$(xmllint --xpath "//result/geometry/location/lat" <(echo "$res") | sed 's/<lat>//g' | sed 's/<\/lat>/|/g' | sed 's/|$//g')
		longitudes=$(xmllint --xpath "//result/geometry/location/lng" <(echo "$res") | sed 's/<lng>//g' | sed 's/<\/lng>/|/g' | sed 's/|$//g')
		latitudes=($latitudes)
		longitudes=($longitudes)
		for key in "${!addresses[@]}"; do
			i=$( echo "$key+1" | bc )
			[[ $i == $addr ]] && _addr_=${addresses[$key]}
		done
		for key in "${!latitudes[@]}"; do
			i=$( echo "$key+1" | bc )
			[[ $i == $addr ]] && latitude=${latitudes[$key]}
		done
		for key in "${!longitudes[@]}"; do
			i=$( echo "$key+1" | bc )
			[[ $i == $addr ]] && longitude=${longitudes[$key]}
		done
	else
		echo "What did you do?!! Aborting ..."
		exit 1
	fi

	unset IFS
}

[[ ! -n "$1" ]] && help && exit 1

while [ $# -gt 0 ]
do
    case "$1" in
		--help | -h )
			help
			exit 0
		;;
		--name | -n )
			shift
			name="$1"
		;;
		--address | -ad )
			shift
			address="$1"
		;;
		--lucky | -lk )
			lucky=true
		;;
		--latitude | -la )
			shift
			latitude="$1"
		;;
		--longitude | -lo )
			shift
			longitude="$1"
		;;
		--zoom | -z )
			shift
			zoom="$1"
		;;
		--longitude-deviation | -lod )
			shift
			longitude_deviation="$1"
		;;
		--latitude-deviation | -lad )
			shift
			latitude_deviation="$1"
		;;
		--min-zoom | -mz )
			shift
			min_zoom="$1"
		;;
		--max-zoom | -Mz )
			shift
			max_zoom="$1"
		;;
		--use-tor | -T )
			use_tor=true
		;;
		--start-port | -sp )
			shift
			start_port="$1"
		;;
		--end-port | -ep )
			shift
			end_port="$1"
		;;
		--max-connections | -mc )
			shift
			max_connections="$1"
		;;
		--only-sat | -os )
			only_sat=true
		;;
		--language | -l )
			shift
			language="$1"
		;;
    esac
    shift
done


([[ ! -n $latitude ]] || [[ ! -n $longitude ]]) && [[ ! -n $address ]] && echo "either --address (-ad) OR [--latitude (-la) and --longitude (-lo)] arguments are mendatory" && exit 1
[[ ! -n $lucky ]] && lucky=false

[[ -n $address ]] && search $address

[[ -n $language ]] || language=$(echo $LANG | sed 's/_.*//g')
[[ -n $language ]] || language=en

[[ ! -n $latitude ]] && echo "--latitude (-la) argument is mandatory" && exit 1
[[ ! -n $longitude ]] && echo "--longitude (-lo) argument is mandatory" && exit 1
([[ ! -n $min_zoom ]] || [[ ! -n $max_zoom ]]) && [[ ! -n $zoom ]] && echo "either --zoom (-z) OR [--min_zoom (-mz) and --max-zoom (-Mz)] arguments are mendatory" && exit 1
([[ ! -n $min_zoom ]] || [[ ! -n $max_zoom ]]) && min_zoom=$zoom && max_zoom=$zoom
([[ $min_zoom -gt 23 ]] || [[ $min_zoom -lt 2 ]] || [[ $max_zoom -gt 23 ]] || [[ $max_zoom -lt 2 ]]) && echo "zoom must be between 2 and 23" && exit 1
[[ -n $zoom ]] && ([[ $zoom -gt 23 ]] || [[ $zoom -lt 2 ]])
[[ ! -n $name ]] && [[ -n $address ]] && name=$address
[[ ! -n $name ]] && [[ ! -n $address ]] && name=$([[ $max_zoom -eq $min_zoom ]] && echo $latitude,$longitude,$max_zoom || echo $latitude,$longitude,$min_zoom-$max_zoom)
[[ ! -n $longitude_deviation ]] && longitude_deviation=0.01
[[ ! -n $latitude_deviation ]] && latitude_deviation=0.01
[[ ! -n $use_tor ]] && use_tor=false
[[ ! -n $only_sat ]] && only_sat=false
[[ ! -n $max_connections ]] && max_connections=4
$use_tor && ( [[ ! -n $start_port ]] || [[ ! -n $end_port ]] ) && echo "you choosed to use Tor, --start-port (-sp) and --end-port (-ep) arguments are mandatory" && exit 1

[[ ! $latitude =~ ^-?[0-9]+([.][0-9]+)?$ ]] && echo "error in latitude format" && exit 1
[[ ! $longitude =~ ^-?[0-9]+([.][0-9]+)?$ ]] && echo "error in longitude format" && exit 1
[[ ! $latitude_deviation =~ ^[0-9]+([.][0-9]+)?$ ]] && echo "error in latitude deviation format" && exit 1
[[ ! $longitude_deviation =~ ^[0-9]+([.][0-9]+)?$ ]] && echo "error in longitude deviation format" && exit 1
[[ -n $zoom ]] && [[ ! $zoom =~ ^[0-9]{1,2}$ ]] && echo "error in zoom format" && exit 1
[[ ! $max_zoom =~ ^[0-9]{1,2}$ ]] && echo "error in maximum zoom format" && exit 1
[[ ! $min_zoom =~ ^[0-9]{1,2}$ ]] && echo "error in minimum zoom format" && exit 1
$use_tor && [[ ! $start_port =~ ^[0-9]+$ ]] && echo "error in starting port format" && exit 1
$use_tor && [[ ! $end_port =~ ^[0-9]+$ ]] && echo "error in ending port format" && exit 1
$use_tor && [[ ! $max_connections =~ ^[0-9]+$ ]] && echo "error in maximum connections format" && exit 1

MINLAT=$( echo "$latitude-$latitude_deviation" | bc )
MAXLAT=$( echo "$latitude+$latitude_deviation" | bc )
MINLONG=$( echo "$longitude-$longitude_deviation" | bc )
MAXLONG=$( echo "$longitude+$longitude_deviation" | bc )

TOTALTILES=0

PI=$( echo "scale=10; 4*a(1)" | bc -l )

[[ -n $_addr_ ]] && _MSG_=" (corresponding to $_addr_)" || _MSG_=""

clear
cat <<WELCOM
			==============================
			| Downloader for Google maps |
			------------------------------

 | This script will construct maps from $(echo -e "\e[31m\e[1m")$MINLAT,$MINLONG to $MAXLAT,$MAXLONG$(echo -e "\e[0m")
 | (zoom $(echo -e "\e[31m\e[1m")$(seq -s ',' $min_zoom $max_zoom)$(echo -e "\e[0m"))$_MSG_ that will be available offline for PC and smartphone
 | use, it will create a HTML page named $(echo -e "\e[31m\e[1m$name.html\e[0m").

WELCOM

if $use_tor; then
cat <<TOR
 | Multiple Tor insctances will be created from port $(echo -e "\e[31m\e[1m")$start_port to port $end_port$(echo -e "\e[0m")
 | and give $(echo -e "\e[31m\e[1m")$(echo "$end_port-$start_port" | bc)$(echo -e "\e[0m") different circuits to avoid greylisting.
 | A number of $(echo -e "\e[31m\e[1m")$(echo "$max_connections")$(echo -e "\e[0m") parallel connections will be set each time.

TOR
else
cat <<NOTOR
 | You chose $(echo -e "\e[31m\e[1m")NOT TO USE$(echo -e "\e[0m") Tor proxies, please be aware
 | that a greylisting measure will be taken
 | by Google soon (likely a captcha verification), this script cannot
 | (yet) resolve captchas so it will stop as soon as a captcha points
 | its nose to avoid blacklisting your IP.

NOTOR
fi

touch /tmp/torsocks.conf
cat >/tmp/torsocks.conf <<EOL
server = 127.0.0.1
server_port = 7000
EOL
export TORSOCKS_CONF_FILE=/tmp/torsocks.conf

function random {
	LEN=$1
	MAX=$(printf '9%.0s' $(seq 1 ${LEN}))
	((LEN--))
	MIN=1$(printf '0%.0s' $(seq 1 ${LEN}))
	shuf -i ${MIN}-${MAX} -n 1
}

function twget {
	switch_proxy
	port=$(echo $TORSOCKS_CONF_FILE | awk -F'[.]' '{print $2}')
	#IP=$(get_IP $port)
	URL="$1"
	try=$2
	x=$(echo $URL | awk -F'[=&]' '{print $8}')
	y=$(echo $URL | awk -F'[=&]' '{print $10}')
	z=$(echo $URL | awk -F'[=&]' '{print $12}')
	t=$(echo $URL | awk -F'[=&]' '{print $2}')
	[[ "$t" == "s" ]] && ext=jpg || ext=png
	code=$(torsocks wget -S -T 10 -q -O tiles/$t/$z/$x/$y.$ext ${URL} 2>&1 | grep "HTTP/" | awk '{print $2}')
	code=$(echo $code | sed 's/\n/-/')
	[[ "$code" == "" ]] && code=XXX
	[[ "$code" == "404" ]] && echo -e " [$try] => $port: $URL [$code]" && cp tiles/img/404.$ext tiles/$t/$z/$x/$y.$ext && exit 0
	[[ "$code" == "400" ]] && echo -e " [$try] => $port: $URL [$code]" && cp tiles/img/404.$ext tiles/$t/$z/$x/$y.$ext && exit 0
	[[ "$code" == "200" ]] && echo -e " [$try] => \e[32m\e[1m$port: $URL [$code]\e[0m" || echo -e " [$try] => \e[31m\e[1m$port: $URL [$code]\e[0m retry \e[35m\e[1m#$try\e[0m"
	((try++))
	[[ "$code" != "200" ]] && newnym $port && rm tiles/$t/$z/$x/$y.$ext 2>/dev/null && sleep 2 && twget "$URL" $try
}

function multitor {
	RANGE="$@"
	for i in ${RANGE}; do (tor --quiet -f <(echo -e "SocksPort $i\nDataDirectory .$i\nControlPort 1$i")&) ; done;
}

function newnym {
	PORT="$@"
	echo -e 'authenticate ""\nSIGNAL NEWNYM' | nc localhost 1${PORT} -q 0 > /dev/null 2>&1
}

function shutdown_tor {
	PORT="$@"
	echo -e 'authenticate ""\nSIGNAL SHUTDOWN' | nc localhost 1${PORT} -q 0 > /dev/null 2>&1
}

function bootstrap_status {
	PORT="$@"
	echo -e 'authenticate ""\nGETINFO status/bootstrap-phase' | nc localhost 1${PORT} -q 0 | grep PROGRESS | awk '{print $3}' | sed 's/PROGRESS=//'
}

function get_IP {
	PORT="$@"
	echo -e 'authenticate ""\nGETINFO address' | nc localhost 1${PORT} -q 0 | grep 'address=' | sed 's/250-address=//'
}

function switch_proxy {
	NEWPORT=$(echo ${RANGE} | sed 's/ /\n/g' | sort --random-sort | head -n 1)
	export TORSOCKS_CONF_FILE=/tmp/torsocks.$NEWPORT.conf
}

function valid_image {
	path=$1
	filename=$(basename "$path")
	ext="${filename##*.}"
	ERROR=$( { identify -format "%f" "$ext:$path"; } 2>&1 )
	[[ "$ERROR" =~ 'error' ]] && echo false || echo true
}

function cleanup_multitor {
	# Wait for all pending jobs before exiting
	echo
	echo "Waiting for remaining jobs to complete..."
	while [[ $(jobs -r | wc -l) -gt 0 ]]; do
		sleep 0.1
	done

	# Close all Tor processes to avoid memory leak
	echo "Closing remaining Tor processes..."
	for port in $(seq $start_port $end_port); do
		shutdown_tor $port
	done

	# Remove generated Tor socket config files from /tmp folder
	rm -rfv /tmp/torsocks.[0-9]*.conf

	# Remove generated folder from Tor circuit setup relative to local folder
	rm -rfv .[0-9]*/

	exit 0
}

# We completely trap the Ctrl+C signal and exit ourselves
trap cleanup_multitor INT

echo " > Checking for necessary files ..."

mkdir -p tiles
mkdir -p tiles/js
mkdir -p tiles/img
mkdir -p tiles/s
mkdir -p tiles/h
wget -q -nc -O tiles/js/jquery-1.12.4.min.js "http://code.jquery.com/jquery-1.12.4.min.js" && echo " -> jquery OK!"
wget -q -nc -O tiles/js/jquery-ui-1.12.1.min.js "https://code.jquery.com/ui/1.12.1/jquery-ui.min.js" && echo " -> jquery-ui OK!"
wget -q -nc -O tiles/js/jquery.ui.touch-punch.min.js "https://raw.githubusercontent.com/furf/jquery-ui-touch-punch/master/jquery.ui.touch-punch.min.js" && echo " -> jquery.ui.touch-punch OK!"
wget -q -nc -O tiles/img/zm.png "http://downloadicons.net/sites/default/files/zoom-out-icon-22851.png" && echo " -> zoom out image OK!"
wget -q -nc -O tiles/img/cross.png "http://pngriver.com/wp-content/uploads/2017/12/transparent-target-aim-png-image.png" && echo " -> cross image OK!"
wget -q -nc -O tiles/img/zp.png "https://www.pngarts.com/files/1/Zoom-PNG-Image-with-Transparent-Background.png" && echo " -> zoom in image OK!"
wget -q -nc -O tiles/img/blank.jpg "https://via.placeholder.com/256" && echo " -> background image OK!"
wget -q -nc -O tiles/img/transparent.png "https://storage.googleapis.com/drivetexas/mask/7/28/52.png" && echo " -> transparent image OK!"
wget -q -nc -O tiles/img/404.jpg "https://dummyimage.com/256/ffffff/f00.jpg&text=Not+found" && echo " -> 404 jpg image OK!"
wget -q -nc -O tiles/img/404.png "https://dummyimage.com/256/ffffff/f00.png&text=Not+found" && echo " -> 404 png image OK!"

TOTALTILES=0

for z in $(seq $max_zoom -1 $min_zoom); do
	MINX=$( echo "(2^($z-1))*(($MINLONG/180)+1)" | bc -l | awk '{printf("%d\n",$0)}' )
	MAXX=$( echo "(2^($z-1))*(($MAXLONG/180)+1)" | bc -l | awk '{printf("%d\n",$0)}' )
	MAXY=$( echo "(2^$z)-((2^($z-1)/$PI)*(((l(s((90+$MINLAT)*$PI/360)/c((90+$MINLAT)*$PI/360)))+$PI)))" | bc -l | awk '{printf("%d\n",$0)}' )
	MINY=$( echo "(2^$z)-((2^($z-1)/$PI)*(((l(s((90+$MAXLAT)*$PI/360)/c((90+$MAXLAT)*$PI/360)))+$PI)))" | bc -l | awk '{printf("%d\n",$0)}' )
	if [ $( echo "$MAXX-$MINX" | bc ) -le 9 ]; then
		MAXX=$( echo "$MAXX+(10-($MAXX-$MINX))/2" | bc | cut -f1 -d"." )
		MINX=$( echo "$MINX-(12-($MAXX-$MINX))/2" | bc | cut -f1 -d"." )
	fi
	if [ $( echo "$MAXY-$MINY" | bc ) -le 9 ]; then
		MAXY=$( echo "$MAXY+(10-($MAXY-$MINY))/2" | bc | cut -f1 -d"." )
		MINY=$( echo "$MINY-(10-($MAXY-$MINY))/2" | bc | cut -f1 -d"." )
	fi
	[[ $MINX -lt 0 ]] && MINX=0
	[[ $MINY -lt 0 ]] && MINY=0
	TOTALTILES=$( echo "$TOTALTILES+($MAXX-$MINX+1)*($MAXY-$MINY+1)" | bc )
done

cat <<TOTALTILES
 > Total number of tiles that will be downloaded: $TOTALTILES

TOTALTILES

if $use_tor; then
	RANGE=$(seq $start_port $end_port)
	echo " > setting Tor circuits ..."
	for i in $(seq $start_port $end_port); do
	touch /tmp/torsocks.$i.conf
	cat >/tmp/torsocks.$i.conf <<EOL
server = 127.0.0.1
server_port = $i
EOL
	done
	multitor $RANGE > /dev/null 2>&1
	global_status=0
	max_status=$( echo "($end_port-$start_port+1)*100" | bc )
	echo
	while [[ $global_status -ne $max_status ]]; do
		global_status=0
		for port in $(seq $start_port $end_port); do
			global_status=$( echo "$global_status+$(bootstrap_status $port)" | bc )
		done
		printf "\033[A"
		echo " -> Tor interface is ready to "$( echo "100*$global_status/$max_status" | bc | cut -f1 -d".")"%"
		sleep 0.3
	done
	gen_html $longitude $latitude $min_zoom $max_zoom $name
	for z in $(seq $max_zoom -1 $min_zoom); do
		MINX=$( echo "(2^($z-1))*(($MINLONG/180)+1)" | bc -l | awk '{printf("%d\n",$0)}' )
		MAXX=$( echo "(2^($z-1))*(($MAXLONG/180)+1)" | bc -l | awk '{printf("%d\n",$0)}' )
		MAXY=$( echo "(2^$z)-((2^($z-1)/$PI)*(((l(s((90+$MINLAT)*$PI/360)/c((90+$MINLAT)*$PI/360)))+$PI)))" | bc -l | awk '{printf("%d\n",$0)}' )
		MINY=$( echo "(2^$z)-((2^($z-1)/$PI)*(((l(s((90+$MAXLAT)*$PI/360)/c((90+$MAXLAT)*$PI/360)))+$PI)))" | bc -l | awk '{printf("%d\n",$0)}' )
		if [ $( echo "$MAXX-$MINX" | bc ) -le 9 ]; then
			MAXX=$( echo "$MAXX+(10-($MAXX-$MINX))/2" | bc | cut -f1 -d"." )
			MINX=$( echo "$MINX-(12-($MAXX-$MINX))/2" | bc | cut -f1 -d"." )
		fi
		if [ $( echo "$MAXY-$MINY" | bc ) -le 9 ]; then
			MAXY=$( echo "$MAXY+(10-($MAXY-$MINY))/2" | bc | cut -f1 -d"." )
			MINY=$( echo "$MINY-(10-($MAXY-$MINY))/2" | bc | cut -f1 -d"." )
		fi
		[[ $MINX -lt 0 ]] && MINX=0
		[[ $MINY -lt 0 ]] && MINY=0
		for i in $(seq $MINX $MAXX); do
			mkdir -p tiles/s/$z/$i
			mkdir -p tiles/h/$z/$i
		done
		tiles=0
		e=0
		last_error=none
		TOTALTILES=$( echo "($MAXX-$MINX+1)*($MAXY-$MINY+1)" | bc )
		for x in $(seq $MINX $MAXX); do
			for y in $(seq $MINY $MAXY); do
				[[ -f tiles/s/$z/$x/$y.jpg ]] && [[ $(ls -lah tiles/s/$z/$x/$y.jpg | awk '{print $5}') == 0 ]] && rm tiles/s/$z/$x/$y.jpg && echo -e " > tiles/s/$z/$x/$y.jpg not a valid file, \e[31m\e[1mremoved\e[0m      " && printf "\033[A"
				[[ -f tiles/h/$z/$x/$y.png ]] && [[ $(ls -lah tiles/h/$z/$x/$y.png | awk '{print $5}') == 0 ]] && rm tiles/h/$z/$x/$y.png && echo -e " > tiles/h/$z/$x/$y.png not a valid file, \e[31m\e[1mremoved\e[0m      " && printf "\033[A"
				[[ -f tiles/s/$z/$x/$y.jpg ]] && ! $(valid_image tiles/s/$z/$x/$y.jpg) && rm tiles/s/$z/$x/$y.jpg && echo -e " > tiles/s/$z/$x/$y.jpg not a valid image format, \e[31m\e[1mremoved\e[0m      " && printf "\033[A"
				[[ -f tiles/h/$z/$x/$y.png ]] && ! $(valid_image tiles/h/$z/$x/$y.png) && rm tiles/h/$z/$x/$y.png && echo -e " > tiles/h/$z/$x/$y.png not a valid image format, \e[31m\e[1mremoved\e[0m      " && printf "\033[A"
				[[ -f tiles/s/$z/$x/$y.jpg ]] && echo -e " >>> tiles/s/$z/$x/$y.jpg already exists, \e[34m\e[1mskipping ...\e[0m        " && printf "\033[A"
				[[ -f tiles/h/$z/$x/$y.png ]] && echo -e " >>> tiles/h/$z/$x/$y.png already exists, \e[34m\e[1mskipping ...\e[0m        " && printf "\033[A"
					while [[ $(jobs -r | wc -l) -gt $max_connections ]]; do
						sleep 0.1
					done
				[[ ! -f tiles/s/$z/$x/$y.jpg ]] && twget "http://mts0.google.com/vt/lyrs=s&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo" 1 &
				[[ ! -f tiles/h/$z/$x/$y.png ]] && ! $only_sat && twget "http://mts0.google.com/vt/lyrs=h&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo" 1 &
			done
		done
	done

	cleanup_multitor
	exit 0
else
	gen_html $longitude $latitude $min_zoom $max_zoom $name
	for z in $(seq $max_zoom -1 $min_zoom); do
		MINX=$( echo "(2^($z-1))*(($MINLONG/180)+1)" | bc -l | awk '{printf("%d\n",$0)}' )
		MAXX=$( echo "(2^($z-1))*(($MAXLONG/180)+1)" | bc -l | awk '{printf("%d\n",$0)}' )
		MAXY=$( echo "(2^$z)-((2^($z-1)/$PI)*(((l(s((90+$MINLAT)*$PI/360)/c((90+$MINLAT)*$PI/360)))+$PI)))" | bc -l | awk '{printf("%d\n",$0)}' )
		MINY=$( echo "(2^$z)-((2^($z-1)/$PI)*(((l(s((90+$MAXLAT)*$PI/360)/c((90+$MAXLAT)*$PI/360)))+$PI)))" | bc -l | awk '{printf("%d\n",$0)}' )
		if [ $( echo "$MAXX-$MINX" | bc ) -le 9 ]; then
			MAXX=$( echo "$MAXX+(10-($MAXX-$MINX))/2" | bc | cut -f1 -d"." )
			MINX=$( echo "$MINX-(10-($MAXX-$MINX))/2" | bc | cut -f1 -d"." )
		fi
		if [ $( echo "$MAXY-$MINY" | bc ) -le 9 ]; then
			MAXY=$( echo "$MAXY+(10-($MAXY-$MINY))/2" | bc | cut -f1 -d"." )
			MINY=$( echo "$MINY-(10-($MAXY-$MINY))/2" | bc | cut -f1 -d"." )
		fi
		[[ $MINX -lt 0 ]] && MINX=0
		[[ $MINY -lt 0 ]] && MINY=0
		for i in $(seq $MINX $MAXX); do
			mkdir -p tiles/s/$z/$i
			mkdir -p tiles/h/$z/$i
		done
		tiles=0
		e=0
		cached=0
		last_error=none
		TOTALTILES=$( echo "($MAXX-$MINX+1)*($MAXY-$MINY+1)" | bc )
		for x in $(seq $MINX $MAXX); do
			for y in $(seq $MINY $MAXY); do
				[ -f tiles/$z/$x/$y.jpg ] && ((cached++))
				echo -e "\e[32m\e[1mCurrent download:\e[0m http://mts0.google.com/vt/lyrs=s&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo ..."
				codeS=$(wget -S -nc -T 60 "http://mts0.google.com/vt/lyrs=s&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo" -O "tiles/s/$z/$x/$y.jpg" 2>&1 | grep "HTTP/" | awk '{print $2}')
				echo -e "\e[32m\e[1mLast status code:\e[0m $codeS"
				if [[ -n $codeS ]] && [ "$codeS" != "200" ]; then
					((e++))
					rm "tiles/s/$z/$x/$y.jpg"
					last_error="http://mts0.google.com/vt/lyrs=s&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo => $codeS"
					[[ "$codeS" == "403" ]] && clear && echo -e "\e[1;91mBRAVO! you've been greylisted! Now you should use Tor (\e[32m--use-tor\e[1;91m or \e[32m-T\e[1;91m argument); exiting _\e[0m" && exit 1
				else
					tiles=$( echo "$tiles+0.5" | bc )
				fi
				if ! $only_sat; then
					echo -e "\e[32m\e[1mCurrent download:\e[0m http://mts0.google.com/vt/lyrs=h&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo ..."
					codeH=$(wget -S -nc -T 60 "http://mts0.google.com/vt/lyrs=h&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo" -O "tiles/h/$z/$x/$y.png" 2>&1 | grep "HTTP/" | awk '{print $2}')
					echo -e "\e[32m\e[1mLast status code:\e[0m $codeH"
					if [[ -n $codeH ]] && [ "$codeH" != "200" ]; then
						((e++))
						rm "tiles/h/$z/$x/$y.jpg"
						last_error="http://mts0.google.com/vt/lyrs=s&hl=$language&src=app&x=$x&y=$y&z=$z&s=Galileo => $codeH"
						[[ "$codeH" == "403" ]] && clear && echo -e "\e[1;91mBRAVO! you've been greylisted! Now you should use Tor (\e[32m--use-tor\e[1;91m or \e[32m-T\e[1;91m argument); exiting _\e[0m" && exit 1
					else
						tiles=$( echo "$tiles+0.5" | bc )
					fi
				fi
				echo -e "\e[32m\e[1mTotal errors:\e[0m "$e"    "
				echo -e "\e[32m\e[1mLast error:\e[0m "$last_error"    "
				echo -e "\e[32m\e[1mTiles already on cache:\e[0m "$cached"    "
				echo -e "\e[32m\e[1mTiles downloaded:\e[0m "$tiles" of "$TOTALTILES"    "
				echo -e "\e[32m\e[1mZoom:\e[0m "$z"    "
				$only_sat && printf "\033[A\033[A\033[A\033[A\033[A\033[A\033[A" || printf "\033[A\033[A\033[A\033[A\033[A\033[A\033[A\033[A\033[A"
				((i++))
			done
		done
	done
	exit 0
fi