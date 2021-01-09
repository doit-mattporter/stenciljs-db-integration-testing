const bodyParser = require("body-parser"),
      {execSync} = require("child_process"),
      express = require("express"),
      router = express.Router(),
      {auth} = require('google-auth-library'),
      {SecretManagerServiceClient} = require("@google-cloud/secret-manager"),
      mysql = require("mysql"),
      util = require("util");

const gcp_secret_client = new SecretManagerServiceClient();

async function getContactFormUserPasswordSecret() {
    const projectId = await auth.getProjectId();
    // Oddly enough, the following is the only way GCP exposes projectNumber, and secret manager is the only place I've seen projectNumber used within a resourceID
    const projectNumber = execSync(`gcloud projects list --filter="${projectId}" --format="value(PROJECT_NUMBER)"`).toString().replace("\n", "");
    const [contact_form_write_password] = await gcp_secret_client.accessSecretVersion({
        name: `projects/${projectNumber}/secrets/wfe-mysql-contact-user/versions/1`
    });
    return contact_form_write_password.payload.data.toString();
}
const password = getContactFormUserPasswordSecret().then((result) => {
    return result.replace("\n", "");
});

var mysqlPool = mysql.createPool({
    host: "",
    port: 3306,
    user: "contact_form_write_user",
    password: password,
    database: "contactdb"
});

function validateEmail(email) {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(String(email).toLowerCase());
}

router.get("/", (req, res) => {
    res.render("home", {
        "pageName": "Home"
    });
});

router.get("/contact", (req, res) => {
    res.render("contact", {
        "pageName": "Contact"
    });
});

router.post("/contact", (req, res) => {
    const firstName = req["body"]["contact"]["firstName"];
    const lastName = req["body"]["contact"]["lastName"];
    const sourceEmail = req["body"]["contact"]["email"];
    const message = req["body"]["contact"]["message"];
    mysqlPool.query("SELECT 21 * 2 AS solution", (error, results, fields) => {
        if (error) throw error;
        console.log("The solution is: " + results[0].solution)
    })
    if (firstName.length >= 2 &&
        firstName.length <= 35 &&
        /a-zA-Z/.test(firstName) &&
        lastName.length >= 2 &&
        lastName.length <= 35 &&
        /a-zA-Z/.test(lastName) &&
        (validateEmail(sourceEmail)) &&
        !(message.includes("href")) &&
        message.length <= 10000) {
        return res.render("thanks", {
            "pageName": "Contact"
        });
    }
})

module.exports = router;
