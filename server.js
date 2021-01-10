// Import libraries
const bodyParser = require("body-parser"),
      cluster = require("cluster"),
      express = require("express"),
      http = require("http");
const numCPUs = require("os").cpus().length;

// Configure Express app
const app = express();
app.use(express.static(__dirname + "/public"));
app.use(bodyParser.urlencoded({
    "limit": "1mb",
    "extended": true
}));
app.set("view engine", "ejs");

// Set routes
var indexRoutes = require("./routes/index");

app.use("/", indexRoutes);

// app.listen(80)
// Create a cluster of servers, one for each vCPU, all listening on the same port
const httpServer = http.createServer(app);
if (cluster.isMaster) {
    // Fork workers
    console.log(`Master ${process.pid} is running`);
    for (let i = 0; i < numCPUs; i++) {
        cluster.fork();
    }
    cluster.on("exit", (worker, code, signal) => {
        console.log(`worker ${worker.process.pid} died`);
    });
} else {
    httpServer.listen(80, "0.0.0.0", () => {
        console.log("HTTP server running on port 80");
    })
};
