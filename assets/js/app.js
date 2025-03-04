// If you want to use Phoenix channels, run `mix help phx.gen.channel`
// to get started and then uncomment the line below.
// import "./user_socket.js"

// You can include dependencies in two ways.
//
// The simplest option is to put them in assets/vendor and
// import them using relative paths:
//
//     import "../vendor/some-package.js"
//
// Alternatively, you can `npm install some-package --prefix assets` and import
// them using a path starting with the package name:
//
//     import "some-package"
//

import Uploaders from "../uploaders"
import InfinityScroll from "./_hooks/infinity_scroll";
// Include phoenix_html to handle method=PUT/DELETE in forms and buttons.
import "phoenix_html"
// Establish Phoenix Socket and LiveView configuration.
import {Socket} from "phoenix"
import {LiveSocket} from "phoenix_live_view"
import topbar from "../vendor/topbar"

import Hooks from "./_hooks"
import MoonHooks from "../../deps/moon/assets/js/hooks"

let Hooks = {
  InfinityScroll: InfinityScroll,
  PageReloader: {
    mounted() {
      this.handleEvent("page_reload", () => {
        window.location.reload();
      });
    }
  }
};

let csrfToken = document.querySelector("meta[name='csrf-token']").getAttribute("content")
let liveSocket = new LiveSocket("/live", Socket, {
  longPollFallbackMs: 2500,
  params: {_csrf_token: csrfToken},
  hooks: {...MoonHooks, ...Hooks},
  uploaders: Uploaders
})

// Show progress bar on live navigation and form submits
topbar.config({barColors: {0: "#29d"}, shadowColor: "rgba(0, 0, 0, .3)"})
window.addEventListener("phx:page-loading-start", _info => topbar.show(300))
window.addEventListener("phx:page-loading-stop", _info => topbar.hide())

// connect if there are any LiveViews on the page
liveSocket.connect()

// expose liveSocket on window for web console debug logs and latency simulation:
// >> liveSocket.enableDebug()
// >> liveSocket.enableLatencySim(1000)  // enabled for duration of browser session
// >> liveSocket.disableLatencySim()
window.liveSocket = liveSocket

import Chart from 'chart.js/auto';
import { CandlestickController, CandlestickElement } from 'chartjs-chart-financial';

Chart.register(CandlestickController, CandlestickElement);

let hooks = {
  CandlestickChart: {
    mounted() {
      const ctx = document.getElementById('candlestickChart').getContext('2d');
      const chart = new Chart(ctx, {
        type: 'candlestick',
        data: {
          datasets: [{
            label: 'Candlestick',
            data: this.getData(), 
          }]
        },
        options: {
          responsive: true,
          scales: {
            x: {
              type: 'time',
              time: {
                unit: 'day'
              }
            },
            y: {
              beginAtZero: false
            }
          }
        }
      });

      this.handleEvent('update_candlestick_data', ({ data }) => {
        chart.data.datasets[0].data = data;
        chart.update();
      });
    },

    getData() {
      return [
        { x: new Date('2023-01-01T00:00:00Z'), o: 100, h: 110, l: 90, c: 105 },
        { x: new Date('2023-01-02T00:00:00Z'), o: 105, h: 120, l: 100, c: 115 },
      ];
    }
  }
};

export default hooks;
