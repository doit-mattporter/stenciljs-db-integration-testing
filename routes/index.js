const bodyParser = require("body-parser"),
    express = require("express"),
    { getMysqlPool } = require("../modules/mysqlpool"),
    mysql = require("mysql"),
    router = express.Router();

function validateEmail(email) {
    var re = /^(([^<>()\[\]\\.,;:\s@"]+(\.[^<>()\[\]\\.,;:\s@"]+)*)|(".+"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$/;
    return re.test(String(email).toLowerCase());
}

router.get("/", (req, res) => {
    querySql = "SELECT * FROM Contacts ORDER BY ContactID DESC LIMIT 10";
    getMysqlPool().then((pool) => {
        pool.query(querySql, (error, results, fields) => {
            if (error) throw error;
            res.render("home", {
                pageName: "Home",
                contacts: results,
            });
        });
    });
});

router.get("/contact", (req, res) => {
    res.render("contact", {
        pageName: "Contact",
    });
});

router.post("/contact", (req, res) => {
    const firstName = req["body"]["contact"]["firstName"];
    const lastName = req["body"]["contact"]["lastName"];
    const sourceEmail = req["body"]["contact"]["email"];
    const message = req["body"]["contact"]["message"];
    var insertSql = "INSERT INTO Contacts (FirstName,LastName,Email,Message) VALUES (?, ?, ?, ?)";
    const inserts = [firstName, lastName, sourceEmail, message];
    insertSql = mysql.format(insertSql, inserts);
    if (firstName.length >= 2 && firstName.length <= 35 && lastName.length >= 2 && lastName.length <= 35 && validateEmail(sourceEmail) && message.length <= 10000) {
        console.log(insertSql);
        getMysqlPool().then((pool) => {
            pool.query(insertSql, (error, results, fields) => {
                if (error) throw error;
            });
        });
        return res.render("thanks", {
            pageName: "Contact",
        });
    }
});

module.exports = router;
