I have a project defined under the `compose` folder and I have jsut deployed the Loki service. I'd like you to create a short and concise script to help me validate that Loki can receive, process and store log data. I'm running on Mac.

Desired output: 
- one bash script that sends some log data and confirms that they are stored in Loki
- one bash script that cleans up the data
- a few PromQL queries to check Loki metrics.

Rules:
- Be concise, avoid over engineering
- Document the instructions and commands because I'm a novice in Loki and Prometheus.