$(function(){
	/*
	 * DATE Piccker (jQuery UI)
	 */
	$.datepicker.setDefaults( $.datepicker.regional[ "ja" ] );
	$("#datepicker").datepicker(
		{dateFormat: "yy/mm/dd"}
	);
	/*
	 * 支払方法、支払タイプをJSONより取得
	 */
	window.localStorage.clear();
	$.getJSON("json/method.json", function(methods){
		var 
			optObj = $("#method");
			len = methods.length;
		for ( var i = 0; i < len; i++) {
			console.log(methods[i].name);
			optObj.append($("<option>").attr({"id":methods[i].id}).attr({"value":methods[i].value}).text(methods[i].name));
			//$("<option>"+ items[i].item + "</option>").appendTo("select#items");
		}
	});
	$("#method").change(function(){
		var optObj = $("#payment option");
		var selectObje = $("#payment");
		optObj.remove();
		var method_name = $("#method").val();
		var json_path = "json/" + method_name + ".json";
		console.log(json_path);
		try {
			$.getJSON(json_path, function(names){
				var len = names.length;
				for ( var i = 0; i < len; i++) {
					selectObje.append($("<option>").attr({"id":names[i].id}).text(names[i].name));
				}
			});
		} catch(e) {
			selectObj.append($("<option>").attr({"id":0}).text("現金"));
		}
	});
	/*
	 * 費目をJSONより取得
	 */
	$.getJSON("json/outgo-items.json", function(items){
		var 
			optObj = $("#items");
			len = items.length;
		for ( var i = 0; i < len; i++) {
			console.log(items[i].item);
			optObj.append($("<option>").attr({"id":items[i].id}).text(items[i].item));
			//$("<option>"+ items[i].item + "</option>").appendTo("select#items");
		}
	});
	/*
	 * 位置情報を取得 (GEOLOCATION)
	 */
	$("#loc").click(function(){
		//console.log("Clicked!!");
		navigator.geolocation.getCurrentPosition(function(pos){
			var latitude = pos.coords.latitude;
			var longitude = pos.coords.longitude;
			var map = null; var marker = null; var gPos = null;
			console.log("latitude:" + latitude);
			console.log("longitude:" + longitude);
			$("div#location").text(latitude);
			$("div#location").append("/" + longitude);
			gPos = new google.maps.LatLng(latitude, longitude);
			var mapOptions = {
				center: gPos,
				zoom: 16,
				mapTypeId: google.maps.MapTypeId.ROADMAP
			};
			map = new google.maps.Map(document.getElementById("googlemap"), mapOptions);
			marker = new google.maps.Marker({
				position: gPos,
				map: map
			});
		});
	});
});