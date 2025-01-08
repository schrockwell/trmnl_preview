const trmnlp = {};

trmnlp.connectLiveRender = function () {
  const ws = new WebSocket("/live_reload");

  ws.onopen = function () {
    console.log("Connected to live reload socket");
  };

  ws.onmessage = function (msg) {
    if (msg.data === "reload") {
      trmnlp.setIframeSrc(trmnlp.iframe.src);
    }
  };

  ws.onclose = function () {
    console.log("Reconnecting to live reload socket...");
    setTimeout(trmnlp.connectLiveRender, 1000);
  };
};

trmnlp.setCaseImage = function () {
  const value = trmnlp.caseSelect.value;
  document.querySelector(".case").className = `case case--${value}`;
  localStorage.setItem("trmnlp-case", value);
};

trmnlp.setPreviewFormat = function () {
  const value = trmnlp.formatSelect.value;
  localStorage.setItem("trmnlp-format", value);

  trmnlp.setIframeSrc(`/render/${trmnlp.view}.${value}`);
};

trmnlp.setIframeSrc = function (src) {
  document.querySelector(".spinner").style.display = "inline-block";
  trmnlp.iframe.src = src;
};

document.addEventListener("DOMContentLoaded", function () {
  trmnlp.view = document.querySelector("meta[name='trmnl-view']").content;
  trmnlp.iframe = document.querySelector("iframe");
  trmnlp.caseSelect = document.querySelector(".select-case");
  trmnlp.formatSelect = document.querySelector(".select-format");
  trmnlp.isLiveReloadEnabled =
    document.querySelector("meta[name='live-reload']").content === "true";

  if (trmnlp.isLiveReloadEnabled) {
    trmnlp.connectLiveRender();
  }

  const caseValue = localStorage.getItem("trmnlp-case") || "black";
  const formatValue = localStorage.getItem("trmnlp-format") || "html";

  trmnlp.caseSelect.value = caseValue;
  trmnlp.caseSelect.addEventListener("change", () => {
    trmnlp.setCaseImage();
  });

  trmnlp.formatSelect.value = formatValue;
  trmnlp.formatSelect.addEventListener("change", () => {
    trmnlp.setPreviewFormat();
  });

  trmnlp.iframe.addEventListener("load", () => {
    document.querySelector(".spinner").style.display = "none";
  });

  trmnlp.setCaseImage();
  trmnlp.setPreviewFormat();
});
