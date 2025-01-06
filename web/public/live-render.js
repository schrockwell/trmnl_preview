live_render = {};

live_render.connect = function () {
  const view = document.querySelector("meta[name='trmnl-view']").content;
  const ws = new WebSocket("/live_render/" + view);

  ws.onopen = function () {
    console.log("Connected to live push server");
  };

  ws.onmessage = function (msg) {
    document.querySelector(".view").innerHTML = msg.data;
  };

  ws.onclose = function () {
    console.log("Reconnecting to live push server...");
    setTimeout(live_render.connect, 1000);
  };
};

document.addEventListener("DOMContentLoaded", function () {
  live_render.connect();
});
