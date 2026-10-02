// Shows the staleness banner on /status/ when the data is over 36 hours old.
// A static page cannot notice its own age, so this checks at view time.
(function () {
  var stamp = document.getElementById("status-generated");
  var banner = document.getElementById("status-stale");
  if (!stamp || !banner) {
    return;
  }
  var generated = Date.parse(stamp.getAttribute("data-generated"));
  if (!isNaN(generated) && Date.now() - generated > 36 * 60 * 60 * 1000) {
    banner.hidden = false;
  }
})();
