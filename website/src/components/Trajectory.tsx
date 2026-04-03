import { Show } from "solid-js";

import { Line as LineChart } from "solid-chartjs";
import {
  Chart,
  Title,
  Colors,
  TimeScale,
  type ChartData,
  type ChartOptions,
} from "chart.js";
import "chartjs-adapter-date-fns";
import { subDays } from "date-fns";

Chart.defaults.font.size = 24;
Chart.register(Title, Colors, TimeScale);

// REFERENCE AS <Trajectory-component-implementation>
function Trajectory(props: { unwrapped?: boolean }) {
  const chartData: ChartData<"line"> = {
    datasets: [
      {
        data: [
          {
            x: subDays(new Date(), 100).getTime(),
            y: 0,
          },
          {
            x: new Date().getTime(),
            y: 100,
          },
        ],
        tension: 0.2,
      },
    ],
  };

  const chartOptions: ChartOptions = {
    plugins: {
      title: { display: true, text: "Trajectory" },
    },
    maintainAspectRatio: false,
    scales: {
      x: {
        type: "time",
        time: {
          unit: "day",
        },
      },
    },
  };

  const chart = (
    <LineChart
      data={chartData}
      options={chartOptions}
      extraCanvasAttributes={{ role: "img", "aria-label": "Trajectory Graph" }}
      fallback={<>fallback</>}
    />
  );
  return (
    <Show
      when={props.unwrapped}
      fallback={<div style={{ position: "relative" }}>{chart}</div>}
    >
      {chart}
    </Show>
  );
}

export default Trajectory;
